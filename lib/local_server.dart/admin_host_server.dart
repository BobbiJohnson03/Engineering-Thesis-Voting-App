import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/cascade.dart';

import '../models/enums.dart';
import '../models/question.dart';
import '../models/meeting.dart';
import '../models/meeting_pass.dart';
import '../models/session.dart';
import '../models/ticket.dart';
import '../models/vote.dart';

import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/vote_repository.dart';
import '../repositories/question_repository.dart';

// używamy publicznej klasy z osobnego pliku
import 'validation_result.dart';

Response _json(Object body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  },
);

/// Admin host = tiny local HTTP + WebSocket server.
/// Public endpoints:
/// - GET  /health
/// - GET  /manifest?sid=SESSION_ID
/// - POST /joinMeeting
/// - POST /ticket
/// - POST /voteBundle    (recommended)
/// - POST /vote          (debug/manual)
/// - GET  /ws?mid=MEETING_ID
///
/// Admin endpoints:
/// - GET  /admin/results?sid=SESSION_ID
/// - POST /admin/close
/// - POST /admin/archive
/// - POST /admin/session/seed      (optional, for dev)
/// - GET  /admin/export/pdf?sid=SESSION_ID  (stub)
class AdminHostServer {
  HttpServer? _server;

  final MeetingRepository meetings;
  final SessionRepository sessions;
  final TicketRepository tickets;
  final VoteRepository votes;
  final QuestionRepository questions;

  /// WS clients grouped by meetingId
  final Map<String, Set<WebSocketChannel>> _wsClients = {};

  /// Prevent rapid double submission per ticket
  final Set<String> _inFlightTickets = <String>{};

  /// Periodic auto-close timer
  Timer? _autoCloseTimer;

  AdminHostServer({
    required this.meetings,
    required this.sessions,
    required this.tickets,
    required this.votes,
    required this.questions,
  });

  Future<void> start({InternetAddress? address, int port = 8080}) async {
    final router =
        Router()
          ..get('/health', _health)
          ..get('/manifest', _manifest)
          ..post('/joinMeeting', _joinMeeting)
          ..post('/ticket', _ticket)
          ..post('/voteBundle', _voteBundle) // main path used by clients
          ..post('/vote', _vote) // keep for debug/manual tests
          ..get('/admin/results', _results)
          ..post('/admin/close', _adminClose)
          ..post('/admin/archive', _adminArchive)
          ..post('/admin/session/seed', _adminSeedSession) // optional for dev
          ..get('/admin/export/pdf', _exportPdfStub) // stub
          ..get('/ws', _wsHandler)
          ..options('/<ignored|.*>', _optionsOk); // CORS preflight

    final apiHandler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_cors())
        .addHandler(router);

    // Serve Flutter Web (PWA) from build/web (same origin as APIs)
    final staticHandler = createStaticHandler(
      'build/web',
      defaultDocument: 'index.html',
      listDirectories: false,
    );

    final cascade =
        Cascade()
            .add(staticHandler) // try static first
            .add(apiHandler) // then API
            .handler;

    _server = await io.serve(cascade, address ?? InternetAddress.anyIPv4, port);

    _startAutoCloser();
    // print('AdminHost listening on http://${_server!.address.address}:$port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  // --------------------- ROUTES ---------------------

  Response _health(Request _) => _json({'ok': true});

  /// Returns a session manifest with full questions/options for rendering.
  /// GET /manifest?sid=<sessionId>
  Future<Response> _manifest(Request req) async {
    final sid = req.requestedUri.queryParameters['sid']?.trim();
    if (sid == null || sid.isEmpty) {
      return _json({'error': 'bad_request'}, status: 400);
    }

    final s = await sessions.get(sid);
    if (s == null) {
      return _json({'error': 'session_not_found'}, status: 404);
    }

    final qs = await questions.byIds(s.questionIds);
    final qJson = [
      for (final q in qs)
        {
          'questionId': q.questionId,
          'text': q.text,
          'maxSelectable': q.maxSelectable,
          'displayGroup': q.displayGroup,
          'options': [
            for (final o in q.options)
              {'id': o.id, 'label': o.label, 'order': o.order},
          ],
        },
    ];

    return _json({
      'sessionId': s.sessionId,
      'title': s.title,
      'isOpen': s.isOpen,
      'votingEndsAt': s.votingEndsAt?.toIso8601String(),
      'questions': qJson,
    });
  }

