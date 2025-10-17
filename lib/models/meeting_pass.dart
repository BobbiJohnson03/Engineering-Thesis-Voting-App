import 'package:hive/hive.dart';
part 'meeting_pass.g.dart';

@HiveType(typeId: 15)
class MeetingPass extends HiveObject {
  @HiveField(0)
  String passId; // UUID

  @HiveField(1)
  String meetingId;

  @HiveField(2)
  DateTime issuedAt;

  @HiveField(3)
  bool revoked;

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
