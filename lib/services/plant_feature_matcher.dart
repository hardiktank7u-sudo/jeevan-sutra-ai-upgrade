import '../models/plant.dart';

/// A characteristic a person can check by looking at, or smelling, a plant.
///
/// Traits are read from each plant's written identification. They are not
/// inferred by a vision model.
class ObservableTrait {
  const ObservableTrait({
    required this.id,
    required this.group,
    required this.label,
    required this.patterns,
    required this.questionCues,
  });

  final String id;
  final String group;
  final String label;
  final List<String> patterns;
  final List<String> questionCues;
}

class PlantTraitProfile {
  const PlantTraitProfile({required this.plant, required this.traits});

  final Plant plant;
  final List<ObservableTrait> traits;

  bool hasTrait(String id) => traits.any((trait) => trait.id == id);
}

/// Overlap between traits the user selected and traits written in one record.
///
/// [similarity] is matched traits divided by selected traits. It is catalogue
/// text overlap, not a probability that the photograph shows this species.
class PlantFeatureMatch {
  const PlantFeatureMatch({
    required this.plant,
    required this.matchedTraits,
    required this.selectedCount,
  });

  final Plant plant;
  final List<ObservableTrait> matchedTraits;
  final int selectedCount;

  double get similarity =>
      selectedCount == 0 ? 0 : matchedTraits.length / selectedCount;
}

class PlantFeatureMatcher {
  const PlantFeatureMatcher._();

  static const List<ObservableTrait> traits = [
    ObservableTrait(
      id: 'herb',
      group: 'Habit',
      label: 'Herb',
      patterns: [r'\bherbs?\b', r'\bherbaceous\b'],
      questionCues: ['herb', 'herbs', 'herbaceous'],
    ),
    ObservableTrait(
      id: 'shrub',
      group: 'Habit',
      label: 'Shrub',
      patterns: [r'\bshrubs?\b'],
      questionCues: ['shrub', 'shrubs'],
    ),
    ObservableTrait(
      id: 'tree',
      group: 'Habit',
      label: 'Tree',
      patterns: [r'\btrees?\b'],
      questionCues: ['tree', 'trees'],
    ),
    ObservableTrait(
      id: 'climber',
      group: 'Habit',
      label: 'Climber or vine',
      patterns: [r'\bclimbers?\b', r'\bclimbing\b', r'\bvines?\b', r'\btwiners?\b'],
      questionCues: ['climber', 'vine', 'climbing'],
    ),
    ObservableTrait(
      id: 'divided_leaves',
      group: 'Leaves',
      label: 'Divided or compound leaves',
      patterns: [
        r'\bfinely divided\b',
        r'\bdeeply divided\b',
        r'\bpinnate\b',
        r'\bcompound leaves\b',
      ],
      questionCues: ['divided leaves', 'compound leaves', 'pinnate'],
    ),
    ObservableTrait(
      id: 'ovate_leaves',
      group: 'Leaves',
      label: 'Ovate leaves',
      patterns: [r'\bovate\b'],
      questionCues: ['ovate'],
    ),
    ObservableTrait(
      id: 'opposite_leaves',
      group: 'Leaves',
      label: 'Opposite leaves',
      patterns: [r'\bopposite leaves\b', r'\bleaves are opposite\b'],
      questionCues: ['opposite leaves'],
    ),
    ObservableTrait(
      id: 'hairy',
      group: 'Leaves',
      label: 'Hairy stems or leaves',
      patterns: [r'\bhairy\b', r'\bpubescent\b', r'\btomentose\b', r'\bvillous\b'],
      questionCues: ['hairy', 'pubescent'],
    ),
    ObservableTrait(
      id: 'white_flowers',
      group: 'Flowers',
      label: 'White flowers',
      patterns: [
        r'\bwhite(?:\s+\w+){0,3}\s+flowers?\b',
        r'\bflowers?\b[^.!\n]{0,40}\bwhite\b',
      ],
      questionCues: ['white flower', 'white flowers'],
    ),
    ObservableTrait(
      id: 'yellow_flowers',
      group: 'Flowers',
      label: 'Yellow flowers',
      patterns: [
        r'\byellow(?:\s+\w+){0,3}\s+flowers?\b',
        r'\bflowers?\b[^.!\n]{0,40}\byellow\b',
      ],
      questionCues: ['yellow flower', 'yellow flowers'],
    ),
    ObservableTrait(
      id: 'pink_purple_flowers',
      group: 'Flowers',
      label: 'Pink, purple, or blue flowers',
      patterns: [
        r'\b(?:pink|purple|violet|blue|purplish|bluish)(?:\s+\w+){0,3}\s+flowers?\b',
        r'\bflowers?\b[^.!\n]{0,40}\b(?:pink|purple|violet|blue)\b',
      ],
      questionCues: [
        'pink flower',
        'purple flower',
        'blue flower',
        'violet flower',
      ],
    ),
    ObservableTrait(
      id: 'red_flowers',
      group: 'Flowers',
      label: 'Red flowers',
      patterns: [
        r'\b(?:red|scarlet|crimson)(?:\s+\w+){0,3}\s+flowers?\b',
        r'\bflowers?\b[^.!\n]{0,40}\b(?:red|scarlet|crimson)\b',
      ],
      questionCues: ['red flower', 'red flowers', 'scarlet flower'],
    ),
    ObservableTrait(
      id: 'clustered_flowers',
      group: 'Flowers',
      label: 'Clustered flowers or umbels',
      patterns: [
        r'\bclusters?\b',
        r'\bumbels?\b',
        r'\bumbrella-shaped\b',
        r'\bracemes?\b',
        r'\bspikes?\b',
        r'\bpanicles?\b',
      ],
      questionCues: ['clusters', 'umbel', 'spike', 'raceme'],
    ),
    ObservableTrait(
      id: 'fleshy_fruit',
      group: 'Fruit',
      label: 'Berry or fleshy fruit',
      patterns: [r'\bberries\b', r'\bberry\b', r'\bdrupes?\b', r'\bfleshy fruits?\b'],
      questionCues: ['berry', 'berries', 'drupe', 'fleshy fruit'],
    ),
    ObservableTrait(
      id: 'pods',
      group: 'Fruit',
      label: 'Pods or legumes',
      patterns: [r'\bpods?\b', r'\blegumes?\b'],
      questionCues: ['pod', 'pods', 'legume'],
    ),
    ObservableTrait(
      id: 'aromatic',
      group: 'Scent',
      label: 'Noticeable aroma',
      patterns: [r'\baromatic\b', r'\bfragrant\b', r'\bcharacteristic aroma\b'],
      questionCues: ['aromatic', 'fragrant', 'aroma', 'smell'],
    ),
  ];

