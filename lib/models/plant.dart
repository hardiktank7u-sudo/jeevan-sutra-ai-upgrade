/// Structured medicinal-plant model for Jeevan Sutra.
///
/// Traditional knowledge, scientific evidence, and safety information are
/// deliberately stored separately so the app can clearly distinguish them.
class Plant {
  final String id;
  final String commonName;
  final String? sanskritName;
  final String? hindiName;
  final String scientificName;
  final String family;
  final String category;
  final String? imageAsset;
  final String identification;
  final List<String> partsUsed;
  final List<String> traditionalReferences;
  final List<String> traditionalUses;
  final List<String> scientificEvidence;
  final List<String> knownCompounds;
  final String evidenceLevel;
  final List<String> evidenceLimitations;
  final String safetySummary;
  final List<String> precautions;
  final List<String> lookAlikes;
  final bool isToxic;
  final String? toxicityWarning;
  final List<String> sources;
  final List<PlantReference> sourceDetails;
  final String reviewStatus;
  final String? reviewedBy;
  final String? reviewDate;
  final String contentVersion;
  final List<String> keywords;

  String get botanicalName => scientificName;
  String? get taste => traditionalReferences.isNotEmpty ? traditionalReferences.first : null;
  String? get potency => knownCompounds.isNotEmpty ? knownCompounds.first : null;
  String? get postDigestiveEffect => evidenceLevel;
  String? get doshaImpact => keywords.isNotEmpty ? keywords.first : null;
  String? get primaryUses => traditionalUses.isNotEmpty ? traditionalUses.join(', ') : null;
  String? get contraindications => precautions.isNotEmpty ? precautions.join(', ') : null;
  String? get botanicalFamily => family;

  const Plant({
    required this.id,
    required this.commonName,
    this.sanskritName,
    this.hindiName,
    required this.scientificName,
    this.family = '',
    this.category = 'General',
    this.imageAsset,
    this.identification = '',
    this.partsUsed = const [],
    this.traditionalReferences = const [],
    this.traditionalUses = const [],
    this.scientificEvidence = const [],
    this.knownCompounds = const [],
    this.evidenceLevel = 'not_assessed',
    this.evidenceLimitations = const [],
    this.safetySummary = '',
    this.precautions = const [],
    this.lookAlikes = const [],
    this.isToxic = false,
    this.toxicityWarning,
    this.sources = const [],
    this.sourceDetails = const [],
    this.reviewStatus = 'draft',
    this.reviewedBy,
    this.reviewDate,
    this.contentVersion = '1.0',
    this.keywords = const [],
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      commonName: json['commonName'] as String,
      sanskritName: json['sanskritName'] as String?,
      hindiName: json['hindiName'] as String?,
      scientificName: json['scientificName'] as String,
      family: json['family'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      imageAsset: json['imageAsset'] as String?,
      identification: json['identification'] as String? ?? '',
      partsUsed: _stringList(json['partsUsed']),
      traditionalReferences: _stringList(json['traditionalReferences']),
      traditionalUses: _stringList(json['traditionalUses']),
      scientificEvidence: _stringList(json['scientificEvidence']),
      knownCompounds: _stringList(json['knownCompounds']),
      evidenceLevel: json['evidenceLevel'] as String? ?? 'not_assessed',
      evidenceLimitations: _stringList(json['evidenceLimitations']),
      safetySummary: json['safetySummary'] as String? ?? '',
      precautions: _stringList(json['precautions']),
      lookAlikes: _stringList(json['lookAlikes']),
      isToxic: json['isToxic'] as bool? ?? false,
      toxicityWarning: json['toxicityWarning'] as String?,
      sources: _stringList(json['sources']),
      sourceDetails: (json['sourceDetails'] as List?)
              ?.whereType<Map>()
              .map(
                (item) => PlantReference.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          const [],
      reviewStatus: json['reviewStatus'] as String? ?? 'draft',
      reviewedBy: json['reviewedBy'] as String?,
      reviewDate: json['reviewDate'] as String?,
      contentVersion: json['contentVersion'] as String? ?? '1.0',
      keywords: _stringList(json['keywords']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'commonName': commonName,
        'sanskritName': sanskritName,
        'hindiName': hindiName,
        'scientificName': scientificName,
        'family': family,
        'category': category,
        'imageAsset': imageAsset,
        'identification': identification,
        'partsUsed': partsUsed,
        'traditionalReferences': traditionalReferences,
        'traditionalUses': traditionalUses,
        'scientificEvidence': scientificEvidence,
        'knownCompounds': knownCompounds,
        'evidenceLevel': evidenceLevel,
        'evidenceLimitations': evidenceLimitations,
        'safetySummary': safetySummary,
        'precautions': precautions,
        'lookAlikes': lookAlikes,
        'isToxic': isToxic,
        'toxicityWarning': toxicityWarning,
        'sources': sources,
        'sourceDetails':
            sourceDetails.map((source) => source.toJson()).toList(),
        'reviewStatus': reviewStatus,
        'reviewedBy': reviewedBy,
        'reviewDate': reviewDate,
        'contentVersion': contentVersion,
        'keywords': keywords,
      };

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }
}

/// A structured reference attached to a plant record.
class PlantReference {
  final String id;
  final String title;
  final String? authors;
  final String? organization;
  final int? year;
  final String sourceType;
  final String supports;
  final String? doi;
  final String? url;

  const PlantReference({
    required this.id,
    required this.title,
    this.authors,
    this.organization,
    this.year,
    this.sourceType = 'other',
    this.supports = '',
    this.doi,
    this.url,
  });

  factory PlantReference.fromJson(Map<String, dynamic> json) {
    return PlantReference(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: json['authors'] as String?,
      organization: json['organization'] as String?,
      year: json['year'] is int ? json['year'] as int : null,
      sourceType: json['sourceType'] as String? ?? 'other',
      supports: json['supports'] as String? ?? '',
      doi: json['doi'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        'organization': organization,
        'year': year,
        'sourceType': sourceType,
        'supports': supports,
        'doi': doi,
        'url': url,
      };
}
