import 'package:hive/hive.dart';
import 'enums.dart';
part 'session.g.dart';

@HiveType(typeId: 4)
class Session extends HiveObject {
  @HiveField(0)
  String sessionId; // unikalny identyfikator sesji

  @HiveField(1)
  String title; // tytuł sesji

  @HiveField(2)
  SessionType type;
  // Steruje jawnością: w secret nie łączymy głosu z tożsamością; w public można (narazie niedodane w implementacji)

  @HiveField(3)
  AnswersSchema answersSchema;
  // Domyślny schemat odpowiedzi (yes/no, yes/no/abstain lub custom)

  @HiveField(4)
  Map<String, int> maxSelectionsPerQuestion;
  // maksymalna liczba wyborów na pytanie (jeśli dotyczy)

  @HiveField(5)
  List<String> questionIds;
  // Lista pytań należących do sesji

  @HiveField(6)
  bool isOpen; // czy sesja jest otwarta na głosowanie

  @HiveField(7)
  DateTime createdAt; // metadane / sortowanie / PDF

  @HiveField(8)
  DateTime? expiresAt;
  // ważność tokenów dołączenia (join JWT) — po tej dacie nie można dołączać

  @HiveField(9)
  String jwtKeyId;
  // Id klucza HMAC (SigningKey) do podpisywania join-tokenów

  @HiveField(10)
  bool archived; // sesja zarchiwizowana (tylko podgląd + eksport)

  @HiveField(11)
  String? ledgerHeadHash;
  // aktualna głowa łańcucha hash (dla szybkiej weryfikacji)

  @HiveField(12)
  DateTime? votingEndsAt; // twardy koniec przyjmowania głosów (auto-close)

  @HiveField(13)
  String shortCode; // np. "A7F9K2" – fallback dla ręcznego dołączenia

  Session({
    required this.sessionId,
    required this.title,
    required this.type,
    required this.answersSchema,
    this.maxSelectionsPerQuestion = const {},
    this.questionIds = const [],
    this.isOpen = true,
    required this.createdAt,
    this.expiresAt,
    required this.jwtKeyId,
    this.archived = false,
    this.ledgerHeadHash,
    this.votingEndsAt,
    this.shortCode = '', // ← domyślnie puste, lub zrób `required`
  });

  // JOIN tokeny wygasły?
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Głosowanie po czasie?
  bool get isVotingTimeOver =>
      votingEndsAt != null && DateTime.now().isAfter(votingEndsAt!);

  // Czy można przyjąć nowy głos TERAZ?
  bool get canAcceptVotes => isOpen && !isVotingTimeOver;

  // zakończ sesję (bez archiwizacji)
  void close() {
    isOpen = false;
    save();
  }

  // archiwizacja po zamknięciu
  void archive() {
    archived = true;
    save();
  }

  // unieważnij stare join-QR (rotacja klucza)
  void rotateJoinKey(String newKeyId) {
    jwtKeyId = newKeyId;
    save();
  }

  // aktualizacja głowy łańcucha po zapisie głosu
  void updateLedgerHead(String newHead) {
    ledgerHeadHash = newHead;
    save();
  }
}
