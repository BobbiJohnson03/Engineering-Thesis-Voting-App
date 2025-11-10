import 'package:hive/hive.dart';
import '../models/secure_vote.dart'; // ✅ Changed from vote.dart
import '_boxes.dart';

class VoteRepository {
  Box<SecureVote>? _box; // ✅ Changed to SecureVote
  Box<String>? _idxByTicket;

  Future<Box<SecureVote>> _open() async =>
      _box ??= await Hive.openBox<SecureVote>(boxVote);

  Future<Box<String>> _openIdx() async =>
      _idxByTicket ??= await Hive.openBox<String>('idx_vote_byTicket');

  Future<void> put(SecureVote vote) async {
    // ✅ Changed parameter type
    final box = await _open();
    final idx = await _openIdx();

    // Check for duplicate votes by ticket
    if (idx.get(vote.ticketId) != null) {
      throw StateError('Vote already exists for ticket ${vote.ticketId}');
    }

    await box.put(vote.id, vote);
    await idx.put(vote.ticketId, vote.id);
  }

  Future<bool> existsByTicketId(String ticketId) async {
    final idx = await _openIdx();
    return idx.get(ticketId) != null;
  }

  Future<List<SecureVote>> forSession(String sessionId) async {
    final box = await _open();
    return box.values
        .where((v) => v.sessionId == sessionId)
        .toList(growable: false);
  }

  Future<List<SecureVote>> forSessionAndQuestion(
    String sessionId,
    String questionId,
  ) async {
    final box = await _open();
    return box.values
        .where((v) => v.sessionId == sessionId && v.questionId == questionId)
        .toList(growable: false);
  }

  Future<SecureVote?> getLastVoteForSession(String sessionId) async {
    final votes = await forSession(sessionId);
    if (votes.isEmpty) return null;

    votes.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return votes.first;
  }

  bool validateVoteSignature(SecureVote vote, String secretKey) {
    return vote.validateSignature(secretKey);
  }
}
