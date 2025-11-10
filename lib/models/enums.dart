import 'package:hive/hive.dart';
part 'enums.g.dart';

/* typ sesji głosowania */
@HiveType(typeId: 0)
enum SessionType {
  @HiveField(0)
  nonsecret,
  @HiveField(1)
  secret,
}

/* schemat odpowiedzi */
@HiveType(typeId: 1)
enum AnswersSchema {
  @HiveField(0)
  yesNo,
  @HiveField(1)
  yesNoAbstain,
  @HiveField(2)
  custom,
}

/* Nstatus sesji */
@HiveType(typeId: 2)
enum SessionStatus {
  @HiveField(0)
  open,
  @HiveField(1)
  closed,
  @HiveField(2)
  archived,
}

@HiveType(typeId: 13)
enum AuditAction {
  @HiveField(0)
  sessionCreated,

  @HiveField(1)
  voteSubmitted,
  @HiveField(2)
  ticketIssued,
  @HiveField(3)
  meetingJoined,
  @HiveField(4)
  sessionClosed,
}
