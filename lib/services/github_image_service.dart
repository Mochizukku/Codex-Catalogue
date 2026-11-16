import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/artifact.dart';

class GithubConfig {
  const GithubConfig({
    required this.owner,
    required this.repo,
    this.branch = 'main',
    required this.pat,
  });

  final String owner;
  final String repo;
  final String branch;
  final String pat;

  bool get isConfigured =>
      owner.trim().isNotEmpty &&
      repo.trim().isNotEmpty &&
      pat.trim().isNotEmpty;
}

class GithubImageService {
  GithubImageService({
    http.Client? client,
    FlutterSecureStorage? storage,
    this.firestore,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final FirebaseFirestore? firestore;

  static const _kOwner = 'gh_owner';
  static const _kRepo = 'gh_repo';
  static const _kBranch = 'gh_branch';
  static const _kPat = 'gh_pat';

  Future<void> saveLocalConfig(GithubConfig config) async {
    await _storage.write(key: _kOwner, value: config.owner.trim());
    await _storage.write(key: _kRepo, value: config.repo.trim());
    await _storage.write(key: _kBranch, value: config.branch.trim());
    await _storage.write(key: _kPat, value: config.pat.trim());
  }

  Future<GithubConfig> loadConfig() async {
    final owner = await _storage.read(key: _kOwner) ?? '';
    final repo = await _storage.read(key: _kRepo) ?? '';
    final branch = await _storage.read(key: _kBranch) ?? 'main';
    final pat = await _storage.read(key: _kPat) ?? '';
    final local = GithubConfig(
      owner: owner,
      repo: repo,
      branch: branch.isEmpty ? 'main' : branch,
      pat: pat,
    );
    if (local.isConfigured || firestore == null) return local;

    try {
      final snap =
          await firestore!.collection('admin_secrets').doc('github').get();
      final data = snap.data();
      if (data != null) {
        return GithubConfig(
          owner: (data['owner'] as String?) ?? '',
          repo: (data['repo'] as String?) ?? '',
          branch: (data['branch'] as String?) ?? 'main',
          pat: (data['pat'] as String?) ?? '',
        );
      }
    } catch (_) {
      // Fallback to local config if Firestore admin_secrets is not set up
    }
    return local;
  }

  Future<String> commitRelicImage({
    required int artifactNumber,
    required String base64Image,
    GithubConfig? overrideConfig,
  }) async {
    final cfg = overrideConfig ?? await loadConfig();
    if (!cfg.isConfigured) {
      throw StateError(
        'GitHub repository & fine-grained PAT are not configured. Set them in Sanctum or admin_secrets/github.',
      );
    }

    final cleanBase64 =
        base64Image.contains(',')
            ? base64Image.split(',').last.trim()
            : base64Image.trim();
    final fourDigit = Artifact.formatFourDigitNumber(artifactNumber);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'relics/artifact_${fourDigit}_$timestamp.jpg';
    final uri = Uri.parse(
      'https://api.github.com/repos/${cfg.owner.trim()}/${cfg.repo.trim()}/contents/$path',
    );

    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer ${cfg.pat.trim()}',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      body: jsonEncode({
        'message': 'Catalogued Artifact [$fourDigit]',
        'content': cleanBase64,
        'branch': cfg.branch.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'GitHub commit failed (${response.statusCode}): ${response.body}',
      );
    }

    return 'https://raw.githubusercontent.com/${cfg.owner.trim()}/${cfg.repo.trim()}/${cfg.branch.trim()}/$path';
  }
}
