enum ReactionCategory {
  namedReactions,
  pericyclic,
  rearrangements,
  organometallics,
  oxidationReduction,
  stereochemistry,
  heterocyclic,
}

extension ReactionCategoryExtension on ReactionCategory {
  String get displayName {
    switch (this) {
      case ReactionCategory.namedReactions:
        return 'Named Reactions';
      case ReactionCategory.pericyclic:
        return 'Pericyclic Reactions';
      case ReactionCategory.rearrangements:
        return 'Molecular Rearrangements';
      case ReactionCategory.organometallics:
        return 'Organometallic Reagents';
      case ReactionCategory.oxidationReduction:
        return 'Redox Transformations';
      case ReactionCategory.stereochemistry:
        return 'Stereoselective Synthesis';
      case ReactionCategory.heterocyclic:
        return 'Heterocyclic Chemistry';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionCategory.namedReactions:
        return '⚗️';
      case ReactionCategory.pericyclic:
        return '🔄';
      case ReactionCategory.rearrangements:
        return '🧬';
      case ReactionCategory.organometallics:
        return '🧪';
      case ReactionCategory.oxidationReduction:
        return '⚡';
      case ReactionCategory.stereochemistry:
        return '🌐';
      case ReactionCategory.heterocyclic:
        return '💠';
    }
  }
}

class ReactionStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? curvedArrowNotes;
  final String? intermediate;

  const ReactionStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.curvedArrowNotes,
    this.intermediate,
  });

  factory ReactionStep.fromJson(Map<String, dynamic> json) {
    return ReactionStep(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      curvedArrowNotes: json['curved_arrow_notes'] as String?,
      intermediate: json['intermediate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'step_number': stepNumber,
    'title': title,
    'description': description,
    if (curvedArrowNotes != null) 'curved_arrow_notes': curvedArrowNotes,
    if (intermediate != null) 'intermediate': intermediate,
  };
}

class ReactionMechanism {
  final String id;
  final String name;
  final List<String> aliases;
  final ReactionCategory category;
  final String summary;
  final String reactants;
  final String reagentsAndConditions;
  final String products;
  final List<ReactionStep> steps;
  final String? svgPath;
  final String? svgUrl;
  final String? svgContent;
  final List<String> keyApplications;
  final List<String> limitations;
  final bool isVerified;

  const ReactionMechanism({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.category,
    required this.summary,
    required this.reactants,
    required this.reagentsAndConditions,
    required this.products,
    this.steps = const [],
    this.svgPath,
    this.svgUrl,
    this.svgContent,
    this.keyApplications = const [],
    this.limitations = const [],
    this.isVerified = false,
  });

  factory ReactionMechanism.fromJson(Map<String, dynamic> json) {
    return ReactionMechanism(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      aliases: List<String>.from(json['aliases'] as List? ?? const []),
      category: ReactionCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String?),
        orElse: () => ReactionCategory.namedReactions,
      ),
      summary: json['summary'] as String? ?? '',
      reactants: json['reactants'] as String? ?? '',
      reagentsAndConditions: json['reagents_and_conditions'] as String? ?? '',
      products: json['products'] as String? ?? '',
      steps: (json['steps'] as List? ?? const [])
          .map((s) => ReactionStep.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      svgPath: json['svg_path'] as String?,
      svgUrl: json['svg_url'] as String?,
      svgContent: json['svg_content'] as String?,
      keyApplications: List<String>.from(json['key_applications'] as List? ?? const []),
      limitations: List<String>.from(json['limitations'] as List? ?? const []),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'category': category.name,
    'summary': summary,
    'reactants': reactants,
    'reagents_and_conditions': reagentsAndConditions,
    'products': products,
    'steps': steps.map((s) => s.toJson()).toList(),
    if (svgPath != null) 'svg_path': svgPath,
    if (svgUrl != null) 'svg_url': svgUrl,
    if (svgContent != null) 'svg_content': svgContent,
    'key_applications': keyApplications,
    'limitations': limitations,
    'is_verified': isVerified,
  };
}


enum AskAiIntent {
  conceptExplanation,
  examAnswer,
  vivaQuestion,
  reactionMechanism,
  quizGeneration,
}
