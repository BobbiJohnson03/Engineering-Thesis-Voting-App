import 'package:hive/hive.dart';
part 'audit_log.g.dart';

@HiveType(typeId: 8)
class AuditLog extends HiveObject {
  @HiveField(0)
  String action; // 'session_created' | 'ticket_issued' | ...
  @HiveField(1)
  String sessionId;
  @HiveField(2)
  String? subjectId; // np. ticketId / voteId / questionId
  @HiveField(3)
  DateTime timestamp;
  @HiveField(4)
  String? details; // JSON/text

  AuditLog({
    required this.action,
    required this.sessionId,
    this.subjectId,
    required this.timestamp,
    this.details,
  });
}
