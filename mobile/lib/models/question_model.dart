/// Modular question matching NestJS `Question` entity.
/// `content` and `answer` stay dynamic (jsonb-compatible).
class QuestionModel {
  final String id;
  final String type;
  final String prompt;
  final Map<String, dynamic> content;
  final dynamic answer;
  final String? unitId;
  final bool isReview;

  const QuestionModel({
    required this.id,
    required this.type,
    required this.prompt,
    required this.content,
    required this.answer,
    this.unitId,
    this.isReview = false,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    Map<String, dynamic> content = {};
    if (rawContent is Map<String, dynamic>) {
      content = rawContent;
    } else if (rawContent is Map) {
      content = Map<String, dynamic>.from(rawContent);
    }

    return QuestionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      prompt: json['prompt'] as String? ?? '',
      content: content,
      answer: json['answer'],
      unitId: json['unitId'] as String? ?? json['unit_id'] as String?,
      isReview: json['isReview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'prompt': prompt,
        'content': content,
        'answer': answer,
        if (unitId != null) 'unitId': unitId,
        'isReview': isReview,
      };

  bool get isMultipleChoice => type == 'multiple_choice';
  bool get isMatching => type == 'matching';
  bool get isClozeTyping => type == 'cloze_typing';

  List<String> get options {
    final raw = content['options'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  String? get correctOption {
    if (answer is Map) {
      final map = Map<String, dynamic>.from(answer as Map);
      return map['correctOption']?.toString();
    }
    if (answer is String) return answer as String;
    return null;
  }
}
