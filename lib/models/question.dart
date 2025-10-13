import 'package:hive/hive.dart';
part 'question.g.dart';

@HiveType(typeId: 2)
class OptionModel /* pojedyncza opcja odpowiedzi na pytanie */ {
  @HiveField(0)
  String id;
  @HiveField(1)
  String label;
  @HiveField(2)
  int order;
  OptionModel({required this.id, required this.label, required this.order});
}

@HiveType(typeId: 3)
class Question
    extends
        HiveObject /* pojedyncze pytanie w sesji głosowania
admin tworzy kilka takich pytań i grupuje je w modelu Session */ {
  @HiveField(0)
  String questionId;

  @HiveField(1)
  String text; // treść pytania

  @HiveField(2)
  List<OptionModel> options; // lista dostępnych opcji odpowiedzi

  @HiveField(3)
  int? maxSelectable; // maksymalna liczba opcji do zaznaczenia (null = brak limitu)

  @HiveField(4)
  int displayGroup; // numer strony wyświetlania (pytania z tym samym numerem grupy wyświetlane razem)

  Question({
    required this.questionId,
    required this.text,
    required this.options,
    this.maxSelectable,
    this.displayGroup = 0,
  });
}
