class ReportSection {
  const ReportSection({required this.title, required this.content});

  final String title;
  final String content;

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };

  static ReportSection fromJson(Map<String, dynamic> json) => ReportSection(
        title: json['title'] as String,
        content: json['content'] as String,
      );
}

class Report {
  const Report({required this.userId, required this.date, required this.sections});

  final String userId;
  final DateTime date;
  final List<ReportSection> sections;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'date': date.toIso8601String(),
        'sections': sections.map((section) => section.toJson()).toList(),
      };

  static Report fromJson(Map<String, dynamic> json) => Report(
        userId: json['userId'] as String,
        date: DateTime.parse(json['date'] as String),
        sections: (json['sections'] as List)
            .map((section) => ReportSection.fromJson(section as Map<String, dynamic>))
            .toList(),
      );
}
