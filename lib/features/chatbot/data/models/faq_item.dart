class FaqItem {
  FaqItem({
    required this.id,
    required this.questionFr,
    required this.questionEn,
    required this.answerFr,
    required this.answerEn,
    required this.category,
  });

  final int id;
  final String questionFr;
  final String questionEn;
  final String answerFr;
  final String answerEn;
  final String category;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as int,
      questionFr: json['question_fr'] as String? ?? '',
      questionEn: json['question_en'] as String? ?? '',
      answerFr: json['answer_fr'] as String? ?? '',
      answerEn: json['answer_en'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }
}