  static List<PlantTraitProfile> index(List<Plant> plants) {
    return [for (final plant in plants) profileFor(plant)];
  }

  static PlantTraitProfile profileFor(Plant plant) {
    final text = '${plant.identification}\n${plant.growingInformation ?? ''}';
    final found = <ObservableTrait>[
      for (final trait in traits)
        if (_matches(trait, text)) trait,
    ];
    return PlantTraitProfile(plant: plant, traits: found);
  }

  static List<PlantFeatureMatch> rank({
    required List<PlantTraitProfile> profiles,
    required Set<String> selectedTraitIds,
  }) {
    if (selectedTraitIds.isEmpty) return const [];
    final matches = <PlantFeatureMatch>[];
    for (final profile in profiles) {
      final matched = [
        for (final trait in profile.traits)
          if (selectedTraitIds.contains(trait.id)) trait,
      ];
      if (matched.isEmpty) continue;
      matches.add(
        PlantFeatureMatch(
          plant: profile.plant,
          matchedTraits: matched,
          selectedCount: selectedTraitIds.length,
        ),
      );
    }
    matches.sort((a, b) {
      final byScore = b.similarity.compareTo(a.similarity);
      if (byScore != 0) return byScore;
      final byCount = b.matchedTraits.length.compareTo(a.matchedTraits.length);
      if (byCount != 0) return byCount;
      return a.plant.commonName.compareTo(b.plant.commonName);
    });
    return matches;
  }

  static bool _matches(ObservableTrait trait, String text) {
    for (final pattern in trait.patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) return true;
    }
    return false;
  }
}
