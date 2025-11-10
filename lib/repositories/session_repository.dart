// lib/repositories/session_repository.dart
import 'package:hive/hive.dart';
import '../models/session.dart';
import '_boxes.dart';

class SessionRepository {
  Box<Session>? _box;

  Future<Box<Session>> _open() async =>
      _box ??= await Hive.openBox<Session>(boxSession);

  Future<void> put(Session s) async {
    final box = await _open();
    await box.put(s.id, s);
  }

  Future<Session?> get(String id) async {
    final box = await _open();
    return box.get(id);
  }

  Future<List<Session>> byIds(List<String> ids) async {
    final box = await _open();
    return ids.map((id) => box.get(id)).whereType<Session>().toList();
  }

  Future<void> update(Session s) async {
    final box = await _open();
    await box.put(s.id, s);
  }

  Future<List<Session>> forMeeting(String meetingId) async {
    final box = await _open();
    return box.values
        .where((s) => s.meetingId == meetingId)
        .toList(growable: false);
  }

  Future<List<Session>> openForMeeting(String meetingId) async {
    final box = await _open();
    return box.values
        .where(
          (s) => s.meetingId == meetingId && s.canVote,
        ) // ✅ Uses canVote getter
        .toList(growable: false);
  }
}
