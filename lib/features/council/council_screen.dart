import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../models/artifact.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_ambient_shell.dart';
import '../../widgets/codex_components.dart';

class CouncilScreen extends ConsumerStatefulWidget {
  const CouncilScreen({super.key});

  @override
  ConsumerState<CouncilScreen> createState() => _CouncilScreenState();
}

class _CouncilScreenState extends ConsumerState<CouncilScreen> {
  int _tab = 0; // 0 = Pending, 1 = Published
  String? _selectedId;
  final _numberCtrl = TextEditingController();
  bool _canon = false;
  String? _numberError;
  bool _busy = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  void _selectItem(Artifact art) {
    setState(() {
      if (_selectedId == art.id) {
        _selectedId = null;
      } else {
        _selectedId = art.id;
        _numberCtrl.text =
            art.artifactNumber != null
                ? Artifact.formatFourDigitNumber(art.artifactNumber!)
                : '';
        _canon = art.isOfficialCanon;
        _numberError = null;
      }
    });
  }

  Future<void> _approve(Artifact art) async {
    final numInput = _numberCtrl.text.trim();
    if (!Artifact.isValidFourDigitNumber(numInput)) {
      setState(() => _numberError = 'Enter a 4-digit artifact number.');
      return;
    }

    setState(() {
      _numberError = null;
      _busy = true;
    });

    try {
      final artifactNum = int.parse(numInput);
      String? rawUrl;
      if (art.stagedImageBase64 != null && art.stagedImageBase64!.isNotEmpty) {
        rawUrl = await ref.read(githubImageServiceProvider).commitRelicImage(
          artifactNumber: artifactNum,
          base64Image: art.stagedImageBase64!,
        );
      }

      await ref.read(firestoreServiceProvider).approveArtifact(
        artifact: art,
        artifactNumber: artifactNum,
        isOfficialCanon: _canon,
        committedRawUrl: rawUrl,
      );

      if (!mounted) return;
      setState(() => _selectedId = null);
      showCodexToast(context, 'Approved and published');
    } catch (e) {
      if (!mounted) return;
      setState(() => _numberError = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Artifact art) async {
    setState(() => _busy = true);
    try {
      await ref.read(firestoreServiceProvider).rejectArtifact(art.id);
      if (!mounted) return;
      setState(() => _selectedId = null);
      showCodexToast(context, 'Submission rejected');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final pending = ref.watch(pendingArtifactsProvider).valueOrNull ?? const [];
    final published =
        ref.watch(approvedArtifactsProvider).valueOrNull ?? const [];
    final items = _tab == 0 ? pending : published;

    return Scaffold(
      backgroundColor: p.background,
      body: CodexAmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CodexIconPillButton(
                          label: '‹ Sanctum',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PUPPETEER'S COUNCIL",
                                style: CodexTypography.screenTitle(
                                  p.textPrimary,
                                ).copyWith(letterSpacing: 1.4),
                              ),
                              Text(
                                'Review & canonize Clairvoyance submissions',
                                style: CodexTypography.metadata(p.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _CouncilTab(
                    label: 'Pending (${pending.length})',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 8),
                  _CouncilTab(
                    label: 'Published (${published.length})',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child:
                    items.isEmpty
                        ? Center(
                          child: Text(
                            _tab == 0
                                ? 'No pending submissions.'
                                : 'No published artifacts.',
                            style: CodexTypography.body(p.textMuted),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final art = items[i];
                            final selected = _selectedId == art.id && _tab == 0;
                            return InkWell(
                              onTap: _tab == 0 ? () => _selectItem(art) : null,
                              borderRadius: BorderRadius.circular(8),
                              child: CodexSectionCard(
                                padding: const EdgeInsets.all(13),
                                glowColor: art.anomalyClass.color,
                                borderColor: selected ? p.accent : p.border,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      art.title,
                                      style: CodexTypography.button(
                                        p.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _tab == 0
                                          ? '${art.anomalyClass.label} · ${art.historicalOrigin}'
                                          : '${art.anomalyClass.label} · ${art.historicalOrigin} · [${art.numberCode}]',
                                      style: CodexTypography.metadata(
                                        p.textMuted,
                                      ),
                                    ),
                                    if (selected) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Text',
                                                  style: CodexTypography.chip(
                                                    p.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  art.chapterContent,
                                                  maxLines: 5,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: CodexTypography.body(
                                                    p.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 100,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Staged image',
                                                  style: CodexTypography.chip(
                                                    p.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (art.stagedImageBase64 !=
                                                        null &&
                                                    art
                                                        .stagedImageBase64!
                                                        .isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child: Image.memory(
                                                      base64Decode(
                                                        art.stagedImageBase64!,
                                                      ),
                                                      height: 76,
                                                      width: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                else
                                                  const CorruptedVisionFallback(
                                                    height: 76,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Official artifact number',
                                        style: CodexTypography.chip(p.textMuted),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _numberCtrl,
                                        keyboardType: TextInputType.number,
                                        maxLength: 4,
                                        style: CodexTypography.body(
                                          p.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          hintText: 'e.g. 0612',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Canon',
                                            style: CodexTypography.body(
                                              p.textPrimary,
                                            ),
                                          ),
                                          Switch.adaptive(
                                            value: _canon,
                                            activeThumbColor: p.accent,
                                            onChanged: (v) =>
                                                setState(() => _canon = v),
                                          ),
                                        ],
                                      ),
                                      if (_numberError != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _numberError!,
                                          style: CodexTypography.metadata(
                                            p.danger,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CodexButton(
                                              label: 'Reject',
                                              filled: false,
                                              dangerOutline: true,
                                              onTap:
                                                  _busy
                                                      ? null
                                                      : () => _reject(art),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: CodexButton(
                                              label:
                                                  _busy
                                                      ? 'Committing...'
                                                      : 'Approve',
                                              onTap:
                                                  _busy
                                                      ? null
                                                      : () => _approve(art),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouncilTab extends StatelessWidget {
  const _CouncilTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? p.pillSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: CodexTypography.dossierLabel(
            active ? p.accent : p.textMuted,
            active: active,
          ),
        ),
      ),
    );
  }
}
