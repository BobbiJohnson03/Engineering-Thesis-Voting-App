import 'package:hive/hive.dart';
import '../models/vote.dart';
import '../utils/hive_boxes.dart';

class VoteRepository {
  Future<Box<Vote>> _box() => HiveBoxes.votes();

  Future<void> save(Vote v) async => (await _box()).put(v.voteId, v);

  Future<List<Vote>> forSession(String sessionId) async =>
      (await _box()).values.where((v) => v.sessionId == sessionId).toList();
}
