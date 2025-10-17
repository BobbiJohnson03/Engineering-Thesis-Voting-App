import 'package:hive/hive.dart';
import '../models/meeting.dart';
import '../utils/hive_boxes.dart';

class MeetingRepository {
  Future<Box<Meeting>> _box() => HiveBoxes.meetings();

  Future<void> upsert(Meeting m) async => (await _box()).put(m.meetingId, m);

  Future<Meeting?> get(String meetingId) async => (await _box()).get(meetingId);

  Future<List<Meeting>> allOpen() async =>
      (await _box()).values.where((m) => m.isOpen).toList();
}
