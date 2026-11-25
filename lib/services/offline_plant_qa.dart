import '../models/plant.dart';
import 'plant_feature_matcher.dart';

/// Retrieval answers grounded only in stored plant records.
class OfflinePlantAnswer {
  const OfflinePlantAnswer({required this.text, required this.fromCatalogue});

  final String text;
  final bool fromCatalogue;
}

class OfflinePlantQa {
  const OfflinePlantQa._();

  static const _genericAliases = {
    'indian',
    'plant',
    'plants',
    'tree',
    'trees',
    'herb',
    'herbs',
    'seed',
    'seeds',
    'leaf',
    'leaves',
    'root',
    'roots',
    'flower',
    'flowers',
    'wild',
    'white',
    'black',
    'red',
    'green',
    'yellow',
    'oil',
    'common',
    'small',
    'large',
    'sweet',
    'medicinal',
    'fruit',
    'fruits',
    'bark',
    'wood',
    'water',
    'blue',
    'pink',
  };

  static OfflinePlantAnswer respond(
    String question,
    List<Plant> plants, {
    List<Map<String, dynamic>> conversationHistory = const [],
    String Function(String question)? generalAnswer,
  }) {
    final catalogue = _catalogueAnswer(question, plants, conversationHistory);
    if (catalogue != null) {
      return OfflinePlantAnswer(text: catalogue, fromCatalogue: true);
    }
    if (_isPlantRelatedQuestion(question)) {
      return const OfflinePlantAnswer(
        text:
            'I could not find a matching plant record in the bundled catalogue. '
            'Try a common, Sanskrit, Hindi, or scientific name from the catalogue.',
        fromCatalogue: false,
      );
    }
    final fallback =
        generalAnswer?.call(question) ??
        'The offline catalogue has no matching plant record for that question.';
    return OfflinePlantAnswer(text: fallback, fromCatalogue: false);
  }

  static bool _isPlantRelatedQuestion(String question) => RegExp(
    r'\b(plant|plants|herb|herbs|herbal|botanical|medicinal|species|leaf|leaves|root|roots|flower|flowers|bark|seed|seeds|safety|safe|toxic|poison|dosage|dose|family|identify|identification|scientific name|traditional use|used for|parts used)\b',
  ).hasMatch(_normalize(question));

  static String? _catalogueAnswer(
    String question,
    List<Plant> plants,
    List<Map<String, dynamic>> conversationHistory,
  ) {
    final normalized = _normalize(question);
    if (normalized.isEmpty || plants.isEmpty) return null;

    final explicit = _mentioned(normalized, plants);
    final followUp = explicit.isEmpty && _looksLikeFollowUp(normalized);
    final context = followUp
        ? _contextPlant(conversationHistory, plants)
        : null;
    final focus = explicit.isNotEmpty
        ? explicit
        : context == null
        ? const <Plant>[]
        : <Plant>[context];

    if (_isDosage(normalized)) {
      if (focus.isEmpty) {
        return 'No dosage is stored in the offline plant catalogue. '
            'This assistant will not suggest a dose, frequency, or preparation amount.';
      }
      if (focus.length > 1) return _ambiguous(focus);
      return _dosageAnswer(focus.first);
    }

    if (focus.isEmpty && _isCatalogueCount(normalized)) {
      return 'The offline catalogue currently has ${plants.length} plant records. '
          'Ask about a plant name, family, identification features, recorded traditional uses, '
          'or the safety text stored for a plant. Medicinal claims and doses are not added.';
    }

    final familyName = _namedFamily(normalized, plants);
    if (focus.isEmpty && familyName != null) {
      final members = plants
          .where(
            (plant) => plant.family.toLowerCase() == familyName.toLowerCase(),
          )
          .toList();
      return _familyList(familyName, members);
    }

    if (focus.isEmpty && _isListingQuestion(normalized)) {
      final asked = _askedTraits(normalized);
      if (asked.isNotEmpty) return _traitList(plants, asked);
    }

    if (focus.isEmpty) return null;
    if (focus.length > 1 && !_isCompare(normalized)) return _ambiguous(focus);
    if (_isCompare(normalized)) {
      if (focus.length < 2) {
        return 'Name two plants to compare. This assistant only compares records that are already in the catalogue.';
      }
      return _compare(focus[0], focus[1]);
    }

    final plant = focus.first;
    if (_isSafety(normalized)) return _safetyAnswer(plant, normalized);
    if (_isFamily(normalized)) return _familyAnswer(plant);
    if (_isIdentification(normalized)) return _identificationAnswer(plant);
    if (_isTraditional(normalized)) return _traditionalAnswer(plant);
    if (_isParts(normalized)) return _partsAnswer(plant);
    if (_isName(normalized)) return _nameAnswer(plant, normalized);
    if (_isTreatmentClaim(normalized)) return _treatmentRefusal(plant);
    return _overview(plant);
  }

