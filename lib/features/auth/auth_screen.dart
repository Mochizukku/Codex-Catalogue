import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/codex_components.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialSignUp = false, this.onSuccess});

  final bool initialSignUp;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
  void dispose() {
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
      } else {
        await auth.signIn(email: email, password: pass);
      }
      if (!mounted) return;
      showCodexToast(
        context,
        isSignUp ? 'The Mark of Codex granted' : 'Welcome back, Seer',
      );
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AuthService.formatAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
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
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CodexIconPillButton(
                    label: '‹ Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _isSignUp ? 'OBTAIN THE MARK' : 'SANCTUM AUTHENTICATION',
                style: CodexTypography.screenTitle(p.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Inscribe your covenant with The Inquisitor to behold the ᛏᚱᚢᛏᚺ and read recovered artifact memories.'
                    : 'Enter your credentials to access Clairvoyance transcripts and your Offline Vault.',
                style: CodexTypography.body(p.textMuted),
              ),
              const SizedBox(height: 20),
              if (_isSignUp) ...[
                Text(
                  'Seeker',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: CodexTypography.body(p.textPrimary),
                ),
                const SizedBox(height: 14),
              ],
              Text('Email Address', style: CodexTypography.chip(p.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: CodexTypography.body(p.textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                'Password',
                style: CodexTypography.chip(p.textMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _isSignUp || _busy ? null : (_) => _submit(),
                style: CodexTypography.body(p.textPrimary),
                decoration: InputDecoration(
                  suffixIcon: _visibilityToggle(
                    obscured: _obscurePass,
                    iconColor: p.textMuted,
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 14),
                Text(
                  'Confirm Password',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPass,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _busy ? null : (_) => _submit(),
                  style: CodexTypography.body(p.textPrimary),
                  decoration: InputDecoration(
                    suffixIcon: _visibilityToggle(
                      obscured: _obscureConfirmPass,
                      iconColor: p.textMuted,
                      onPressed: () => setState(
                        () => _obscureConfirmPass = !_obscureConfirmPass,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: CodexTypography.metadata(p.danger)),
              ],
              const SizedBox(height: 20),
              CodexButton(
                label:
                    _busy
                        ? 'Verifying Covenant...'
                        : (_isSignUp ? 'Sign Up & Behold ᛏᚱᚢᛏᚺ' : 'Sign In'),
                onTap: _busy ? null : _submit,
              ),
              const SizedBox(height: 10),
              CodexButton(
                label:
                    _isSignUp
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
      ),
    );
  }
}
