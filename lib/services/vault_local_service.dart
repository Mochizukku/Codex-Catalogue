import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artifact.dart';

class VaultEntry {
  const VaultEntry({
    required this.artifact,
    required this.isBookmarked,
    required this.isOfflineSaved,
    this.localImagePath,
  });

  final Artifact artifact;
  final bool isBookmarked;
  final bool isOfflineSaved;
  final String? localImagePath;

  VaultEntry copyWith({
    Artifact? artifact,
    bool? isBookmarked,
    bool? isOfflineSaved,
    String? localImagePath,
    bool clearLocalImage = false,
  }) => VaultEntry(
    artifact: artifact ?? this.artifact,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    isOfflineSaved: isOfflineSaved ?? this.isOfflineSaved,
    localImagePath:
        clearLocalImage ? null : (localImagePath ?? this.localImagePath),
  );

  Map<String, dynamic> toJson() => {
    'artifact': artifact.toJson(),
    'isBookmarked': isBookmarked,
    'isOfflineSaved': isOfflineSaved,
    'localImagePath': localImagePath,
  };

  factory VaultEntry.fromJson(Map<String, dynamic> map) {
    final artMap = Map<String, dynamic>.from(map['artifact'] as Map);
    return VaultEntry(
      artifact: Artifact.fromMap((artMap['id'] as String?) ?? '', artMap),
      isBookmarked: (map['isBookmarked'] as bool?) ?? false,
      isOfflineSaved: (map['isOfflineSaved'] as bool?) ?? false,
      localImagePath: map['localImagePath'] as String?,
    );
  }
}

class VaultLocalService {
  VaultLocalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _kVaultEntries = 'codex_vault_entries_v1';
  static const _kLocalDraft = 'codex_local_studio_draft_v1';

  Future<Map<String, VaultEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVaultEntries);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, VaultEntry>{};
    for (final entry in decoded.entries) {
      result[entry.key] = VaultEntry.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return result;
  }

  Future<void> _saveEntries(Map<String, VaultEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = <String, dynamic>{};
    for (final e in entries.entries) {
      if (e.value.isBookmarked || e.value.isOfflineSaved) {
        filtered[e.key] = e.value.toJson();
      }
    }
    await prefs.setString(_kVaultEntries, jsonEncode(filtered));
  }

  Future<Map<String, VaultEntry>> setBookmark(
    Artifact artifact,
    bool bookmarked,
  ) async {
    final entries = await loadEntries();
    final existing = entries[artifact.id];
    if (existing == null && !bookmarked) return entries;
    final next =
        existing?.copyWith(artifact: artifact, isBookmarked: bookmarked) ??
        VaultEntry(
          artifact: artifact,
          isBookmarked: bookmarked,
          isOfflineSaved: false,
        );
    if (!next.isBookmarked && !next.isOfflineSaved) {
      entries.remove(artifact.id);
    } else {
      entries[artifact.id] = next;
    }
    await _saveEntries(entries);
    return entries;
  }

  Future<Map<String, VaultEntry>> setOfflineSaved(
    Artifact artifact,
    bool offlineSaved,
  ) async {
    final entries = await loadEntries();
    final existing = entries[artifact.id];
    String? localImage = existing?.localImagePath;

    if (offlineSaved && artifact.primaryImageUrl != null) {
      try {
        final resp = await _client
            .get(Uri.parse(artifact.primaryImageUrl!))
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/relic_${artifact.id}.jpg');
          await file.writeAsBytes(resp.bodyBytes);
          localImage = file.path;
        }
      } catch (_) {
        // Text transcript still caches offline even if image URL is unreachable
      }
    } else if (!offlineSaved && localImage != null) {
      try {
        final file = File(localImage);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      localImage = null;
    }

    final next =
        existing?.copyWith(
          artifact: artifact,
          isOfflineSaved: offlineSaved,
          localImagePath: localImage,
          clearLocalImage: !offlineSaved,
        ) ??
        VaultEntry(
          artifact: artifact,
          isBookmarked: false,
          isOfflineSaved: offlineSaved,
          localImagePath: localImage,
        );

    if (!next.isBookmarked && !next.isOfflineSaved) {
      entries.remove(artifact.id);
    } else {
      entries[artifact.id] = next;
    }
    await _saveEntries(entries);
    return entries;
  }

  Future<void> saveLocalDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalDraft, jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> loadLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalDraft);
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> clearLocalDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalDraft);
  }
}
