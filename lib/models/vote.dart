import 'package:hive/hive.dart';
part 'vote.g.dart';

@HiveType(typeId: 6)
class Vote extends HiveObject {
  @HiveField(0)
  String voteId; // UUID

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  String questionId;

  @HiveField(3)
  List<String> selectedOptionIds;

  @HiveField(4)
  DateTime submittedAt;

  @HiveField(5)
  String byTicketId; // 1 głos/ticket

  @HiveField(6)
  String hashPrev; // łańcuch

  @HiveField(7)
  String hashSelf;

  Vote({
    required this.voteId,
    required this.sessionId,
    required this.questionId,
    required this.selectedOptionIds,
    required this.submittedAt,
    required this.byTicketId,
    required this.hashPrev,
    required this.hashSelf,
  });
}
