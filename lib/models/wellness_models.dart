// Flutter Models for Jeevan Sutra - Living Intelligence
// Null-safe, production-ready Dart data structures

enum DoshaType { vata, pitta, kapha, tridoshic }

enum RoutineTimeOfDay { morning, daytime, evening, night }

enum SeasonType { shishira, vasanta, grishma, varsha, sharad, hemanta }

class UserProfile {
  String name;
  String ageGroup;
  String dominantPrakriti;
  List<String> goals;
  String dietaryPreference;
  String preferredLanguage;

  UserProfile({
    required this.name,
    required this.ageGroup,
    required this.dominantPrakriti,
    required this.goals,
    required this.dietaryPreference,
    required this.preferredLanguage,
  });

  UserProfile copyWith({
    String? name,
    String? ageGroup,
    String? dominantPrakriti,
    List<String>? goals,
    String? dietaryPreference,
    String? preferredLanguage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      dominantPrakriti: dominantPrakriti ?? this.dominantPrakriti,
      goals: goals ?? this.goals,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}

class RoutineItem {
  final String id;
  final String title;
  final String sanskritName;
  final String time;
  final RoutineTimeOfDay period;
  final String description;
  final String benefits;
  final DoshaType balancingDosha;
  bool isCompleted;

  RoutineItem({
    required this.id,
    required this.title,
    required this.sanskritName,
    required this.time,
    required this.period,
    required this.description,
    required this.benefits,
    required this.balancingDosha,
    this.isCompleted = false,
  });
}

class MedicinalPlant {
  final String id;
  final String commonName;
  final String botanicalName;
  final String sanskritName;
  final String category;
  final String primaryUses;
  final String traditionalApplication;
  final String scientificEvidence;
  final String dosageAndPreparation;
  final String precautions;
  final List<DoshaType> balancesDosha;
  final String rasa; // Taste
  final String virya; // Potency
  final String vipaka; // Post-digestive effect
  bool isBookmarked;

  // Convenience aliases for compatibility with older screen code
  String get name => commonName;
  List<DoshaType> get balancingDosha => balancesDosha;
  String get taste => rasa;
  String get potency => virya;
  String get postDigestiveEffect => vipaka;
  String get contraindications => precautions;

  MedicinalPlant({
    required this.id,
    required this.commonName,
    required this.botanicalName,
    required this.sanskritName,
    required this.category,
    required this.primaryUses,
    required this.traditionalApplication,
    required this.scientificEvidence,
    required this.dosageAndPreparation,
    required this.precautions,
    required this.balancesDosha,
    required this.rasa,
    required this.virya,
    required this.vipaka,
    this.isBookmarked = false,
  });
}

class MealSuggestion {
  final String id;
  final String title;
  final String mealType; // Breakfast, Lunch, Snack, Dinner
  final String sanskritConcept;
  final String description;
  final List<String> ingredients;
  final String preparationTime;
  final String caloriesEst;
  final String doshaEffect;
  final List<String> benefits;
  bool isBookmarked;

  // Convenience aliases
  String get name => title;
  String get sanskritName => sanskritConcept;
  String get timing => preparationTime;

  MealSuggestion({
    required this.id,
    required this.title,
    required this.mealType,
    required this.sanskritConcept,
    required this.description,
    required this.ingredients,
    required this.preparationTime,
    required this.caloriesEst,
    required this.doshaEffect,
    required this.benefits,
    this.isBookmarked = false,
  });
}

class YogaMeditationSession {
  final String id;
  final String title;
  final String sanskritTitle;
  final String category; // Asana, Pranayama, Dhyana, Nidra
  final int durationMinutes;
  final String intensity; // Gentle, Moderate, Restorative
  final String description;
  final List<String> steps;
  final String modernBenefits;
  bool isBookmarked;

  // Convenience alias
  String get name => title;

  YogaMeditationSession({
    required this.id,
    required this.title,
    required this.sanskritTitle,
    required this.category,
    required this.durationMinutes,
    required this.intensity,
    required this.description,
    required this.steps,
    required this.modernBenefits,
    this.isBookmarked = false,
  });
}

class KnowledgeArticle {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final int readingTimeMinutes;
  final String author;
  final String excerpt;
  final String fullContent;
  final List<String> tags;
  bool isBookmarked;

  // Convenience alias for fullContent
  String get content => fullContent;
  String get name => title;

  KnowledgeArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readingTimeMinutes,
    required this.author,
    required this.excerpt,
    required this.fullContent,
    required this.tags,
    this.isBookmarked = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? suggestedTopic;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedTopic,
  });
}

class SeasonInfo {
  final SeasonType type;
  final String name;
  final String sanskritName;
  final String months;
  final String dominantElement;
  final String doshaState;
  final String dietaryAdvice;
  final String lifestyleAdvice;
  final List<String> recommendedHerbs;
  final List<String> avoidances;

  SeasonInfo({
    required this.type,
    required this.name,
    required this.sanskritName,
    required this.months,
    required this.dominantElement,
    required this.doshaState,
    required this.dietaryAdvice,
    required this.lifestyleAdvice,
    required this.recommendedHerbs,
    required this.avoidances,
  });
}