  /// POST /joinMeeting
  /// Body:
  /// { "token": "...",  (TODO: verify JWT)
  ///   "mid": "meetingId",
  ///   "deviceFingerprintHash": "..."? }
  Future<Response> _joinMeeting(Request req) async {
    final Map<String, dynamic> body =
        jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    // TODO: verify JWT HS256 and extract meetingId. For MVP accept "mid".
    final meetingId = (body['mid'] as String?)?.trim();
    if (meetingId == null || meetingId.isEmpty) {
      return _json({'error': 'missing_meeting_id'}, status: 400);
    }

    final Meeting? meeting = await meetings.get(meetingId);
    if (meeting == null) {
      return _json({'error': 'meeting_not_found'}, status: 404);
    }
    if (!meeting.isOpen || meeting.isOver) {
      return _json({'error': 'meeting_closed'}, status: 403);
    }

    // MVP: MeetingPass not persisted yet (can add MeetingPassRepository later)
    final pass = MeetingPass(
      passId: DateTime.now().microsecondsSinceEpoch.toString(),
      meetingId: meeting.meetingId,
      issuedAt: DateTime.now(),
      deviceFingerprintHash: body['deviceFingerprintHash'] as String?,
    );

    final agendaSessions = await sessions.byIds(meeting.sessionIds);
    final agenda = [
      for (final s in agendaSessions)
        {
          'sessionId': s.sessionId,
          'title': s.title,
          'isOpen': s.isOpen,
          'expiresAt': s.expiresAt?.toIso8601String(),
          'votingEndsAt': s.votingEndsAt?.toIso8601String(),
        },
    ];

    return _json({
      'meeting': {
        'meetingId': meeting.meetingId,
        'title': meeting.title,
        'isOpen': meeting.isOpen,
      },
      'passId': pass.passId,
      'agenda': agenda,
    });
  }

  /// POST /ticket
  /// Body: { "passId": "...", "sessionId": "...", "deviceFingerprintHash": "..."? }
  Future<Response> _ticket(Request req) async {
    final Map<String, dynamic> body =
        jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final passId = (body['passId'] as String?)?.trim();
    final sessionId = (body['sessionId'] as String?)?.trim();
    final fp = body['deviceFingerprintHash'] as String?;

    if (passId == null ||
        passId.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return _json({'error': 'bad_request'}, status: 400);
    }

    final Session? s = await sessions.get(sessionId);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);
    if (!s.canAcceptVotes)
      return _json({'error': 'session_closed'}, status: 403);

    // Idempotent issuance — if (passId, sessionId) exists, return it.
    final newTicketId = DateTime.now().microsecondsSinceEpoch.toString();
    final Ticket t = await tickets.issueIfAbsent(
      ticketId: newTicketId,
      sessionId: sessionId,
      byPassId: passId, // keeping field name as-is (no model changes now)
      deviceFingerprintHash: fp,
    );

    // Broadcast optional presence/ticket event (meeting inferred later)
    final String? meetingId = await _meetingIdForSession(sessionId);
    if (meetingId != null) {
      _broadcast(meetingId, {'type': 'ticket_issued', 'sessionId': sessionId});
    }

