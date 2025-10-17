import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
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

class AdminHostServer {
  final _router = Router();
  final _wsClients = <String, Set<WebSocketChannel>>{}; // key = meetingId

  HttpServer? _server;
  final MeetingRepository meetings;
  final SessionRepository sessions;
  final TicketRepository tickets;
  final VoteRepository votes;

  AdminHostServer({
    required this.meetings,
    required this.sessions,
    required this.tickets,
    required this.votes,
  }) {
    _router
      ..get('/health', _health)
      ..post(
        '/joinMeeting',
        _joinMeeting,
      ) // issues MeetingPass (JWT verified later)
      ..post('/ticket', _ticket) // lazy ticket issuance
      ..post('/vote', _vote) // append to hash chain
      ..get('/ws', _wsHandler); // ws://host/ws?mid=...
  }

  Future<void> start({InternetAddress? address, int port = 8080}) async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_cors())
        .addHandler(_router);

    _server = await io.serve(handler, address ?? InternetAddress.anyIPv4, port);
    // print('AdminHost running on ${_server!.address.address}:$port');
  }

  Future<void> stop() async => _server?.close(force: true);

  // ---------------- Handlers ----------------

  Response _health(Request req) => Response.ok(
    jsonEncode({'ok': true}),
    headers: {'content-type': 'application/json'},
  );

  Future<Response> _joinMeeting(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final token =
        body['token'] as String?; // TODO: verify JWT (HS256) with SigningKey
    final fp = body['deviceFingerprintHash'] as String?;

    if (token == null) {
      return Response(400, body: '{"error":"missing_token"}');
    }

    // TODO: parse/verify token -> meetingId (payload['mid'])
    final meetingId = body['mid'] as String? ?? 'demo-meeting'; // TEMP for MVP

    final meeting = await meetings.get(meetingId);
    if (meeting == null || !meeting.isOpen) {
      return Response.forbidden('{"error":"meeting_closed"}');
    }

    // Reuse or create MeetingPass (simple MVP: always new)
    final pass = MeetingPass(
      passId: DateTime.now().microsecondsSinceEpoch.toString(),
      meetingId: meeting.meetingId,
      issuedAt: DateTime.now(),
      deviceFingerprintHash: fp,
    );
    // Normally: store in Hive (box meetingPasses); omitted here to stay short.

    // Build agenda
    final agendaSessions = await sessions.listByIds(meeting.sessionIds);
    final agenda = [
      for (final s in agendaSessions)
        {'sessionId': s.sessionId, 'title': s.title, 'isOpen': s.isOpen},
    ];

    return Response.ok(
      jsonEncode({
        'meeting': {
          'meetingId': meeting.meetingId,
          'title': meeting.title,
          'isOpen': meeting.isOpen,
        },
        'passId': pass.passId,
        'agenda': agenda,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _ticket(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final passId = body['passId'] as String?;
    final sessionId = body['sessionId'] as String?;
    final fp = body['deviceFingerprintHash'] as String?;

    if (passId == null || sessionId == null) {
      return Response(400, body: '{"error":"bad_request"}');
    }

    final session = await sessions.getById(sessionId);
    if (session == null || !session.canAcceptVotes) {
      return Response.forbidden('{"error":"session_closed"}');
    }

    final existing = await tickets.findByPassAndSession(passId, sessionId);
    if (existing != null) {
      return Response.ok(
        jsonEncode({
          'ticketId': existing.ticketId,
          'sessionId': existing.sessionId,
          'byPassId': existing.byPassId,
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    final t = Ticket(
      ticketId: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId,
      issuedAt: DateTime.now(),
      used: false,
      revoked: false,
      deviceFingerprintHash: fp,
      byPassId: passId,
    );
    await tickets.save(t);

    return Response.ok(
      jsonEncode({
        'ticketId': t.ticketId,
        'sessionId': t.sessionId,
        'byPassId': t.byPassId,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _vote(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final ticketId = body['ticketId'] as String?;
    final sessionId = body['sessionId'] as String?;
    final questionId = body['questionId'] as String?;
    final selected = (body['selectedOptionIds'] as List?)?.cast<String>() ?? [];

    if ([ticketId, sessionId, questionId].any((e) => e == null)) {
      return Response(400, body: '{"error":"bad_request"}');
    }

    // TODO: check ticket validity (one vote per ticket)
    // TODO: compute hashPrev from Session.ledgerHeadHash, set hashSelf, update head.

    final v = Vote(
      voteId: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId!,
      questionId: questionId!,
      selectedOptionIds: selected,
      submittedAt: DateTime.now(),
      byTicketId: ticketId!,
      hashPrev: '', // fill with current head
      hashSelf: '', // fill with sha256(prev + payload)
    );
    await votes.save(v);

    _broadcast(body['mid'] ?? '', {'type': 'progress', 'sessionId': sessionId});

    return Response.ok(
      '{"ok":true}',
      headers: {'content-type': 'application/json'},
    );
  }

  Response _wsHandler(Request req) {
    final meetingId = req.requestedUri.queryParameters['mid'] ?? 'default';
    _wsClients.putIfAbsent(meetingId, () => <WebSocketChannel>{});
    return webSocketHandler((channel) {
      _wsClients[meetingId]!.add(channel);
      channel.stream.listen(
        (event) {},
        onDone: () => _wsClients[meetingId]!.remove(channel),
      );
    })(req);
  }

  void _broadcast(String meetingId, Map<String, dynamic> msg) {
    final clients = _wsClients[meetingId];
    if (clients == null) return;
    final json = jsonEncode(msg);
    for (final c in clients) {
      c.sink.add(json);
    }
  }

  Middleware _cors() {
    return (inner) => (req) async {
      final res = await inner(req);
      return res.change(
        headers: {
          ...res.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        },
      );
    };
  }
}
