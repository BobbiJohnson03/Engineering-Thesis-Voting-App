import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/meeting.dart';
import '../models/meeting_pass.dart';
import '../models/session.dart';
import '../models/ticket.dart';
import '../models/vote.dart';

import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/vote_repository.dart';

Response _json(Object body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  },
);

/// Admin host = tiny local HTTP + WebSocket server.
/// - /joinMeeting → issues MeetingPass (MVP: in-memory) and returns agenda
/// - /ticket      → idempotent ticket issuance bound to MeetingPass
/// - /vote        → appends vote to ledger (hash chain), marks ticket used
/// - /ws          → websocket broadcast per meeting
class AdminHostServer {
  HttpServer? _server;

  final MeetingRepository meetings;
  final SessionRepository sessions;
  final TicketRepository tickets;
  final VoteRepository votes;

  /// WS clients grouped by meetingId
  final Map<String, Set<WebSocketChannel>> _wsClients = {};

  AdminHostServer({
    required this.meetings,
    required this.sessions,
    required this.tickets,
    required this.votes,
  });

  Future<void> start({InternetAddress? address, int port = 8080}) async {
    final router =
        Router()
          ..get('/health', _health)
          ..post('/joinMeeting', _joinMeeting)
          ..post('/ticket', _ticket)
          ..post('/vote', _vote)
          ..get('/ws', _wsHandler)
          ..options('/<ignored|.*>', _optionsOk); // CORS preflight

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_cors())
        .addHandler(router);

    _server = await io.serve(handler, address ?? InternetAddress.anyIPv4, port);
    // print('AdminHost listening on http://${_server!.address.address}:$port');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  // --------------------- ROUTES ---------------------

  Response _health(Request _) => _json({'ok': true});

  /// Body:
  /// {
  ///   "token": "...",                // (MVP: optional; JWT verify TODO)
  ///   "mid": "meetingId",           // allow explicit for MVP
  ///   "deviceFingerprintHash": "..."// optional
  /// }
  Future<Response> _joinMeeting(Request req) async {
    final Map<String, dynamic> body =
        jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    // TODO: verify JWT HS256 and extract meetingId. For MVP accept "mid".
    final meetingId = (body['mid'] as String?)?.trim();
    if (meetingId == null || meetingId.isEmpty) {
      return _json({'error': 'missing_meeting_id'}, status: 400);
    }

    final Meeting? meeting = await meetings.get(meetingId);
    if (meeting == null)
      return _json({'error': 'meeting_not_found'}, status: 404);
    if (!meeting.isOpen || meeting.isOver) {
      return _json({'error': 'meeting_closed'}, status: 403);
    }

    // MVP: MeetingPass not persisted yet (we can add MeetingPassRepository later)
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

  /// Body:
  /// { "passId": "...", "sessionId": "...", "deviceFingerprintHash": "..." }
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
      byPassId: passId,
      deviceFingerprintHash: fp,
    );

    return _json({
      'ticketId': t.ticketId,
      'sessionId': t.sessionId,
      'byPassId': t.byPassId,
    });
  }

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

    // Validate session open.
    final Session? s = await sessions.get(sessionId!);
    if (s == null) return _json({'error': 'session_not_found'}, status: 404);
    if (!s.canAcceptVotes)
      return _json({'error': 'session_closed'}, status: 403);

    // Validate ticket.
    final Ticket? t = await tickets.get(ticketId!);
    if (t == null) return _json({'error': 'invalid_ticket'}, status: 403);
    if (t.revoked) return _json({'error': 'ticket_revoked'}, status: 403);
    if (t.used) return _json({'error': 'ticket_already_used'}, status: 409);
    if (t.sessionId != sessionId) {
      return _json({'error': 'ticket_session_mismatch'}, status: 400);
    }

    // --- Hash chain ---
    final prev = s.ledgerHeadHash ?? '';
    // Create a stable payload string for hashing.
    final payload = jsonEncode({
      'sessionId': sessionId,
      'questionId': questionId,
      'selectedOptionIds': selected,
      'byTicketId': ticketId,
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
      'prev': prev,
    });
    final hashSelf = sha256.convert(utf8.encode(payload)).toString();

    final v = Vote(
      voteId: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId,
      questionId: questionId!,
      selectedOptionIds: selected,
      submittedAt: DateTime.now(),
      byTicketId: ticketId,
      hashPrev: prev,
      hashSelf: hashSelf,
    );

    // Persist
    await votes.put(v);
    await tickets.markUsed(ticketId);
    s.updateLedgerHead(hashSelf); // persists via HiveObject.save()

    // Broadcast progress to all WS clients of the meeting that contains this session.
    final String? meetingId = await _meetingIdForSession(sessionId);
    if (meetingId != null) {
      _broadcast(meetingId, {
        'type': 'progress',
        'sessionId': sessionId,
        'questionId': questionId,
      });
    }

    return _json({'ok': true});
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
    // (Later we can keep a reverse index: sessionId -> meetingId)
  }
}
