import 'dart:ui';
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
          // ── Background (match Signup: dark gradient + glow) ─────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B0614),
                    Color(0xFF2B0A4F),
                    Color(0xFF6F2DA8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -90,
                    right: -60,
                    child: _GlowBlob(
                      color: const Color(0xFFB26CFF).withValues(alpha: 0.45),
                      size: 220,
                      blur: 28,
                    ),
                  ),
                  Positioned(
                    top: 90,
                    left: -80,
                    child: _GlowBlob(
                      color: const Color(0xFFFF5ACD).withValues(alpha: 0.18),
                      size: 240,
                      blur: 30,
                    ),
                  ),
                  Positioned(
                    bottom: 140,
                    right: -90,
                    child: _GlowBlob(
                      color: const Color(0xFF4D7CFE).withValues(alpha: 0.14),
                      size: 260,
                      blur: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hero top (glass logo + text) ────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.40,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color:
                              CupertinoColors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6F2DA8)
                                    .withValues(alpha: 0.35),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(26),
                          child: SvgPicture.asset(
                            'assets/svg/sigin.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Endura',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back to your journey',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet card (glass, like Signup) ──────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: size.height * 0.40,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(34)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF7F0FF).withValues(alpha: 0.92),
                        const Color(0xFFEFE2FF).withValues(alpha: 0.88),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.65),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A1A6B)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3C135D),
                            letterSpacing: -0.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue your Endura journey.',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF4A1A6B)
                                .withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),

                        _AuthField(
                          controller: _username,
                          placeholder: 'Username',
                          icon: CupertinoIcons.person_fill,
                        ),
                        const SizedBox(height: 14),

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

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6F2DA8), Color(0xFFB26CFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6F2DA8)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CupertinoButton(
                              color: CupertinoColors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              pressedOpacity: 0.72,
                              onPressed: _handleSignin,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_biometricsAvailable) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _handleBiometricLogin,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6F2DA8)
                                        .withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF6F2DA8)
                                          .withValues(alpha: 0.22),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6F2DA8)
                                            .withValues(alpha: 0.22),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.lock_shield_fill,
                                    color: Color(0xFF3C135D),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in with biometrics',
                            style: TextStyle(
                              color: const Color(0xFF4A1A6B)
                                  .withValues(alpha: 0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          pressedOpacity: 0.55,
                          onPressed: _handleResetData,
                          child: Text(
                            'Reset All Data',
                            style: TextStyle(
                              color: const Color(0xFF4A1A6B)
                                  .withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          pressedOpacity: 0.55,
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const SignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              color: const Color(0xFF6F2DA8)
                                  .withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
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

          // ── Back button ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 6, top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    minSize: 0,
                    pressedOpacity: 0.65,
                    onPressed: () => Navigator.maybePop(context),
                    child: Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white.withValues(alpha: 0.92),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow blob for background ────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Modern Auth Field Component (focus glow) ────────────────────────────────
class _AuthField extends StatefulWidget {
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
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? const Color(0xFF6F2DA8).withValues(alpha: 0.55)
        : const Color(0xFF6F2DA8).withValues(alpha: 0.12);

    final glowColor = _focused
        ? const Color(0xFFB26CFF).withValues(alpha: 0.28)
        : const Color(0xFF6F2DA8).withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.white.withValues(alpha: 0.94),
            const Color(0xFFF6EEFF).withValues(alpha: 0.86),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: _focused ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: _focused ? 22 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CupertinoTextField(
        focusNode: _focusNode,
        controller: widget.controller,
        placeholder: widget.placeholder,
        placeholderStyle: TextStyle(
          color: const Color(0xFF4A1A6B).withValues(alpha: 0.40),
          fontWeight: FontWeight.w600,
        ),
        style: const TextStyle(
          color: CupertinoColors.black,
          fontWeight: FontWeight.w700,
        ),
        obscureText: widget.obscureText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            widget.icon,
            color: _focused
                ? const Color(0xFF6F2DA8).withValues(alpha: 0.95)
                : const Color(0xFF6F2DA8).withValues(alpha: 0.70),
          ),
        ),
        suffix: widget.suffix,
        decoration: BoxDecoration(
          color: CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
