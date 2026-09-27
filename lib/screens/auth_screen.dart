import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/glow_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pulse_glow.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final service = context.read<SupabaseService>();
    try {
      if (_isLogin) {
        await service.signIn(_email.text.trim(), _password.text);
      } else {
        final res = await service.signUp(
          _email.text.trim(),
          _password.text,
          name: _name.text.trim(),
        );
        // With email confirmation on, there's no session until they confirm.
        if (res.session == null && mounted) {
          setState(() {
            _isLogin = true;
            _info = 'Account created. Confirm your email, then log in.';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -90, left: -70, child: _Blob(AppColors.primary)),
          const Positioned(bottom: -110, right: -80, child: _Blob(AppColors.secondary)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    PulseGlow(
                      color: AppColors.primary,
                      borderRadius: 28,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 38),
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(.7, .7),
                          curve: Curves.easeOutBack,
                          duration: 700.ms,
                        ),
                    const SizedBox(height: 22),
                    const Text(
                      'MyAllowance',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.8),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Know what you can spend today.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 30),
                    GlowCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Log in' : 'Create your account',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 18),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: _isLogin
                                  ? const SizedBox(width: double.infinity)
                                  : Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: _name,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: const InputDecoration(
                                          hintText: 'Your name',
                                          prefixIcon: Icon(Icons.person_rounded),
                                        ),
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Enter your name'
                                            : null,
                                      ),
                                    ),
                            ),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                prefixIcon: Icon(Icons.mail_rounded),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Use at least 6 characters'
                                  : null,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            ],
                            if (_info != null) ...[
                              const SizedBox(height: 14),
                              Text(_info!, style: const TextStyle(color: AppColors.secondary)),
                            ],
                            const SizedBox(height: 22),
                            GradientButton(
                              label: _isLogin ? 'Log in' : 'Sign up',
                              loading: _loading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: .08, end: 0),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                        _info = null;
                      }),
                      child: Text(
                        _isLogin
                            ? "New here? Create an account"
                            : 'Already have an account? Log in',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(.32), color.withOpacity(0)]),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .move(
          begin: Offset.zero,
          end: const Offset(24, 30),
          duration: 6.seconds,
          curve: Curves.easeInOut,
        );
  }
}