  static String _overview(Plant plant) {
    final out = StringBuffer()
      ..writeln('**${plant.commonName}** (${plant.scientificName})')
      ..writeln(
        'Family: ${plant.family.isEmpty ? 'Not recorded' : plant.family}.',
      );
    if ((plant.sanskritName ?? '').trim().isNotEmpty) {
      out.writeln('Sanskrit name: ${plant.sanskritName}.');
    }
    if ((plant.hindiName ?? '').trim().isNotEmpty) {
      out.writeln('Hindi name: ${plant.hindiName}.');
    }
    if (plant.identification.trim().isNotEmpty) {
      out.writeln('\n**Identification**\n${plant.identification.trim()}');
    } else {
      out.writeln('\n**Identification**\nNot recorded in this catalogue.');
    }
    if (plant.partsUsed.isNotEmpty) {
      out.writeln('\n**Parts recorded**\n${plant.partsUsed.join(', ')}.');
    }
    if (plant.traditionalUses.isNotEmpty) {
      out.writeln(
        '\n**Traditional uses (not proof of treatment)**\n${plant.traditionalUses.join('\n')}',
      );
    } else {
      out.writeln(
        '\n**Traditional uses (not proof of treatment)**\nNone are recorded for this plant.',
      );
    }
    if (plant.scientificEvidence.isNotEmpty) {
      out.writeln(
        '\n**Scientific evidence**\n${plant.scientificEvidence.join('\n')}',
      );
    }
    out.writeln('\n${_safetyBlock(plant)}');
    if (plant.precautions.isNotEmpty) {
      out.writeln(
        '\n**Precautions recorded**\n${plant.precautions.join('\n')}',
      );
    }
    out
      ..writeln('\n${_toxicityLine(plant)}')
      ..writeln(
        '\nDosage: not recorded in this catalogue. This assistant does not recommend a dose.',
      )
      ..writeln(
        '\nOffline catalogue record · ${plant.reviewStatus} · Sources: ${plant.sources.isEmpty ? 'Not listed' : plant.sources.join('; ')}.',
      )
      ..write(
        'This is educational information from stored records, not diagnosis or treatment advice. Do not consume or apply an unidentified plant.',
      );
    return out.toString();
  }

  static String _dosageAnswer(Plant plant) {
    return '**${plant.commonName}** (${plant.scientificName})\n\n'
        'No dosage is stored for this plant. This assistant will not suggest a dose, '
        'frequency, or preparation amount.\n\n'
        '${_safetyBlock(plant)}\n\n'
        'Recorded safety text is not a personal recommendation.';
  }

  static String _safetyAnswer(Plant plant, String normalized) {
    final gaps = <String>[];
    final recorded = _recordedSafetyText(plant).toLowerCase();
    if (RegExp(r'pregnan').hasMatch(normalized) &&
        !recorded.contains('pregnan')) {
      gaps.add('Pregnancy-specific safety information is not recorded.');
    }
    if (RegExp(r'\b(child|children)\b').hasMatch(normalized) &&
        !RegExp(r'\b(child|children)\b').hasMatch(recorded)) {
      gaps.add('Child-specific safety information is not recorded.');
    }
    final gapText = gaps.isEmpty ? '' : '\n\n${gaps.join(' ')}';
    return '**${plant.commonName}** (${plant.scientificName})\n\n'
        '${_safetyBlock(plant)}$gapText\n\n'
        '${_toxicityLine(plant)}\n\n'
        'No dosage is stored. This answer quotes recorded safety text only and does not add a recommendation.';
  }

