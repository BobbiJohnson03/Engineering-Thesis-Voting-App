// lib/repositories/meeting_repository.dart
import 'package:hive/hive.dart';
import '../models/meeting.dart';
import '_boxes.dart';

class MeetingRepository {
  Box<Meeting>? _box;

  Future<Box<Meeting>> _open() async =>
      _box ??= await Hive.openBox<Meeting>(boxMeeting);

  Future<void> put(Meeting m) async {
    final box = await _open();
    await box.put(m.meetingId, m);
  }

  Future<Meeting?> get(String id) async {
    final box = await _open();
    return box.get(id);
  }

  Future<List<Meeting>> all() async {
    final box = await _open();
    return box.values.toList(growable: false);
  }
}
