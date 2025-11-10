import "package:vote_app_thesis/models/enums.dart";
import 'package:hive/hive.dart';
part 'session.g.dart';

@HiveType(typeId: 6) // FIXED: Changed from 4 to 6 to avoid conflict
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  SessionType type;

  @HiveField(3)
  AnswersSchema answersSchema;

  @HiveField(4)
  List<String> questionIds;

  @HiveField(5)
  SessionStatus status; // Single source of truth

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? endsAt; // Combined: voting ends + session expires

  @HiveField(8)
  String jwtKeyId;

  @HiveField(9)
  String? ledgerHeadHash;

  @HiveField(10)
  String joinCode;

  @HiveField(11)
  String meetingId;

  Session({
    required this.id,
    required this.title,
    required this.type,
    required this.answersSchema,
    this.questionIds = const [],
    this.status = SessionStatus.open,
    required this.createdAt,
    this.endsAt,
    required this.jwtKeyId,
    this.ledgerHeadHash,
    this.joinCode = '',
    required this.meetingId,
  });

  // Simplified logic:
  bool get canVote =>
      status == SessionStatus.open &&
      (endsAt == null || DateTime.now().isBefore(endsAt!));

  bool get canView => status != SessionStatus.archived;

  void close() {
    status = SessionStatus.closed;
    save();
  }

  void archive() {
    status = SessionStatus.archived;
    save();
  }
}