    return _json({
      'ticketId': t.ticketId,
      'sessionId': t.sessionId,
      'byPassId': t.byPassId,
    });
  }

  // ---- selection validation helper ----
  ValidationResult _validateSelection({
    required List<String> selected,
    required List<String> validOptionIds,
    required int? maxSelectable,
  }) {
    // duplicates
    if (selected.length != selected.toSet().length) {
      return const ValidationResult.err('duplicate_option');
    }
    // allowed
    for (final id in selected) {
      if (!validOptionIds.contains(id)) {
        return const ValidationResult.err('invalid_option');
      }
    }
    // cap
    if (maxSelectable != null && selected.length > maxSelectable) {
      return const ValidationResult.err('too_many_selected');
    }
    return const ValidationResult.ok();
  }

  /// POST /voteBundle
  /// Body:
  /// { "ticketId": "...", "sessionId": "...",
  ///   "answers": [ { "questionId": "...", "selectedOptionIds": ["..."] }, ... ] }
  Future<Response> _voteBundle(Request req) async {
    final Map<String, dynamic> body = jsonDecode(await req.readAsString());
    final ticketId = (body['ticketId'] as String?)?.trim();
    final sessionId = (body['sessionId'] as String?)?.trim();
    final answers =
        (body['answers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    if ([ticketId, sessionId].any((e) => e == null || e!.isEmpty) ||
        answers.isEmpty) {
      return _json({'error': 'bad_request'}, status: 400);
    }

    // In-flight guard
    if (!_inFlightTickets.add(ticketId!)) {
      return _json({'error': 'busy'}, status: 409);
    }
    try {
      // Validate session & ticket
      final Session? s = await sessions.get(sessionId!);
      if (s == null) return _json({'error': 'session_not_found'}, status: 404);
      if (!s.canAcceptVotes)
        return _json({'error': 'session_closed'}, status: 403);

      final Ticket? t = await tickets.get(ticketId);
      if (t == null) return _json({'error': 'invalid_ticket'}, status: 403);
      if (t.revoked) return _json({'error': 'ticket_revoked'}, status: 403);
      if (t.used) return _json({'error': 'ticket_already_used'}, status: 409);
      if (t.sessionId != sessionId) {
        return _json({'error': 'ticket_session_mismatch'}, status: 400);
      }

      // Load questions for validation
      final qList = await questions.byIds(s.questionIds);
      final Map<String, Question> qById = {
        for (final q in qList) q.questionId: q,
      };

      var prev = s.ledgerHeadHash ?? '';
      final nowUtc = DateTime.now().toUtc();

      for (final a in answers) {
        final qid = (a['questionId'] as String?)?.trim();
        if (qid == null || qid.isEmpty) {
          return _json({'error': 'bad_question_id'}, status: 400);
        }
        final q = qById[qid];
        if (q == null) {
          return _json({'error': 'question_not_in_session'}, status: 400);
        }

        final selected =
            (a['selectedOptionIds'] as List?)?.cast<String>() ??
            const <String>[];
        final validOptionIds = q.options
            .map((o) => o.id)
            .toList(growable: false);

        final vr = _validateSelection(
          selected: selected,
          validOptionIds: validOptionIds,
          maxSelectable: q.maxSelectable,
        );
        if (!vr.ok) return _json({'error': vr.error}, status: 400);

        final payload = jsonEncode({
          'sessionId': sessionId,
          'questionId': qid,
          'selectedOptionIds': selected,
          'byTicketId': ticketId, // MVP (later: salted hash for secret ballots)
          'submittedAt': nowUtc.toIso8601String(),
          'prev': prev,
        });
        final hashSelf = sha256.convert(utf8.encode(payload)).toString();

        final v = Vote(
          voteId: DateTime.now().microsecondsSinceEpoch.toString(),
          sessionId: sessionId,
          questionId: qid,
          selectedOptionIds: selected,
          submittedAt: nowUtc, // store UTC consistently
          byTicketId: ticketId,
          hashPrev: prev,
          hashSelf: hashSelf,
        );
        await votes.put(v);
        prev = hashSelf;
      }

      await tickets.markUsed(ticketId);
      s.updateLedgerHead(prev); // persists via HiveObject.save()

      // Broadcast progress to all WS clients for this meeting.
      final String? meetingId = await _meetingIdForSession(sessionId);
      if (meetingId != null) {
        _broadcast(meetingId, {
          'type': 'vote_progress',
          'sessionId': sessionId,
        });
      }

      return _json({'ok': true});
    } finally {
      _inFlightTickets.remove(ticketId);
    }
  }

  /// Debug/manual endpoint for single-question submit.
  /// Body:
  /// { "ticketId": "...", "sessionId": "...", "questionId": "...", "selectedOptionIds": ["..."] }
  Future<Response> _vote(Request req) async {
    final Map<String, dynamic> body =
        jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final ticketId = (body['ticketId'] as String?)?.trim();
    final sessionId = (body['sessionId'] as String?)?.trim();
    final questionId = (body['questionId'] as String?)?.trim();
    final selected =
        (body['selectedOptionIds'] as List?)?.cast<String>() ??
        const <String>[];

    if ([ticketId, sessionId, questionId].any((e) => e == null || e!.isEmpty)) {
      return _json({'error': 'bad_request'}, status: 400);
    }

    final Session? s = await sessions.get(sessionId!);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);
    if (!s.canAcceptVotes)
      return _json({'error': 'session_closed'}, status: 403);

    final Ticket? t = await tickets.get(ticketId!);
    if (t == null) return _json({'error': 'invalid_ticket'}, status: 403);
    if (t.revoked) return _json({'error': 'ticket_revoked'}, status: 403);
    if (t.used) return _json({'error': 'ticket_already_used'}, status: 409);
    if (t.sessionId != sessionId) {
      return _json({'error': 'ticket_session_mismatch'}, status: 400);
    }

    // NOTE: For brevity we don't validate selection rules here (debug path).

    final prev = s.ledgerHeadHash ?? '';
    final nowUtc = DateTime.now().toUtc();

    final payload = jsonEncode({
      'sessionId': sessionId,
      'questionId': questionId,
      'selectedOptionIds': selected,
      'byTicketId': ticketId,
      'submittedAt': nowUtc.toIso8601String(),
      'prev': prev,
    });
    final hashSelf = sha256.convert(utf8.encode(payload)).toString();

    final v = Vote(
      voteId: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId,
      questionId: questionId!,
      selectedOptionIds: selected,
      submittedAt: nowUtc,
      byTicketId: ticketId,
      hashPrev: prev,
      hashSelf: hashSelf,
    );

    await votes.put(v);
    await tickets.markUsed(
      ticketId,
    ); // one question consumes the ticket (debug)
    s.updateLedgerHead(hashSelf);

    final String? meetingId = await _meetingIdForSession(sessionId);
    if (meetingId != null) {
      _broadcast(meetingId, {
        'type': 'vote_progress',
        'sessionId': sessionId,
        'questionId': questionId,
      });
    }

    return _json({'ok': true});
  }

  /// GET /admin/results?sid=SESSION_ID
  Future<Response> _results(Request req) async {
    final sid = req.requestedUri.queryParameters['sid']?.trim();
    if (sid == null || sid.isEmpty)
      return _json({'error': 'bad_request'}, status: 400);

    final s = await sessions.get(sid);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);

    final votesList = await votes.forSession(sid);
    final Map<String, Map<String, int>> tallies = {};
    for (final v in votesList) {
      final t = tallies.putIfAbsent(v.questionId, () => <String, int>{});
      for (final optId in v.selectedOptionIds) {
        t[optId] = (t[optId] ?? 0) + 1;
      }
    }
    return _json({'sessionId': sid, 'tallies': tallies});
  }

  /// POST /admin/close { sessionId }
  Future<Response> _adminClose(Request req) async {
    final Map<String, dynamic> body = jsonDecode(await req.readAsString());
    final sid = (body['sessionId'] as String?)?.trim();
    if (sid == null || sid.isEmpty)
      return _json({'error': 'bad_request'}, status: 400);

    final s = await sessions.get(sid);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);

    s.close();
    final mid = await _meetingIdForSession(sid);
    if (mid != null)
      _broadcast(mid, {'type': 'session_closed', 'sessionId': sid});
    return _json({'ok': true});
  }

  /// POST /admin/archive { sessionId }
  Future<Response> _adminArchive(Request req) async {
    final Map<String, dynamic> body = jsonDecode(await req.readAsString());
    final sid = (body['sessionId'] as String?)?.trim();
    if (sid == null || sid.isEmpty)
      return _json({'error': 'bad_request'}, status: 400);

    final s = await sessions.get(sid);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);

    s.closeAndArchive();
    final mid = await _meetingIdForSession(sid);
    if (mid != null)
      _broadcast(mid, {'type': 'session_archived', 'sessionId': sid});
    return _json({'ok': true});
  }

  /// POST /admin/session/seed (DEV ONLY)
  Future<Response> _adminSeedSession(Request req) async {
    final Map<String, dynamic> body = jsonDecode(await req.readAsString());
    final meetingId = (body['meetingId'] as String?)?.trim();
    final title = (body['title'] as String?)?.trim();
    final List<dynamic> qIn = (body['questions'] as List?) ?? const [];

    if ([meetingId, title].any((e) => e == null || e!.isEmpty) || qIn.isEmpty) {
      return _json({'error': 'bad_request'}, status: 400);
    }

    final m = await meetings.get(meetingId!);
    if (m == null) return _json({'error': 'meeting_not_found'}, status: 404);

    final sessionId = DateTime.now().microsecondsSinceEpoch.toString();
    final questionIds = <String>[];

    for (final qj in qIn.cast<Map<String, dynamic>>()) {
      final qid =
          qj['questionId'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString();
      questionIds.add(qid);

      final options =
          ((qj['options'] as List?) ?? const <Map<String, dynamic>>[])
              .cast<Map<String, dynamic>>()
              .map(
                (o) => OptionModel(
                  id: o['id'] as String,
                  label: o['label'] as String,
                  order: (o['order'] ?? 0) as int,
                ),
              )
              .toList();

      final q = Question(
        questionId: qid,
        text: qj['text'] as String? ?? '',
        options: options,
        maxSelectable: qj['maxSelectable'] as int?,
        displayGroup: qj['displayGroup'] as int? ?? 0,
      );
      await questions.put(q);
    }

    final s = Session(
      sessionId: sessionId,
      title: title!,
      type: SessionType.public,
      answersSchema: AnswersSchema.custom,
      maxSelectionsPerQuestion: const {},
      questionIds: questionIds,
      isOpen: true,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      jwtKeyId: 'local', // stub
      archived: false,
      ledgerHeadHash: null,
      votingEndsAt: null,
      shortCode: (body['shortCode'] as String?) ?? '',
    );
    await sessions.put(s);

    // attach to meeting
    final updated = await meetings.get(meetingId);
    if (updated != null) {
      updated.sessionIds = [...updated.sessionIds, sessionId];
      await updated.save();
    }

    return _json({'ok': true, 'sessionId': sessionId});
  }

  /// GET /admin/export/pdf?sid=...  (stub)
  Future<Response> _exportPdfStub(Request req) async {
    final sid = req.requestedUri.queryParameters['sid']?.trim();
    if (sid == null || sid.isEmpty)
      return _json({'error': 'bad_request'}, status: 400);
    final s = await sessions.get(sid);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);

    final bytes = utf8.encode(
      'PDF export is not implemented yet for session $sid',
    );
    return Response.ok(
      bytes,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/pdf',
        'Content-Disposition': 'attachment; filename="results_$sid.pdf"',
      },
    );
  }

  /// ws://host/ws?mid=<meetingId>
  Response _wsHandler(Request req) {
    final meetingId = req.requestedUri.queryParameters['mid'] ?? 'default';
    _wsClients.putIfAbsent(meetingId, () => <WebSocketChannel>{});
    return webSocketHandler((socket) {
      _wsClients[meetingId]!.add(socket);
      socket.stream.listen(
        (event) {
          // optional: handle pings or admin commands
        },
        onDone: () {
          _wsClients[meetingId]!.remove(socket);
        },
      );
    })(req);
  }

  // --------------------- HELPERS ---------------------

  static Middleware _cors() {
    Response addCors(Response res) => res.change(
      headers: {
        ...res.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      },
    );

    return (inner) => (req) async {
      if (req.method == 'OPTIONS') {
        return addCors(Response.ok(''));
      }
      final res = await inner(req);
      return addCors(res);
    };
  }

  Response _optionsOk(Request _) => _json({'ok': true});

  void _broadcast(String meetingId, Map<String, dynamic> msg) {
    final set = _wsClients[meetingId];
    if (set == null || set.isEmpty) return;
    final data = jsonEncode(msg);
    for (final c in set) {
      c.sink.add(data);
    }
  }

  /// Find the meeting that contains [sessionId] in its agenda (linear scan is fine for small N).
  Future<String?> _meetingIdForSession(String sessionId) async {
    final all = await meetings.all();
    for (final m in all) {
      if (m.sessionIds.contains(sessionId)) return m.meetingId;
    }
    return null;
  }

  void _startAutoCloser() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final all = await meetings.all();
      for (final m in all) {
        for (final sid in m.sessionIds) {
          final s = await sessions.get(sid);
          if (s != null && s.isOpen && s.isVotingTimeOver) {
            s.close();
            _broadcast(m.meetingId, {
              'type': 'session_closed',
              'sessionId': sid,
            });
          }
        }
      }
    });
  }
}
