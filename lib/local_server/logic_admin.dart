import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/vote_repository.dart';
import '../repositories/question_repository.dart';
import '../models/secure_vote.dart';
import 'broadcast_manager.dart';
import 'logic_helpers.dart';

class LogicAdmin {
  final MeetingRepository meetings;
  final SessionRepository sessions;
  final VoteRepository votes;
  final QuestionRepository questions;
  final BroadcastManager broadcast;

  LogicAdmin({
    required this.meetings,
    required this.sessions,
    required this.votes,
    required this.questions,
    required this.broadcast,
  });

  Future<Response> results(Request req) async {
    final sessionId = req.url.queryParameters['sessionId'];
    if (sessionId == null) return _errorResponse('Missing sessionId');

    final session = await sessions.get(sessionId);
    if (session == null) return _errorResponse('Session not found');

    final sessionVotes = await votes.forSession(sessionId);
    final results = await _calculateResults(sessionVotes);

    return _successResponse({'results': results});
  }

  Future<Response> closeSession(Request req) async {
    final body = await readJson(req);
    final sessionId = body['sessionId'] as String?;

    if (sessionId == null) return _errorResponse('Missing sessionId');

    final session = await sessions.get(sessionId);
    if (session == null) return _errorResponse('Session not found');

    session.close();

    broadcast.send(session.meetingId, {
      'type': 'session_closed',
      'sessionId': sessionId,
    });

    return _successResponse({'message': 'Session closed'});
  }

  Future<Map<String, dynamic>> _calculateResults(List<SecureVote> votes) async {
    final Map<String, Map<String, int>> tallies = {};

    for (final vote in votes) {
      final questionTallies = tallies.putIfAbsent(
        vote.questionId,
        () => <String, int>{},
      );

      for (final optionId in vote.selectedOptionIds) {
        questionTallies[optionId] = (questionTallies[optionId] ?? 0) + 1;
      }
    }

    return tallies;
  }

  Response _successResponse(Map<String, dynamic> data) {
    return Response.ok(
      jsonEncode({'success': true, ...data}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _errorResponse(String message, {int status = 400}) {
    return Response(
      status,
      body: jsonEncode({'success': false, 'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
