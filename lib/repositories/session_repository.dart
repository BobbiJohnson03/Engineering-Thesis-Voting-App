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
    await box.put(s.sessionId, s);
  }

  Future<Session?> get(String id) async {
    final box = await _open();
    return box.get(id);
  }

  Future<List<Session>> byIds(List<String> ids) async {
    final box = await _open();
    return ids.map((id) => box.get(id)).whereType<Session>().toList();
  }
}