  static String _familyAnswer(Plant plant) {
    final family = plant.family.trim().isEmpty
        ? 'Not recorded in this catalogue.'
        : plant.family.trim();
    return '**${plant.commonName}** is recorded in the family $family. '
        'Scientific name: ${plant.scientificName}.';
  }

  static String _identificationAnswer(Plant plant) {
    final text = plant.identification.trim().isEmpty
        ? 'Identification features are not recorded for this plant.'
        : plant.identification.trim();
    return '**Identification recorded for ${plant.commonName}** (${plant.scientificName})\n\n$text\n\n'
        'This is the stored description, not a confirmation that a photograph shows this plant.';
  }

  static String _traditionalAnswer(Plant plant) {
    if (plant.traditionalUses.isEmpty) {
      return 'No traditional uses are recorded for ${plant.commonName}. '
          'None have been added.';
    }
    return '**Traditional uses recorded for ${plant.commonName}**\n\n'
        '${plant.traditionalUses.join('\n')}\n\n'
        'These are traditional uses stored in the catalogue. They are not proof of treatment, '
        'and no dose is included.';
  }

  static String _partsAnswer(Plant plant) {
    if (plant.partsUsed.isEmpty) {
      return 'No plant parts are recorded for ${plant.commonName}.';
    }
    return 'Parts recorded for ${plant.commonName}: ${plant.partsUsed.join(', ')}.';
  }

  static String _nameAnswer(Plant plant, String normalized) {
    if (normalized.contains('scientific') || normalized.contains('botanical')) {
      return 'The scientific name recorded for ${plant.commonName} is ${plant.scientificName}.';
    }
    if (normalized.contains('hindi')) {
      final name = (plant.hindiName ?? '').trim();
      return name.isEmpty
          ? 'No Hindi name is recorded for ${plant.commonName}.'
          : 'The Hindi name recorded for ${plant.commonName} is $name.';
    }
    if (normalized.contains('sanskrit')) {
      final name = (plant.sanskritName ?? '').trim();
      return name.isEmpty
          ? 'No Sanskrit name is recorded for ${plant.commonName}.'
          : 'The Sanskrit name recorded for ${plant.commonName} is $name.';
    }
    return _overview(plant);
  }

  static String _treatmentRefusal(Plant plant) {
    final uses = plant.traditionalUses.isEmpty
        ? 'No traditional uses are recorded for this plant.'
        : 'Traditional uses recorded, which are not proof of treatment:\n${plant.traditionalUses.join('\n')}';
    return 'This assistant cannot say whether ${plant.commonName} treats, cures, or should be taken for a condition.\n\n'
        '$uses\n\n${_safetyBlock(plant)}\n\n'
        'No dosage is stored, and none is recommended here.';
  }

  static String _compare(Plant first, Plant second) {
    return '**${first.commonName}** and **${second.commonName}**\n\n'
        'This places two stored records side by side. It does not say that one treats a condition better.\n\n'
        '${_compareSide(first)}\n\n${_compareSide(second)}';
  }

  static String _compareSide(Plant plant) {
    final identification = plant.identification.trim().isEmpty
        ? 'Identification: not recorded.'
        : 'Identification: ${_shorten(plant.identification.trim(), 500)}';
    final uses = plant.traditionalUses.isEmpty
        ? 'Traditional uses: none recorded.'
        : 'Traditional uses recorded: ${_shorten(plant.traditionalUses.join(' '), 400)}';
    return '**${plant.commonName}** (${plant.scientificName})\n'
        'Family: ${plant.family.isEmpty ? 'Not recorded' : plant.family}.\n'
        '$identification\n$uses\n${_safetyBlock(plant)}';
  }

  static String _familyList(String family, List<Plant> members) {
    if (members.isEmpty) {
      return 'No plants in the loaded catalogue are recorded in the family $family.';
    }
    final lines = members
        .take(12)
        .map((plant) => '- ${plant.commonName} (${plant.scientificName})')
        .join('\n');
    final extra = members.length > 12
        ? '\n\n${members.length - 12} more records are in this family.'
        : '';
    return '**$family** — ${members.length} record${members.length == 1 ? '' : 's'} in the loaded catalogue\n\n'
        '$lines$extra\n\n'
        'Ask for one plant to see its identification, traditional uses, or recorded safety text.';
  }

