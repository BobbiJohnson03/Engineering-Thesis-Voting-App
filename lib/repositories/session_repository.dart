import 'package:hive/hive.dart';
import '../models/session.dart';
import '../utils/hive_boxes.dart';

class SessionRepository {
  Future<Box<Session>> _box() => HiveBoxes.sessions();

  Future<Session?> getById(String id) async => (await _box()).values.firstWhere(
    (s) => s.sessionId == id,
    orElse: () => null,
  );

  Future<void> upsert(Session s) async => (await _box()).put(s.sessionId, s);

  Future<List<Session>> listByIds(List<String> ids) async {
    final box = await _box();
    return ids.map((id) => box.get(id)).whereType<Session>().toList();
  }
}
