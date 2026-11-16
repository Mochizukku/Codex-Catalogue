class LoreConfig {
  const LoreConfig({
    this.organizationName = 'Codex Catalogue',
    this.leaderTitle = 'The Puppeteer',
    this.labelFormat = 'Artifact [{NUMBER}]',
    this.downvoteThreshold = -10,
    this.anomalyClasses = const [
      'Beneficial',
      'Harmless',
      'Cursed',
      'Dangerous',
    ],
    this.historicalOrigins = const [
      'Ancient Egypt',
      'Rome',
      'Athens',
      'Multiverse',
      'Mesopotamia',
      'Modern Era',
    ],
  });

  final String organizationName;
  final String leaderTitle;
  final String labelFormat;
  final int downvoteThreshold;
  final List<String> anomalyClasses;
  final List<String> historicalOrigins;

  factory LoreConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const LoreConfig();
    return LoreConfig(
      organizationName:
          (map['organizationName'] as String?) ?? 'Codex Catalogue',
      leaderTitle: (map['leaderTitle'] as String?) ?? 'The Puppeteer',
      labelFormat: (map['labelFormat'] as String?) ?? 'Artifact [{NUMBER}]',
      downvoteThreshold: (map['downvoteThreshold'] as num?)?.toInt() ?? -10,
      anomalyClasses:
          (map['anomalyClasses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Beneficial', 'Harmless', 'Cursed', 'Dangerous'],
      historicalOrigins:
          (map['historicalOrigins'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Ancient Egypt',
            'Rome',
            'Athens',
            'Multiverse',
            'Mesopotamia',
            'Modern Era',
          ],
    );
  }
}
