import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../models/plant.dart';

/// Loads plant knowledge from Firestore when available and falls back to the
/// bundled catalogue. Firestore's native persistent cache supports previously
/// downloaded documents while offline; the bundled JSON is the first-run
/// fallback when no Firestore cache exists yet.
class ContentRepository {
  ContentRepository._();

  static const String _plantsAsset = 'assets/knowledge/plants.json';
  static const String _plantsCollection = 'plants';

  static List<Plant>? _plantsCache;
  static bool _lastLoadUsedCloud = false;

  /// True when the most recent successful load came from Firestore (including
  /// Firestore's local persistent cache).
  static bool get lastLoadUsedCloud => _lastLoadUsedCloud;

  /// Loads plants. Set [refresh] to bypass the in-memory cache and check
  /// Firestore again. If Firestore is unavailable or empty, bundled JSON is
  /// used. Existing callers need no changes.
  static Future<List<Plant>> loadPlants({bool refresh = false}) async {
    if (!refresh && _plantsCache != null) {
      return List.unmodifiable(_plantsCache!);
    }

    final cloudPlants = await _tryLoadFirestorePlants();
    if (cloudPlants != null && cloudPlants.isNotEmpty) {
      _plantsCache = cloudPlants;
      _lastLoadUsedCloud = true;
      return List.unmodifiable(cloudPlants);
    }

    final bundledPlants = await _loadBundledPlants();
    _plantsCache = bundledPlants;
    _lastLoadUsedCloud = false;
    return List.unmodifiable(bundledPlants);
  }

  /// Forces a Firestore refresh. Returns true if a non-empty cloud/cache
  /// catalogue was read; otherwise leaves the bundled catalogue in place.
  static Future<bool> refreshFromCloud() async {
    final cloudPlants = await _tryLoadFirestorePlants();
    if (cloudPlants == null || cloudPlants.isEmpty) return false;
    _plantsCache = cloudPlants;
    _lastLoadUsedCloud = true;
    return true;
  }

  static Future<List<Plant>?> _tryLoadFirestorePlants() async {
    // Tests and early startup can call the repository before Firebase init.
    final cloud = await _readFirestoreCatalogue();
    if (!cloud.succeeded || cloud.plants.isEmpty) return null;
    return cloud.plants;
  }

  static Future<List<Plant>> _loadBundledPlants() async {
    if (_plantsCache != null && _plantsCache!.isNotEmpty) {
      return _plantsCache!;
    }
    final rawJson = await rootBundle.loadString(_plantsAsset);
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('plants.json must contain a JSON object.');
    }

    final rawPlants = decoded['plants'];
    if (rawPlants is! List) {
      throw const FormatException('plants.json must contain a "plants" array.');
    }

    final plants = <Plant>[];
    for (final item in rawPlants) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      try {
        plants.add(Plant.fromJson(map));
      } on Object catch (error) {
        throw FormatException('Invalid plant record in plants.json: $error');
      }
    }
    _plantsCache = plants;
    return plants;
  }

  /// Loads only the bundled plant records, without contacting Firestore.
  ///
  /// Use this for features that must remain immediately available offline.
  static Future<List<Plant>> loadBundledPlants() => _loadBundledPlants();

  /// Finds a plant by its stable ID.
  static Future<Plant?> getPlantById(String id) async {
    final plants = await loadPlants();
    for (final plant in plants) {
      if (plant.id == id) return plant;
    }
    return null;
  }

  /// Searches plant names, scientific names, and keywords.
  static Future<List<Plant>> searchPlants(String query) async {
    final plants = await loadPlants();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return List.unmodifiable(plants);

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

  /// Clears the in-memory cache so the next load checks Firestore again.
  static void clearCache() {
    _plantsCache = null;
    _lastLoadUsedCloud = false;
  }

  /// Union of the bundled catalogue and the Firestore `plants` collection.
  ///
  /// Bundled records stay present when Firestore is offline, empty, or only a
  /// subset. A Firestore document with the same id replaces the bundled copy.
  static Future<PlantCatalogueLoad> loadComparisonCatalogue() async {
    final bundled = await _loadBundledPlants();
    final cloud = await _readFirestoreCatalogue();
    return PlantCatalogueLoad(
      plants: mergePlantCatalogues(bundled, cloud.plants),
      bundledCount: bundled.length,
      firestoreCount: cloud.plants.length,
      firestoreReadSucceeded: cloud.succeeded,
    );
  }

  static List<Plant> mergePlantCatalogues(
    List<Plant> bundled,
    List<Plant> firestore,
  ) {
    final byId = <String, Plant>{};
    final order = <String>[];
    for (final plant in bundled) {
      if (byId.containsKey(plant.id)) continue;
      byId[plant.id] = plant;
      order.add(plant.id);
    }
    for (final plant in firestore) {
      if (!byId.containsKey(plant.id)) order.add(plant.id);
      byId[plant.id] = plant;
    }
    return [for (final id in order) byId[id]!];
  }

  static Future<({List<Plant> plants, bool succeeded})>
  _readFirestoreCatalogue() async {
    if (Firebase.apps.isEmpty) {
      return (plants: const <Plant>[], succeeded: false);
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_plantsCollection)
          .get();
      final plants = <Plant>[];
      for (final document in snapshot.docs) {
        final data = Map<String, dynamic>.from(document.data());
        data['id'] ??= document.id;
        plants.add(Plant.fromJson(data));
      }
      return (plants: plants, succeeded: true);
    } on Object {
      return (plants: const <Plant>[], succeeded: false);
    }
  }
}

/// Result of reading both the bundled file and Firestore.
class PlantCatalogueLoad {
  const PlantCatalogueLoad({
    required this.plants,
    required this.bundledCount,
    required this.firestoreCount,
    required this.firestoreReadSucceeded,
  });

  final List<Plant> plants;
  final int bundledCount;
  final int firestoreCount;
  final bool firestoreReadSucceeded;

  String get comparisonNote {
    if (firestoreReadSucceeded) {
      return 'Compared ${plants.length} records: $bundledCount from the bundled catalogue and $firestoreCount from the Firestore plants collection. Matching ids were kept once.';
    }
    return 'Firestore was not available. Compared $bundledCount records from the bundled catalogue only.';
  }
}
