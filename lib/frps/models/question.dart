enum QuestionType { multipleChoice, numeric, freeText }

class Question {
  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });

  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
}
