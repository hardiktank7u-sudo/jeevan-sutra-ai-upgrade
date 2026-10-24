import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/plant.dart';

/// Loads structured Jeevan Sutra content from bundled JSON assets.
class ContentRepository {
  ContentRepository._();

  static const String _plantsAsset = 'assets/knowledge/plants.json';

  static List<Plant>? _plantsCache;

  /// Loads all medicinal plants from the local JSON database.
  static Future<List<Plant>> loadPlants() async {
    if (_plantsCache != null) {
      return List.unmodifiable(_plantsCache!);
    }

    final rawJson = await rootBundle.loadString(_plantsAsset);
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'plants.json must contain a JSON object.',
      );
    }

    final rawPlants = decoded['plants'];

    if (rawPlants is! List) {
      throw const FormatException(
        'plants.json must contain a "plants" array.',
      );
    }

    final plants = <Plant>[];

    for (final item in rawPlants) {
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);

      try {
        plants.add(Plant.fromJson(map));
      } on Object catch (error) {
        throw FormatException(
          'Invalid plant record in plants.json: $error',
        );
      }
    }

    _plantsCache = plants;
    return List.unmodifiable(plants);
  }

  /// Finds a plant by its stable ID.
  static Future<Plant?> getPlantById(String id) async {
    final plants = await loadPlants();

    for (final plant in plants) {
      if (plant.id == id) {
        return plant;
      }
    }

    return null;
  }

  /// Searches plant names, scientific names, and keywords.
  static Future<List<Plant>> searchPlants(String query) async {
    final plants = await loadPlants();
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(plants);
    }

    return plants.where((plant) {
      final searchableText = [
        plant.commonName,
        plant.sanskritName ?? '',
        plant.hindiName ?? '',
        plant.scientificName,
        plant.family,
        plant.category,
        ...plant.keywords,
      ].join(' ').toLowerCase();

      return searchableText.contains(normalizedQuery);
    }).toList();
  }

  /// Clears the in-memory cache.
  ///
  /// Useful later if content is refreshed from a remote source.
  static void clearCache() {
    _plantsCache = null;
  }
}
