import "package:vote_app_thesis/models/option.dart";
import 'package:hive/hive.dart';
part 'question.g.dart';

/* pojedyncze pytanie; admin tworzy kilka takich pytań i grupuje je następnie w Session */
@HiveType(typeId: 5)
class Question extends HiveObject {
  @HiveField(0)
  final String id; // Not questionId

  @HiveField(1)
  String text;

  @HiveField(2)
  List<Option> options; // Simplified Option

  @HiveField(3)
  int maxSelections; // Not maxSelectable, not nullable

  @HiveField(4)
  int displayOrder; // Not displayGroup

  @HiveField(5)
  String sessionId; // Not meetingId (Question → Session → Meeting)

  Question({
    required this.id,
    required this.text,
    required this.options,
    this.maxSelections = 1, // Default to single selection
    this.displayOrder = 0,
    required this.sessionId,
  });
}