  static String _traitList(List<Plant> plants, List<ObservableTrait> asked) {
    final profiles = PlantFeatureMatcher.index(plants);
    final matches = profiles.where((profile) {
      return asked.every((trait) => profile.hasTrait(trait.id));
    }).toList();
    final labels = asked.map((trait) => trait.label).join(', ');
    if (matches.isEmpty) {
      return 'No catalogue record mentions all of these features together: $labels. '
          'This was a text search of stored identification notes, not a visual identification.';
    }
    final lines = matches
        .take(10)
        .map(
          (profile) =>
              '- ${profile.plant.commonName} (${profile.plant.family.isEmpty ? 'family not recorded' : profile.plant.family})',
        )
        .join('\n');
    final extra = matches.length > 10
        ? '\n\n${matches.length - 10} more records also mention those features.'
        : '';
    return '**Records whose identification text mentions: $labels**\n\n'
        '$lines$extra\n\n'
        'This is a text search of the catalogue, not automatic image recognition.';
  }

  static String _ambiguous(List<Plant> plants) {
    final names = plants
        .take(5)
        .map((plant) => '${plant.commonName} (${plant.scientificName})')
        .join('; ');
    return 'Several catalogue records match that name: $names. '
        'Ask again with the full common name or the scientific name.';
  }

  static String _safetyBlock(Plant plant) {
    if (plant.safetySummary.trim().isNotEmpty) {
      return '**Safety information**\n${plant.safetySummary.trim()}';
    }
    return '**Safety information**\nNot recorded in this catalogue. Absence of a warning does not mean the plant is safe.';
  }

  static String _toxicityLine(Plant plant) {
    if (plant.isToxic == true ||
        (plant.toxicityWarning ?? '').trim().isNotEmpty) {
      return '**Toxicity notice**\n${plant.toxicityWarning ?? 'This record flags potential toxicity. Do not use it based on this app.'}';
    }
    if (plant.isToxic == false) {
      return '**Safety status:** This record does not flag the plant as toxic. That is not a safety approval.';
    }
    return '**Safety status:** Not established in this record; absence of a warning does not mean the plant is safe.';
  }

  static String _recordedSafetyText(Plant plant) {
    return [
      plant.safetySummary,
      ...plant.precautions,
      plant.toxicityWarning ?? '',
    ].join('\n');
  }

  static List<ObservableTrait> _askedTraits(String normalized) {
    final asked = <ObservableTrait>[];
    for (final trait in PlantFeatureMatcher.traits) {
      for (final cue in trait.questionCues) {
        if (normalized.contains(cue)) {
          asked.add(trait);
          break;
        }
      }
    }
    return asked;
  }

  static Plant? _contextPlant(
    List<Map<String, dynamic>> history,
    List<Plant> plants,
  ) {
    for (final message in history.reversed) {
      final text = _normalize((message['text'] ?? '').toString());
      if (text.isEmpty) continue;
      final mentioned = _mentioned(text, plants);
      if (mentioned.isNotEmpty) return mentioned.first;
    }
    return null;
  }

  static List<Plant> _mentioned(String normalized, List<Plant> plants) {
    final scores = <Plant, int>{};
    for (final plant in plants) {
      var best = 0;
      for (final alias in _aliases(plant)) {
        if (_containsAlias(normalized, alias) && alias.length > best) {
          best = alias.length;
        }
      }
      if (best > 0) scores[plant] = best;
    }
    if (scores.isEmpty) return const [];
    final bestScore = scores.values.reduce((a, b) => a > b ? a : b);
    final winners = scores.entries
        .where((entry) => entry.value == bestScore)
        .map((entry) => entry.key)
        .toList();
    winners.sort((a, b) => a.commonName.compareTo(b.commonName));
    return winners;
  }

