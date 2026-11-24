import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../models/artifact.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_ambient_shell.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';

class TranscribeScreen extends ConsumerStatefulWidget {
  const TranscribeScreen({super.key});

  @override
  ConsumerState<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends ConsumerState<TranscribeScreen> {
  ArtifactStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final submissionsAsync = ref.watch(authorSubmissionsProvider);

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CLAIRVOYANCE STUDIO',
              style: CodexTypography.screenTitle(
                p.textPrimary,
              ).copyWith(letterSpacing: 1.5),
            ),
            Text(
              'Transcribe recovered artifact memories',
              style: CodexTypography.metadata(p.textMuted),
            ),
            const Spacer(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: CodexSectionCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 36, color: p.accent),
                      const SizedBox(height: 10),
                      Text(
                        'Only initiated Scribes of The Clairvoyance may transcribe artifact memories.',
                        textAlign: TextAlign.center,
                        style: CodexTypography.body(p.textMuted),
                      ),
                      const SizedBox(height: 16),
                      CodexButton(
                        label: 'Sign Up / Sign In to Transcribe',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AuthScreen(initialSignUp: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLAIRVOYANCE STUDIO',
                      style: CodexTypography.screenTitle(
                        p.textPrimary,
                      ).copyWith(letterSpacing: 1.5),
                    ),
                    Text(
                      'Your memory transcriptions & drafts',
                      style: CodexTypography.metadata(p.textMuted),
                    ),
                  ],
                ),
              ),
              CodexIconPillButton(
                label: '＋ New',
                active: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudioWizardScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CodexChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 6),
                for (final s in ArtifactStatus.values) ...[
                  CodexChip(
                    label: s.displayLabel,
                    selected: _statusFilter == s,
                    onTap: () => setState(
                      () => _statusFilter = _statusFilter == s ? null : s,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: switch (submissionsAsync) {
              AsyncData(:final value) => Builder(
                builder: (context) {
                  final filtered = _statusFilter == null
                      ? value
                      : value
                            .where((a) => a.status == _statusFilter)
                            .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: CodexSectionCard(
                          padding: const EdgeInsets.all(22),
                          child: Text(
                            value.isEmpty
                                ? 'No transcriptions submitted yet. Tap ＋ New to open the Clairvoyance Studio.'
                                : 'No transcriptions match this status filter.',
                            textAlign: TextAlign.center,
                            style: CodexTypography.body(p.textMuted),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final canEdit =
                          item.status != ArtifactStatus.approved ||
                          item.isFlagged;
                      return CodexSectionCard(
                        padding: const EdgeInsets.all(13),
                        glowColor: item.anomalyClass.color,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: item.anomalyClass.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: CodexTypography.cardTitle(
                                      p.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.pillSurface,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.status.displayLabel,
                                    style: CodexTypography.badge(
                                      item.status == ArtifactStatus.approved
                                          ? AnomalyClass.beneficial.color
                                          : p.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.anomalyClass.label} · ${item.historicalOrigin}',
                              style: CodexTypography.metadata(p.textMuted),
                            ),
                            if (canEdit) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: CodexIconPillButton(
                                  label: 'Edit',
                                  onTap: () => Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudioWizardScreen(
                                        initialArtifact: item,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              AsyncError(:final error) => Center(
                child: Text(
                  'Error loading submissions: $error',
                  style: CodexTypography.body(p.danger),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class StudioWizardScreen extends ConsumerStatefulWidget {
  const StudioWizardScreen({super.key, this.initialArtifact});

  final Artifact? initialArtifact;

  @override
  ConsumerState<StudioWizardScreen> createState() => _StudioWizardScreenState();
}

class _StudioWizardScreenState extends ConsumerState<StudioWizardScreen> {
  int _step = 1;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _recoveryCtrl;
  late final TextEditingController _chapterCtrl;
  AnomalyClass? _anomalyClass;
  String? _era;
  String? _stagedBase64;
  String? _validationError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialArtifact;
    _titleCtrl = TextEditingController(text: init?.title ?? '');
    _recoveryCtrl = TextEditingController(
      text: init?.adventurerRecoveryNote ?? '',
    );
    _chapterCtrl = TextEditingController(text: init?.chapterContent ?? '');
    _anomalyClass = init?.anomalyClass;
    _era = init?.historicalOrigin;
    _stagedBase64 = init?.stagedImageBase64;
    if (init == null) _restoreLocalDraft();
  }

  Future<void> _restoreLocalDraft() async {
    final draft = await ref.read(vaultLocalServiceProvider).loadLocalDraft();
    if (draft == null || !mounted) return;
    setState(() {
      _titleCtrl.text = (draft['title'] as String?) ?? '';
      _recoveryCtrl.text = (draft['recovery'] as String?) ?? '';
      _chapterCtrl.text = (draft['chapter'] as String?) ?? '';
      if (draft['anomalyClass'] != null) {
        _anomalyClass = AnomalyClass.fromString(
          draft['anomalyClass'] as String?,
        );
      }
      _era = draft['era'] as String?;
      _stagedBase64 = draft['stagedBase64'] as String?;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _recoveryCtrl.dispose();
    _chapterCtrl.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_step == 1) {
      if (_titleCtrl.text.trim().isEmpty) {
        setState(() => _validationError = 'Enter an artifact title.');
        return false;
      }
      if (_anomalyClass == null) {
        setState(() => _validationError = 'Select an anomaly class.');
        return false;
      }
      if (_era == null || _era!.trim().isEmpty) {
        setState(() => _validationError = 'Choose an ancient city / era.');
        return false;
      }
    } else if (_step == 2) {
      if (_recoveryCtrl.text.trim().isEmpty) {
        setState(() => _validationError = 'Enter the Adventurer recovery log.');
        return false;
      }
    } else if (_step == 3) {
      if (_chapterCtrl.text.trim().isEmpty) {
        setState(() => _validationError = 'Write the Discoverer POV chapter.');
        return false;
      }
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _pickIllustration() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 960,
      maxHeight: 640,
      imageQuality: 72,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _stagedBase64 = base64Encode(bytes));
  }

  Future<void> _saveDraft() async {
    await ref.read(vaultLocalServiceProvider).saveLocalDraft({
      'title': _titleCtrl.text.trim(),
      'recovery': _recoveryCtrl.text.trim(),
      'chapter': _chapterCtrl.text.trim(),
      'anomalyClass': _anomalyClass?.label,
      'era': _era,
      'stagedBase64': _stagedBase64,
    });
    if (mounted) showCodexToast(context, 'Draft saved on this device');
  }

  Future<void> _submitForReview() async {
    if (!_validateCurrentStep()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final artifact = Artifact(
        id: widget.initialArtifact?.id ?? '',
        artifactNumber: widget.initialArtifact?.artifactNumber,
        title: _titleCtrl.text.trim(),
        anomalyClass: _anomalyClass ?? AnomalyClass.cursed,
        historicalOrigin: _era ?? 'Rome',
        discovererPerspective: 'First-hand Discoverer Account',
        adventurerRecoveryNote: _recoveryCtrl.text.trim(),
        clairvoyanceName: user.displayName,
        chapterContent: _chapterCtrl.text.trim(),
        imageUrls: widget.initialArtifact?.imageUrls ?? const [],
        stagedImageBase64: _stagedBase64,
        authorId: user.uid,
        status: ArtifactStatus.pending,
        visibility: ArtifactVisibility.public,
        updatedAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).saveSubmission(artifact);
      await ref.read(vaultLocalServiceProvider).clearLocalDraft();
      if (!mounted) return;
      showCodexToast(context, 'Submitted for review');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _validationError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final eras =
        ref.watch(loreConfigProvider).valueOrNull?.historicalOrigins ??
        const ['Ancient Egypt', 'Rome', 'Athens', 'Multiverse'];

    return Scaffold(
      backgroundColor: p.background,
      body: CodexAmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialArtifact != null ? 'Revise' : 'Transcribe',
                    style: CodexTypography.screenTitle(p.textPrimary),
                  ),
                  Text(
                    'Step $_step of 4',
                    style: CodexTypography.body(p.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(4, (i) {
                  final active = i < _step;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: active ? p.accent : p.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_step == 1) ...[
                Text(
                  'Artifact title',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleCtrl,
                  style: CodexTypography.body(p.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. The Silent Astrolabe',
                  ),
                ),
                const SizedBox(height: 14),
                Text('Anomaly class', style: CodexTypography.chip(p.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in AnomalyClass.values)
                      CodexChip(
                        label: c.label,
                        selected: _anomalyClass == c,
                        dotColor: c.color,
                        onTap: () => setState(() => _anomalyClass = c),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Ancient city / era',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: eras.contains(_era) ? _era : null,
                  dropdownColor: p.surface,
                  style: CodexTypography.body(p.textPrimary),
                  hint: Text(
                    'Choose…',
                    style: CodexTypography.body(p.textMuted),
                  ),
                  items: [
                    for (final e in eras)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (v) => setState(() => _era = v),
                ),
              ] else if (_step == 2) ...[
                Text(
                  'Adventurer recovery log',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _recoveryCtrl,
                  maxLines: 6,
                  style: CodexTypography.textArea(p.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Where it was found, who held it, what was lost…',
                  ),
                ),
              ] else if (_step == 3) ...[
                Text(
                  'Discoverer POV chapter',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _chapterCtrl,
                  maxLines: 10,
                  style: CodexTypography.textArea(p.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Write in the first person, as the discoverer…',
                  ),
                ),
              ] else if (_step == 4) ...[
                Text(
                  'Relic illustration',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 8),
                if (_stagedBase64 != null && _stagedBase64!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: p.accent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.memory(
                        base64Decode(_stagedBase64!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const CorruptedVisionFallback(),
                const SizedBox(height: 10),
                CodexButton(
                  label:
                      _stagedBase64 != null
                          ? 'Remove illustration'
                          : 'Attach illustration',
                  filled: false,
                  onTap: () {
                    if (_stagedBase64 != null) {
                      setState(() => _stagedBase64 = null);
                    } else {
                      _pickIllustration();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Without an illustration, readers see the redacted fallback card.',
                  style: CodexTypography.metadata(p.textMuted),
                ),
              ],
              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _validationError!,
                  style: CodexTypography.metadata(p.danger),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CodexButton(
                      label: _step == 1 ? 'Cancel' : 'Back',
                      filled: false,
                      mutedOutline: _step == 1,
                      onTap: () {
                        if (_step == 1) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _validationError = null;
                            _step -= 1;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CodexButton(
                      label:
                          _step < 4
                              ? 'Next'
                              : (_submitting
                                  ? 'Submitting...'
                                  : 'Submit for review'),
                      onTap:
                          _submitting
                              ? null
                              : () {
                                if (_step < 4) {
                                  if (_validateCurrentStep()) {
                                    setState(() => _step += 1);
                                  }
                                } else {
                                  _submitForReview();
                                }
                              },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CodexButton(
                label: 'Save draft',
                filled: false,
                mutedOutline: true,
                onTap: _saveDraft,
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
