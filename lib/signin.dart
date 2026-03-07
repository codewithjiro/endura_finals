import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/hive_service.dart';
import 'core/utils/biometric_service.dart';
import 'features/home/home_shell.dart';
import 'features/profile/user_repository.dart';
import 'signup.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final box = Hive.box(HiveBoxes.database);
  bool hidePassword = true;
  bool _biometricsAvailable = false;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = BiometricService.isEnabled();
    final canAuth = await BiometricService.canAuthenticate();
    if (mounted) {
      setState(() => _biometricsAvailable = enabled && canAuth);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await BiometricService.authenticate(
      reason: 'Sign in to Endura',
    );
    if (!authenticated || !mounted) return;

    // Biometric passed — log in directly
    box.put('loggedIn', true);

    final storedUsername = box.get('username');
    if (UserRepository.getProfile() == null && storedUsername != null) {
      await UserRepository.createFromAuth(storedUsername);
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _showError(String message) {
    showThemedDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Oops'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _handleSignin() async {
    if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final storedUsername = box.get('username');
    final storedPassword = box.get('password');

    if (storedUsername == null || storedPassword == null) {
      _showError('No account found. Please sign up first.');
      return;
    }

    if (_username.text.trim() != storedUsername ||
        _password.text.trim() != storedPassword) {
      _showError('Invalid username or password.');
      return;
    }

    // Set logged in flag
    box.put('loggedIn', true);

    // Ensure profile exists
    if (UserRepository.getProfile() == null) {
      await UserRepository.createFromAuth(storedUsername);
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _handleResetData() async {
    // If biometrics are enabled, require authentication first
    if (BiometricService.isEnabled()) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to reset all data',
      );
      if (!authenticated) {
        if (mounted) {
          showThemedDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Authentication Failed'),
              content: const Text(
                'Biometric authentication is required to reset data.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete your account, all activities, '
          'challenges, feed data, and preferences. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reset Everything'),
            onPressed: () async {
              Navigator.of(ctx).pop();

              // Clear all feature boxes (activities, feed, challenges, etc.)
              await HiveService.clearAll();

              // Clear auth credentials and login state
              await box.clear();

              if (!mounted) return;

              // Navigate to signup as a fresh user
              Navigator.of(context).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const SignupPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // ── Light Purple hero top with SVG ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.44,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SVG Logo Container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6F2DA8).withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: SvgPicture.asset(
                        'assets/svg/sigin.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Endura',
                      style: TextStyle(
                        color: Color(0xFF4A1A6B),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back to your journey',
                      style: TextStyle(
                        color: const Color(0xFF4A1A6B).withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Grape Purple bottom card ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: size.height * 0.36,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6F2DA8), Color(0xFF8E44AD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue your Endura journey.',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Username field
                    _AuthField(
                      controller: _username,
                      placeholder: 'Username',
                      icon: CupertinoIcons.person_fill,
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    _AuthField(
                      controller: _password,
                      placeholder: 'Password',
                      icon: CupertinoIcons.lock_fill,
                      obscureText: hidePassword,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => hidePassword = !hidePassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            hidePassword
                                ? CupertinoIcons.eye_fill
                                : CupertinoIcons.eye_slash_fill,
                            color: CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _handleSignin,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFF6F2DA8),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Biometric login button
                    if (_biometricsAvailable) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _handleBiometricLogin,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: CupertinoColors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in with biometrics',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Reset Data button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _handleResetData,
                      child: Text(
                        'Reset All Data',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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

// ── Modern Auth Field Component ─────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
        style: const TextStyle(color: CupertinoColors.black),
        obscureText: obscureText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(icon, color: CupertinoColors.systemGrey),
        ),
        suffix: suffix,
        decoration: BoxDecoration(
          color: CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
