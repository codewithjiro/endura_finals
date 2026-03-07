import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/storage/hive_boxes.dart';
import 'package:endura/core/storage/hive_service.dart';
import 'package:endura/core/utils/biometric_service.dart';
import 'package:endura/signin.dart';
import 'package:endura/signup.dart';
import 'package:endura/main.dart' show themeNotifier;

/// Settings screen — biometrics toggle, logout, and reset data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  String _themeMode = 'system';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await BiometricService.canAuthenticate();
    final enabled = BiometricService.isEnabled();
    final theme = themeNotifier.mode;
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsEnabled = enabled;
        _themeMode = theme;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Verify biometric first before enabling
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      if (!authenticated) return;
    }

    await BiometricService.setEnabled(value);
    if (mounted) {
      setState(() => _biometricsEnabled = value);
    }
  }

  void _handleLogout() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'You will need to sign in again. Your data will be kept.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Log Out'),
            onPressed: () async {
              Navigator.of(ctx).pop();

              final box = Hive.box(HiveBoxes.database);
              await box.put('loggedIn', false);

              if (!mounted) return;

              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const SigninPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetData() async {
    // If biometrics enabled, require authentication first
    if (_biometricsEnabled) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to reset all data',
      );
      if (!authenticated) {
        if (mounted) {
          showCupertinoDialog(
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

              // Clear all feature boxes
              await HiveService.clearAll();

              // Clear auth credentials and login state
              final box = Hive.box(HiveBoxes.database);
              await box.clear();

              if (!mounted) return;

              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        previousPageTitle: 'Profile',
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Appearance Section ──────────────────────────
                    _SectionHeader('Appearance'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _themeMode == 'dark'
                                    ? CupertinoIcons.moon_fill
                                    : CupertinoIcons.sun_max_fill,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Theme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child:
                                CupertinoSlidingSegmentedControl<String>(
                              groupValue: _themeMode,
                              children: const {
                                'system': Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text('System',
                                      style: TextStyle(fontSize: 13)),
                                ),
                                'light': Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text('Light',
                                      style: TextStyle(fontSize: 13)),
                                ),
                                'dark': Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text('Dark',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              },
                              onValueChanged: (value) async {
                                if (value == null) return;
                                setState(() => _themeMode = value);
                                await themeNotifier.setMode(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Security Section ────────────────────────────
                    _SectionHeader('Security'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Column(
                        children: [
                          // Biometric toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Biometric Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              AppTheme.textColor(context),
                                        ),
                                      ),
                                      Text(
                                        _biometricsAvailable
                                            ? 'Use fingerprint or Face ID to sign in'
                                            : 'Not available on this device',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: _biometricsEnabled,
                                  activeTrackColor: AppTheme.primary,
                                  onChanged: _biometricsAvailable
                                      ? _toggleBiometrics
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Account Section ─────────────────────────────
                    _SectionHeader('Account'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Column(
                        children: [
                          // Logout
                          _SettingsAction(
                            icon: CupertinoIcons.square_arrow_right,
                            iconColor: AppTheme.primary,
                            label: 'Log Out',
                            onTap: _handleLogout,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 0.5,
                              color: CupertinoColors.separator,
                            ),
                          ),
                          // Reset data
                          _SettingsAction(
                            icon: CupertinoIcons.trash,
                            iconColor: AppTheme.danger,
                            label: 'Reset All Data',
                            labelColor: AppTheme.danger,
                            onTap: _handleResetData,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Info footer ─────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Endura v1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Local-first fitness tracking',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingsAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppTheme.textColor(context),
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}






