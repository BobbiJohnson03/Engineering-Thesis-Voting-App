import 'package:hive/hive.dart';
part 'enums.g.dart';

/* definiuje dwa typy enumeracji, które pełnią kluczową rolę w logice głosowań
określają jakie typy sesji i jakie schematy odpowiedzi są w ogóle możliwe w aplikacji */

// typ sesji głosowania: publiczna (wyniki jawne) lub tajna (wyniki ukryte)
@HiveType(typeId: 0)
enum SessionType {
  @HiveField(0)
  public,
  @HiveField(1)
  secret,
}

// schemat odpowiedzi: tak/nie, tak/nie/wstrzymaj się lub niestandardowy (zdefiniowany przez admina)
@HiveType(typeId: 1)
enum AnswersSchema {
  @HiveField(0)
  yesNo,
  @HiveField(1)
  yesNoAbstain,
  @HiveField(2)
  custom,
}
