import 'package:hive/hive.dart';
part 'result.g.dart';

@HiveType(typeId: 7)
class Result extends HiveObject {
  @HiveField(0)
  String sessionId;

  @HiveField(1)
  String questionId;

  @HiveField(2)
  Map<String, int> countsByOptionId;

  @HiveField(3)
  DateTime computedAt;

  @HiveField(4)
  String? ledgerHeadHash;

  Result({
    required this.sessionId,
    required this.questionId,
    required this.countsByOptionId,
    required this.computedAt,
    this.ledgerHeadHash,
  });
}
