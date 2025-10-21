import 'package:hive/hive.dart';
part 'meeting_pass.g.dart';

/*permission to join the whole meeting */

@HiveType(typeId: 11)
class MeetingPass extends HiveObject {
  @HiveField(0)
  String passId; // UUID

  @HiveField(1)
  String meetingId;

  @HiveField(2)
  DateTime issuedAt;

  @HiveField(3)
  bool revoked; /* If admin decides to invalidate a ticket (e.g., participant leaves the meeting, or technical issue),
they can mark revoked = true to disable it. */

  @HiveField(4)
  String? deviceFingerprintHash; // best-effort (optional)

  MeetingPass({
    required this.passId,
    required this.meetingId,
    required this.issuedAt,
    this.revoked = false,
    this.deviceFingerprintHash,
  });
}
