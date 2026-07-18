class WordExample {
  final String english;
  final String persian;

  const WordExample({
    required this.english,
    required this.persian,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      english: json['english'] as String? ?? '',
      persian: json['persian'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'english': english,
        'persian': persian,
      };
}

/// Matches NestJS `Word` entity / JSON response (camelCase + jsonb examples).
class WordModel {
  final String id;
  final String word;
  final String persianMeaning;
  final List<String> synonyms;
  final List<WordExample> examples;
  final String? unitId;

  const WordModel({
    required this.id,
    required this.word,
    required this.persianMeaning,
    this.synonyms = const [],
    this.examples = const [],
    this.unitId,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final rawExamples = json['examples'];
    final examples = <WordExample>[];
    if (rawExamples is List) {
      for (final item in rawExamples) {
        if (item is Map<String, dynamic>) {
          examples.add(WordExample.fromJson(item));
        } else if (item is Map) {
          examples.add(
            WordExample.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawSynonyms = json['synonyms'];
    final synonyms = <String>[];
    if (rawSynonyms is List) {
      synonyms.addAll(rawSynonyms.map((e) => e.toString()));
    }

    return WordModel(
      id: json['id'] as String,
      word: json['word'] as String,
      persianMeaning: json['persianMeaning'] as String? ??
          json['persian_meaning'] as String? ??
          '',
      synonyms: synonyms,
      examples: examples,
      unitId: json['unitId'] as String? ?? json['unit_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'persianMeaning': persianMeaning,
        'synonyms': synonyms,
        'examples': examples.map((e) => e.toJson()).toList(),
        if (unitId != null) 'unitId': unitId,
      };
}
