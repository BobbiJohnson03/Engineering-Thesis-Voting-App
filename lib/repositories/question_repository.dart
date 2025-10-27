import 'package:hive/hive.dart';
import '../models/question.dart';
import '_boxes.dart';

class QuestionRepository {
  Box<Question>? _box;

  Future<Box<Question>> _open() async =>
      _box ??= await Hive.openBox<Question>(boxQuestion);

  Future<void> put(Question q) async {
    final box = await _open();
    await box.put(q.questionId, q);
  }

  Future<Question?> get(String id) async {
    final box = await _open();
    return box.get(id);
  }

  Future<List<Question>> byIds(List<String> ids) async {
    final box = await _open();
    return ids.map((id) => box.get(id)).whereType<Question>().toList();
  }
}
