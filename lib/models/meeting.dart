import 'package:hive/hive.dart';
part 'meeting.g.dart';

@HiveType(typeId: 10)
class Meeting extends HiveObject {
  @HiveField(0)
  String meetingId; // UUID

  @HiveField(1)
  String title; // e.g., "Senate Meeting – Oct 2025"

  @HiveField(2)
  List<String> sessionIds; // sessions that belong to this meeting

  @HiveField(3)
  bool isOpen; // meeting is active (lobby/WS open)

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? endsAt; // optional global window

  @HiveField(6)
  String shortCode; // manual join code for meeting

  @HiveField(7)
  String jwtKeyId; // key used to sign meeting join tokens

  Meeting({
    required this.meetingId,
    required this.title,
    this.sessionIds = const [],
    this.isOpen = true,
    required this.createdAt,
    this.endsAt,
    this.shortCode = '',
    required this.jwtKeyId,
  });

  bool get isOver => endsAt != null && DateTime.now().isAfter(endsAt!);
}
