import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// Login screen wired to real Firebase Auth via [AuthService].
///
/// Routing is handled by the [StreamBuilder] in `main.dart` (AppRoot) which
/// listens to `authStateChanges`, so a successful sign-in here automatically
/// swaps this screen for the main app — no callback needed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _obscure = true;
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Runs an auth action, showing a spinner and surfacing errors as SnackBars.
  /// On success the auth-state stream in AppRoot handles navigation.
  Future<void> _run(Future<Object?> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
      // No manual navigation — StreamBuilder in AppRoot reacts to the change.
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitEmailForm() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    await _run(() {
      if (_isSignUp) {
        return AuthService.instance.signUpWithEmail(
          email,
          password,
          displayName: name.isEmpty ? null : name,
        );
      }
      return AuthService.instance.signInWithEmail(email, password);
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter your email above first, then tap "Forgot password".');
      return;
    }
    await _run(() async {
      await AuthService.instance.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email.')),
        );
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/icon/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text('✨', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('STYLEDROP',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI-powered personal stylist',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(flex: 2),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(color: AppColors.ink),
                    )
                  else if (!_showEmailForm)
                    ..._buildProviderButtons()
                  else
                    ..._buildEmailForm(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 16),
                    child: Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProviderButtons() {
    return [
      _AuthButton(
        icon: Icons.g_mobiledata_rounded,
        label: 'Continue with Google',
        onTap: () => _run(AuthService.instance.signInWithGoogle),
      ),
      const SizedBox(height: 12),
      _AuthButton(
        icon: Icons.apple_rounded,
        label: 'Continue with Apple',
        onTap: () => _run(AuthService.instance.signInWithApple),
      ),
      const SizedBox(height: 12),
      _AuthButton(
        icon: Icons.email_outlined,
        label: 'Continue with Email',
        onTap: () => setState(() => _showEmailForm = true),
      ),
      const SizedBox(height: 20),
      Row(
        children: const [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 20),
      TextButton(
        onPressed: () => _run(AuthService.instance.signInAsGuest),
        child: const Text('Continue as Guest'),
      ),
    ];
  }

  List<Widget> _buildEmailForm() {
    return [
      Text(
        _isSignUp ? 'Create your account' : 'Welcome back',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      if (_isSignUp) ...[
        TextField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: 'Email address'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordCtrl,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _submitEmailForm(),
        decoration: InputDecoration(
          hintText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      if (!_isSignUp)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitEmailForm,
          child: Text(_isSignUp ? 'SIGN UP' : 'SIGN IN'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() => _isSignUp = !_isSignUp),
        child: Text(_isSignUp
            ? 'Already have an account? Sign in'
            : "Don't have an account? Sign up"),
      ),
      TextButton(
        onPressed: () => setState(() {
          _showEmailForm = false;
          _isSignUp = false;
        }),
        child: const Text('Back'),
      ),
    ];
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(label),
        ),
      ),
    );
  }
}
