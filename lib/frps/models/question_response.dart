class QuestionResponse {
  const QuestionResponse({
    required this.userId,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  final String userId;
  final String questionId;
  final dynamic answer;
  final DateTime answeredAt;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'questionId': questionId,
        'answer': answer,
        'answeredAt': answeredAt.toIso8601String(),
      };

  static QuestionResponse fromJson(Map<String, dynamic> json) => QuestionResponse(
        userId: json['userId'] as String,
        questionId: json['questionId'] as String,
        answer: json['answer'],
        answeredAt: DateTime.parse(json['answeredAt'] as String),
      );
}
