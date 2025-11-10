import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../repositories/session_repository.dart';
import '../repositories/ticket_repository.dart';
import '../repositories/vote_repository.dart';
import '../repositories/question_repository.dart';
import '../repositories/signing_key_repository.dart';
import '../models/secure_vote.dart';
import '../models/question.dart';
import 'broadcast_manager.dart';
import 'logic_helpers.dart';

class LogicVote {
  final SessionRepository sessions;
  final TicketRepository tickets;
  final VoteRepository votes;
  final QuestionRepository questions;
  final SigningKeyRepository signingKeys;
  final BroadcastManager broadcast;
  final Uuid _uuid = Uuid();

  LogicVote({
    required this.sessions,
    required this.tickets,
    required this.votes,
    required this.questions,
    required this.signingKeys,
    required this.broadcast,
  });

  Future<Response> submitVote(Request req) async {
    final body = await readJson(req);
    final ticketId = body['ticketId'] as String?;
    final sessionId = body['sessionId'] as String?;
    final questionId = body['questionId'] as String?;
    final selectedOptions =
        (body['selectedOptionIds'] as List?)?.cast<String>() ?? [];

    // Validation
    if (ticketId == null || sessionId == null || questionId == null) {
      return jsonErr('Missing required fields');
    }

    final session = await sessions.get(sessionId);
    final ticket = await tickets.get(ticketId);
    final question = await questions.get(questionId);

    if (session == null) return jsonErr('Session not found');
    if (ticket == null) return jsonErr('Invalid ticket');
    if (question == null) return jsonErr('Question not found');
    if (!session.canVote) return jsonErr('Session closed');
    if (ticket.isUsed) return jsonErr('Ticket already used');
    if (!ticket.isValid) return jsonErr('Ticket expired');
    if (!_isValidSelection(selectedOptions, question)) {
      return jsonErr('Invalid option selection');
    }

    // Get signing key for session
    final sessionKeys = await signingKeys.forSession(sessionId);
    final signingKey = sessionKeys.isNotEmpty ? sessionKeys.first : null;
    if (signingKey == null) return jsonErr('Session configuration error');

    // Check for duplicate vote by ticket
    final hasVoted = await votes.existsByTicketId(ticketId);
    if (hasVoted) return jsonErr('Already voted with this ticket');

    // Get previous vote for hash chain
    final previousVote = await votes.getLastVoteForSession(sessionId);
    final previousHash = previousVote?.voteHash ?? '0';

    // Create secure vote
    final vote = SecureVote(
      id: _uuid.v4(),
      sessionId: sessionId,
      questionId: questionId,
      selectedOptionIds: selectedOptions,
      submittedAt: DateTime.now().toUtc(),
      ticketId: ticketId,
      previousVoteHash: previousHash,
      voteHash: '', // Will be computed
      nonce: _uuid.v4(),
      signature: '', // Will be computed
    );

    // Compute hash and signature
    final computedHash = vote.computeHash();
    final signature = SecureVote.generateHMAC(signingKey.secret, computedHash);

    // Create final vote with computed values
    final finalVote = SecureVote(
      id: vote.id,
      sessionId: vote.sessionId,
      questionId: vote.questionId,
      selectedOptionIds: vote.selectedOptionIds,
      submittedAt: vote.submittedAt,
      ticketId: vote.ticketId,
      previousVoteHash: vote.previousVoteHash,
      voteHash: computedHash,
      nonce: vote.nonce,
      signature: signature,
    );

    // Validate signature
    if (!finalVote.validateSignature(signingKey.secret)) {
      return jsonErr('Vote security validation failed');
    }

    // Save vote and mark ticket as used
    await votes.put(finalVote);
    await tickets.markAsUsed(ticketId);

    // Update session ledger head
    session.ledgerHeadHash = finalVote.voteHash;
    await session.save();

    broadcast.send(session.meetingId, {
      'type': 'vote_received',
      'sessionId': sessionId,
      'questionId': questionId,
      'voteId': finalVote.id,
    });

    return jsonOk({
      'success': true,
      'voteId': finalVote.id,
      'message': 'Vote submitted successfully',
    });
  }

  bool _isValidSelection(List<String> selected, Question question) {
    if (selected.isEmpty) return false;
    if (selected.length > question.maxSelections) return false;

    final validOptionIds = question.options.map((o) => o.id).toSet();
    return selected.every((id) => validOptionIds.contains(id));
  }
}