  static Iterable<String> _aliases(Plant plant) sync* {
    yield plant.commonName;
    for (final part in plant.commonName.split(RegExp(r'[/|,]'))) {
      yield part;
    }
    yield plant.scientificName;
    final scientificParts = _normalize(plant.scientificName)
        .split(' ')
        .where((part) => part.length > 1)
        .toList();
    if (scientificParts.length >= 2) {
      yield '${scientificParts[0]} ${scientificParts[1]}';
    }
    if ((plant.sanskritName ?? '').trim().isNotEmpty) yield plant.sanskritName!;
    if ((plant.hindiName ?? '').trim().isNotEmpty) yield plant.hindiName!;
    for (final keyword in plant.keywords) {
      if (keyword.trim().length >= 5) yield keyword;
    }
  }

  static bool _containsAlias(String normalized, String alias) {
    final phrase = _normalize(alias);
    if (phrase.length < 4 || _genericAliases.contains(phrase)) return false;
    final ascii = RegExp(r'^[a-z0-9\s]+$').hasMatch(phrase);
    if (!ascii) return normalized.contains(phrase);
    return RegExp('\\b${RegExp.escape(phrase)}\\b').hasMatch(normalized);
  }

  static String? _namedFamily(String normalized, List<Plant> plants) {
    String? best;
    var bestLength = 0;
    for (final plant in plants) {
      final family = _normalize(plant.family);
      if (family.length < 4 || family.length <= bestLength) continue;
      if (RegExp('\\b${RegExp.escape(family)}\\b').hasMatch(normalized)) {
        best = plant.family.trim();
        bestLength = family.length;
      }
    }
    return best;
  }

  static bool _looksLikeFollowUp(String normalized) {
    return RegExp(
          r'\b(it|its|itself|this plant|that plant|the plant|this one|that one|same plant)\b',
        ).hasMatch(normalized) ||
        _isBareField(normalized);
  }

  static bool _isBareField(String normalized) {
    final words = normalized.split(' ').where((word) => word.isNotEmpty).length;
    if (words > 8) return false;
    return RegExp(
      r'\b(family|safety|safe|uses?|identif\w*|dose|dosage|precaution|toxic|scientific|hindi|sanskrit|parts?)\b',
    ).hasMatch(normalized);
  }

  static bool _isDosage(String normalized) => RegExp(
    r'\b(dosage|doses?|dose of|what dose|how much should i take|milligrams?)\b',
  ).hasMatch(normalized);

  static bool _isCatalogueCount(String normalized) => RegExp(
    r'\b(how many plants|list all plants|plant catalogue|medicinal plants|which plants do you know)\b',
  ).hasMatch(normalized);

  static bool _isListingQuestion(String normalized) =>
      RegExp(r'\b(which|list|show|plants with|plants that)\b')
          .hasMatch(normalized);

  static bool _isCompare(String normalized) =>
      RegExp(r'\b(compare|comparison|difference|versus|vs)\b')
          .hasMatch(normalized);

  static bool _isSafety(String normalized) => RegExp(
    r'\b(safe|safety|danger|side effects?|precautions?|toxic|poison|pregnan\w*|children|child)\b',
  ).hasMatch(normalized);

  static bool _isFamily(String normalized) =>
      RegExp(r'\b(family|botanical family)\b').hasMatch(normalized);

  static bool _isIdentification(String normalized) =>
      RegExp(r'\b(identif\w*|look like|looks like|features)\b')
          .hasMatch(normalized);

  static bool _isTraditional(String normalized) =>
      RegExp(r'\b(traditional uses?|used for|uses of)\b').hasMatch(normalized);

  static bool _isParts(String normalized) =>
      RegExp(r'\b(parts? used|which part)\b').hasMatch(normalized);

  static bool _isName(String normalized) =>
      RegExp(r'\b(scientific name|botanical name|hindi name|sanskrit name)\b')
          .hasMatch(normalized);

  static bool _isTreatmentClaim(String normalized) => RegExp(
    r'\b(cures?|treats?|treatments?|heals?|should i take|can i take)\b',
  ).hasMatch(normalized);

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _shorten(String value, int max) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= max) return compact;
    return '${compact.substring(0, max).trim()}… The stored record continues.';
  }
}
