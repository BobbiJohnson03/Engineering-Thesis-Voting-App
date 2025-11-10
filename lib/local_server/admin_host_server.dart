import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'broadcast_manager.dart';
import 'auto_close_manager.dart';
import 'logic_join_ticket.dart';
import 'logic_vote.dart';
import 'logic_manifest.dart';
import 'logic_admin.dart';

import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/vote_repository.dart';
import '../repositories/question_repository.dart';
import '../repositories/meeting_pass_repository.dart';
import '../repositories/signing_key_repository.dart';
import 'package:flutter/foundation.dart';

class AdminHostServer {
  HttpServer? _server;

  late final BroadcastManager broadcast;
  late final AutoCloseManager autoClose;

  late final LogicJoinTicket lt;
  late final LogicVote lv;
  late final LogicManifest lm;
  late final LogicAdmin la;

  AdminHostServer({
    required MeetingRepository meetings,
    required SessionRepository sessions,
    required TicketRepository tickets,
    required VoteRepository votes,
    required QuestionRepository questions,
    required MeetingPassRepository meetingPasses,
    required SigningKeyRepository signingKeys,
  }) {
    broadcast = BroadcastManager();

    lt = LogicJoinTicket(
      meetings: meetings,
      sessions: sessions,
      tickets: tickets,
      meetingPasses: meetingPasses,
      broadcast: broadcast,
    );

    lv = LogicVote(
      sessions: sessions,
      tickets: tickets,
      votes: votes,
      questions: questions,
      signingKeys: signingKeys,
      broadcast: broadcast,
    );

    lm = LogicManifest(sessions: sessions, questions: questions);

    la = LogicAdmin(
      meetings: meetings,
      sessions: sessions,
      votes: votes,
      questions: questions,
      broadcast: broadcast,
    );

    autoClose = AutoCloseManager(meetings, sessions, broadcast);
  }

  Future<void> start({InternetAddress? address, int port = 8080}) async {
    final router =
        Router()
          ..get('/health', (req) => _jsonResponse({'ok': true}))
          ..get('/manifest', lm.manifest)
          ..post('/join', lt.joinMeeting)
          ..post('/ticket', lt.requestTicket)
          ..post('/vote', lv.submitVote)
          ..get('/admin/results', la.results)
          ..post('/admin/close', la.closeSession)
          ..get('/ws', broadcast.handleWs)
          ..options('/<ignored|.*>', (req) => Response.ok(''));

    final apiHandler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware)
        .addHandler(router.call);

    final staticHandler = createStaticHandler(
      'build/web',
      defaultDocument: 'index.html',
      listDirectories: false,
    );

    final cascade = Cascade().add(staticHandler).add(apiHandler).handler;

    _server = await io.serve(cascade, address ?? InternetAddress.anyIPv4, port);
    autoClose.start();

    if (kDebugMode) {
      debugPrint(
        'AdminHost listening on http://${_server!.address.address}:$port',
      );
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    autoClose.stop();
    _server = null;
  }

  static Middleware get _corsMiddleware {
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

  Response _jsonResponse(Map<String, dynamic> data, {int status = 200}) {
    return Response.ok(
      jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
