import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/codex_components.dart';
import '../../widgets/floating_runes_overlay.dart';
import '../landing/arcane_backdrop.dart';
import '../landing/ethereal_mist_overlay.dart';
import 'the_mark_ritual_overlay.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialSignUp = false, this.onSuccess});

  final bool initialSignUp;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final LandingAtmosphereController _atmosphere;
  late bool _isSignUp = widget.initialSignUp;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _atmosphere = LandingAtmosphereController(this)..start(() => mounted);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atmosphere.disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _atmosphere.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isSignUp = _isSignUp;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    final name = _nameCtrl.text.trim();

    if (isSignUp && name.isEmpty) {
      setState(() => _error = 'Enter your Seeker title.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (isSignUp && confirmPass != pass) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!ref.read(firebaseReadyProvider)) {
      setState(
        () => _error =
            'Firebase is not configured yet. Follow SETUP.md to link your project.',
      );
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (isSignUp) {
        await auth.signUp(email: email, password: pass, displayName: name);
        await auth.signOut();
        if (!mounted) return;
        showCodexToast(context, 'The Mark of Codex granted');
        showTheMarkRitualTransition(
          context,
          onSwitchToSignIn: () {
            if (!mounted) return;
            setState(() {
              _isSignUp = false;
              _passCtrl.clear();
              _confirmPassCtrl.clear();
              _error = null;
              _busy = false;
            });
          },
        );
      } else {
        await auth.signIn(email: email, password: pass);
        if (!mounted) return;
        showCodexToast(context, 'Welcome back, Seer');
        showSanctumAwakeningTransition(
          context,
          onEnterDashboard: () {
            if (!mounted) return;
            setState(() => _busy = false);
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AuthService.formatAuthError(e);
        _busy = false;
      });
    }
  }

  Widget _visibilityToggle({
    required bool obscured,
    required Color iconColor,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: obscured ? 'Show password' : 'Hide password',
    icon: Icon(
      obscured ? Icons.visibility_off : Icons.visibility,
      size: 18,
      color: iconColor,
    ),
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final violet = AnomalyClass.cursed.color;
    final isDark = p.mode == CodexThemeMode.dark;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ArcaneBackdrop(animation: _atmosphere.controller),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _atmosphere.controller,
              builder: (_, _) => EtherealMistOverlay(
                animation: _atmosphere.controller,
                seed: _atmosphere.cycleSeed,
              ),
            ),
          ),
          FloatingRunesOverlay(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 54).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CodexIconPillButton(
                              label: '‹ Back',
                              onTap: _busy
                                  ? () {}
                                  : () => Navigator.of(context).maybePop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthCrestHeader(
                                  sealAnimation: _atmosphere.controller,
                                  isSignUp: _isSignUp,
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: p.surface.withValues(
                                      alpha: isDark ? 0.82 : 0.90,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _isSignUp
                                          ? p.danger.withValues(alpha: 0.45)
                                          : p.border,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isSignUp ? p.danger : violet)
                                                .withValues(alpha: 0.14),
                                        blurRadius: 24,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        child: _isSignUp
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    'Seeker',
                                                    style: CodexTypography.chip(
                                                      p.textMuted,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  TextField(
                                                    controller: _nameCtrl,
                                                    enabled: !_busy,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    style: CodexTypography.body(
                                                      p.textPrimary,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          hintText:
                                                              'e.g. Seer_Manayon',
                                                        ),
                                                  ),
                                                  const SizedBox(height: 14),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      Text(
                                        'Email Address',
                                        style: CodexTypography.chip(
                                          p.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _emailCtrl,
                                        enabled: !_busy,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        style: CodexTypography.body(
                                          p.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'seeker@codex.org',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Password',
                                        style: CodexTypography.chip(
                                          p.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _passCtrl,
                                        enabled: !_busy,
                                        obscureText: _obscurePass,
                                        textInputAction: _isSignUp
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        onSubmitted: _isSignUp || _busy
                                            ? null
                                            : (_) => _submit(),
                                        style: CodexTypography.body(
                                          p.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          suffixIcon: _visibilityToggle(
                                            obscured: _obscurePass,
                                            iconColor: p.textMuted,
                                            onPressed: () => setState(
                                              () =>
                                                  _obscurePass = !_obscurePass,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isSignUp) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          'Confirm Password',
                                          style: CodexTypography.chip(
                                            p.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _confirmPassCtrl,
                                          enabled: !_busy,
                                          obscureText: _obscureConfirmPass,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: _busy
                                              ? null
                                              : (_) => _submit(),
                                          style: CodexTypography.body(
                                            p.textPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '••••••••',
                                            suffixIcon: _visibilityToggle(
                                              obscured: _obscureConfirmPass,
                                              iconColor: p.textMuted,
                                              onPressed: () => setState(
                                                () => _obscureConfirmPass =
                                                    !_obscureConfirmPass,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (_error != null) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          _error!,
                                          style: CodexTypography.metadata(
                                            p.danger,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      _AuthRitualButton(
                                        label: _busy
                                            ? (_isSignUp
                                                  ? 'Inscribing Covenant...'
                                                  : 'Awakening Sanctum...')
                                            : (_isSignUp
                                                  ? 'Sign Up & Behold ᛏᚱᚢᛏᚺ'
                                                  : 'Sign In'),
                                        sinister: _isSignUp,
                                        onTap: _busy ? null : _submit,
                                      ),
                                      const SizedBox(height: 10),
                                      CodexButton(
                                        label: _isSignUp
                                            ? 'Already initiated? Sign In'
                                            : 'No Mark yet? Sign Up',
                                        filled: false,
                                        mutedOutline: true,
                                        onTap: _busy
                                            ? null
                                            : () => setState(() {
                                                _isSignUp = !_isSignUp;
                                                _error = null;
                                              }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _atmosphere.controller,
              builder: (_, _) => EtherealMistOverlay(
                animation: _atmosphere.controller,
                seed: _atmosphere.cycleSeed,
                foreground: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCrestHeader extends StatelessWidget {
  const _AuthCrestHeader({
    required this.sealAnimation,
    required this.isSignUp,
  });

  final Animation<double> sealAnimation;
  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final violet = AnomalyClass.cursed.color;
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OverflowBox(
                minWidth: 164,
                maxWidth: 164,
                minHeight: 164,
                maxHeight: 164,
                child: ArcaneSealRing(animation: sealAnimation, size: 164),
              ),
              Image.asset(
                'assets/images/codexlogo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.auto_stories, size: 42, color: p.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            isSignUp ? 'OBTAIN THE MARK' : 'SANCTUM AUTHENTICATION',
            key: ValueKey(isSignUp),
            textAlign: TextAlign.center,
            style: CodexTypography.screenTitle(
              p.textPrimary,
            ).copyWith(fontSize: 22, letterSpacing: 2.0),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 36),
                height: 1,
                color: violet.withValues(alpha: 0.55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '✦  ᛟ  ✦',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: p.accent.withValues(alpha: 0.85),
                ),
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 36),
                height: 1,
                color: violet.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? 'Inscribe your covenant with The Inquisitor to behold the ᛏᚱᚢᛏᚺ and read recovered artifact memories.'
              : 'Enter your credentials to access Clairvoyance transcripts and your Offline Vault.',
          textAlign: TextAlign.center,
          style: CodexTypography.body(p.textMuted),
        ),
      ],
    );
  }
}

class _AuthRitualButton extends StatefulWidget {
  const _AuthRitualButton({
    required this.label,
    required this.sinister,
    required this.onTap,
  });

  final String label;
  final bool sinister;
  final VoidCallback? onTap;

  @override
  State<_AuthRitualButton> createState() => _AuthRitualButtonState();
}

class _AuthRitualButtonState extends State<_AuthRitualButton> {
  static const _crimsonBg = Color(0xFF2B080C);
  static const _crimsonBorder = Color(0xFFDC2626);
  static const _crimsonText = Color(0xFFFFE4E6);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final activeSinister = widget.sinister && _hovered;
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activeSinister ? _crimsonBg : p.accent,
            borderRadius: BorderRadius.circular(activeSinister ? 3 : 6),
            border: Border.all(
              color: activeSinister ? _crimsonBorder : p.accent,
              width: activeSinister ? 1.3 : 1.0,
            ),
            boxShadow: activeSinister
                ? [
                    BoxShadow(
                      color: _crimsonBorder.withValues(alpha: 0.48),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            style: CodexTypography.button(
              activeSinister ? _crimsonText : p.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}
