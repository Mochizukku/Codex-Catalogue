import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_components.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialSignUp = false, this.onSuccess});

  final bool initialSignUp;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignUp = widget.initialSignUp;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final name = _nameCtrl.text.trim();

    if (_isSignUp && name.isEmpty) {
      setState(() => _error = 'Enter your Seeker / Scribe title.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(email: email, password: pass, displayName: name);
      } else {
        await auth.signIn(email: email, password: pass);
      }
      if (!mounted) return;
      showCodexToast(
        context,
        _isSignUp ? 'The Mark of Codex granted' : 'Welcome back, Seer',
      );
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                  'Seeker / Scribe Name',
                  style: CodexTypography.chip(p.textMuted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  style: CodexTypography.body(p.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Seer_Manayon',
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text('Email Address', style: CodexTypography.chip(p.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: CodexTypography.body(p.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'seeker@codex.org',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Secret Cipher (Password)',
                style: CodexTypography.chip(p.textMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: CodexTypography.body(p.textPrimary),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
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
                onTap: () => setState(() {
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
