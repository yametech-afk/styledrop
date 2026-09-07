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

  Future<void> _run(Future<Object?> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildHero(),
                  const Spacer(flex: 2),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                        color: AppColors.ink,
                        strokeWidth: 2,
                      ),
                    )
                  else if (!_showEmailForm)
                    ..._buildProviderButtons()
                  else
                    ..._buildEmailForm(),
                  const Spacer(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        // Logo
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/icon/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.style_outlined,
              size: 40,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // App name
        Text(
          'StyleDrop',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 6),
        // Tagline
        Text(
          'Your AI Wardrobe Stylist',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 28),
        // Divider
        Row(
          children: [
            Expanded(
              child: Divider(color: AppColors.line, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sign in to continue',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            Expanded(
              child: Divider(color: AppColors.line, thickness: 1),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildProviderButtons() {
    return [
      _SocialButton(
        svgPath: null,
        iconData: Icons.g_mobiledata_rounded,
        label: 'Continue with Google',
        onTap: () => _run(AuthService.instance.signInWithGoogle),
      ),
      const SizedBox(height: 10),
      _SocialButton(
        svgPath: null,
        iconData: Icons.apple_rounded,
        label: 'Continue with Apple',
        onTap: () => _run(AuthService.instance.signInWithApple),
      ),
      const SizedBox(height: 10),
      _SocialButton(
        svgPath: null,
        iconData: Icons.mail_outline_rounded,
        label: 'Continue with Email',
        onTap: () => setState(() => _showEmailForm = true),
      ),
      const SizedBox(height: 20),
      // Guest option — subtle, not a full button
      Center(
        child: TextButton(
          onPressed: () => _run(AuthService.instance.signInAsGuest),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.mutedText,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'Skip for now — Continue as Guest',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildEmailForm() {
    return [
      // Header
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: AppColors.ink,
            onPressed: () => setState(() {
              _showEmailForm = false;
              _isSignUp = false;
            }),
          ),
          const SizedBox(width: 4),
          Text(
            _isSignUp ? 'Create account' : 'Welcome back',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (_isSignUp) ...[
        _buildTextField(
          controller: _nameCtrl,
          hint: 'Your name',
          icon: Icons.person_outline_rounded,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
      ],
      _buildTextField(
        controller: _emailCtrl,
        hint: 'Email address',
        icon: Icons.mail_outline_rounded,
        action: TextInputAction.next,
        type: TextInputType.emailAddress,
        autofill: AutofillHints.email,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _passwordCtrl,
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        action: TextInputAction.done,
        autofill: AutofillHints.password,
        obscure: _obscure,
        onSubmitted: (_) => _submitEmailForm(),
        suffix: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.mutedText,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      if (!_isSignUp)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Forgot password?',
                style: TextStyle(fontSize: 12)),
          ),
        ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _submitEmailForm,
          child: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _isSignUp = !_isSignUp),
          style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
          child: Text(
            _isSignUp
                ? 'Already have an account? Sign in'
                : "Don't have an account? Sign up",
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputAction action = TextInputAction.next,
    TextInputType type = TextInputType.text,
    String? autofill,
    bool obscure = false,
    void Function(String)? onSubmitted,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textInputAction: action,
      obscureText: obscure,
      autofillHints: autofill != null ? [autofill] : null,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.mutedText),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        'By continuing you agree to our Terms & Privacy Policy',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String? svgPath;
  final IconData? iconData;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    this.svgPath,
    this.iconData,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line, width: 1.2),
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Icon(iconData, size: 22, color: AppColors.inkSoft),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
