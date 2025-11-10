import 'package:shelf/shelf.dart';
import '../repositories/session_repository.dart';
import '../repositories/question_repository.dart';
import 'logic_helpers.dart';

class LogicManifest {
  final SessionRepository sessions;
  final QuestionRepository questions;

  LogicManifest({required this.sessions, required this.questions});

  Future<Response> manifest(Request req) async {
    final sessionId = req.requestedUri.queryParameters['sessionId']?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      return jsonErr('Missing sessionId', status: 400);
    }

    final session = await sessions.get(sessionId);
    if (session == null) {
      return jsonErr('Session not found', status: 404);
    }

    final questionsList = await questions.byIds(session.questionIds);
    final questionsJson = [
      for (final question in questionsList)
        {
          'id': question.id,
          'text': question.text,
          'maxSelections': question.maxSelections,
          'displayOrder': question.displayOrder,
          'options': [
            for (final option in question.options)
              {'id': option.id, 'text': option.text},
          ],
        },
    ];

    return jsonOk({
      'sessionId': session.id,
      'title': session.title,
      'type': session.type.name,
      'answersSchema': session.answersSchema.name,
      'status': session.status.name,
      'canVote': session.canVote,
      'endsAt': session.endsAt?.toIso8601String(),
      'questions': questionsJson,
    });
  }
}
