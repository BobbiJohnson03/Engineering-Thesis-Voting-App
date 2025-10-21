// lib/repositories/vote_repository.dart
import 'package:hive/hive.dart';
import '../models/vote.dart';
import '_boxes.dart';

class VoteRepository {
  Box<Vote>? _box;

  Future<Box<Vote>> _open() async => _box ??= await Hive.openBox<Vote>(boxVote);

  Future<void> put(Vote v) async {
    final box = await _open();
    await box.put(v.voteId, v);
  }

  Future<List<Vote>> forSession(String sessionId) async {
    final box = await _open();
    return box.values
        .where((v) => v.sessionId == sessionId)
        .toList(growable: false);
  }
}
