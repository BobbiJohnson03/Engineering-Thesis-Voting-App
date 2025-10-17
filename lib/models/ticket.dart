import 'package:hive/hive.dart';
part 'ticket.g.dart';

@HiveType(typeId: 5)
class Ticket extends HiveObject {
  @HiveField(0)
  String ticketId;

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  DateTime issuedAt;

  @HiveField(3)
  bool used;

  @HiveField(4)
  bool revoked;

  @HiveField(5)
  String? deviceFingerprintHash;

  @HiveField(6)
  String byPassId; // NEW: binds ticket to a MeetingPass

  Ticket({
    required this.ticketId,
    required this.sessionId,
    required this.issuedAt,
    this.used = false,
    this.revoked = false,
    this.deviceFingerprintHash,
    required this.byPassId, // NEW: required
  });
}
