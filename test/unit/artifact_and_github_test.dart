import 'dart:convert';
import 'package:codex_catalouge/core/theme/codex_tokens.dart';
import 'package:codex_catalouge/models/artifact.dart';
import 'package:codex_catalouge/services/github_image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Artifact 4-digit numbering & auto-flagging', () {
    test('formats 4-digit codes with leading zeroes', () {
      expect(Artifact.formatFourDigitNumber(1), '0001');
      expect(Artifact.formatFourDigitNumber(91), '0091');
      expect(Artifact.formatFourDigitNumber(417), '0417');
      expect(Artifact.formatFourDigitNumber(9999), '9999');
    });

    test('validates 4-digit artifact numbers', () {
      expect(Artifact.isValidFourDigitNumber('0612'), isTrue);
      expect(Artifact.isValidFourDigitNumber('0001'), isTrue);
      expect(Artifact.isValidFourDigitNumber('612'), isFalse);
      expect(Artifact.isValidFourDigitNumber('0000'), isFalse);
      expect(Artifact.isValidFourDigitNumber('abcd'), isFalse);
    });

    test('computes net rating and triggers flagged state at threshold', () {
      final flagged = Artifact(
        id: 'art_1',
        artifactNumber: 508,
        title: 'The Hollow Oar of Piraeus',
        anomalyClass: AnomalyClass.dangerous,
        historicalOrigin: 'Athens',
        discovererPerspective: 'Sailor',
        adventurerRecoveryNote: 'Recovered off Piraeus.',
        clairvoyanceName: 'Seer_1',
        chapterContent: 'The oar came up dripping.',
        authorId: 'u1',
        upvotes: 2,
        downvotes: 14,
        downvoteThreshold: -10,
        updatedAt: DateTime(2026),
      );
      expect(flagged.rating, -12);
      expect(flagged.signedRating, '−12');
      expect(flagged.bracketedCode, 'Artifact [0508]');
      expect(flagged.isFlagged, isTrue);
    });
  });

  group('GithubImageService', () {
    test('commits base64 image and returns persistent Raw URL', () async {
      late Uri capturedUri;
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((req) async {
        capturedUri = req.url;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{"content":{"sha":"abc"}}', 201);
      });

      final service = GithubImageService(client: mockClient);
      final url = await service.commitRelicImage(
        artifactNumber: 612,
        base64Image: base64Encode([1, 2, 3]),
        overrideConfig: const GithubConfig(
          owner: 'codex-org',
          repo: 'codex-assets',
          branch: 'main',
          pat: 'github_pat_test',
        ),
      );

      expect(
        capturedUri.toString(),
        startsWith(
          'https://api.github.com/repos/codex-org/codex-assets/contents/relics/artifact_0612_',
        ),
      );
      expect(capturedBody['message'], 'Catalogued Artifact [0612]');
      expect(
        url,
        startsWith(
          'https://raw.githubusercontent.com/codex-org/codex-assets/main/relics/artifact_0612_',
        ),
      );
    });
  });
}
