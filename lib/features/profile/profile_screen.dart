
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/utils/formatters.dart';
import 'package:endura/shared/models/cached_user.dart';
import 'package:endura/shared/widgets/endura_avatar.dart';
import 'package:endura/features/activity/activity_repository.dart';
import 'package:endura/features/activity/activity_list_screen.dart';
import 'package:endura/features/profile/user_repository.dart';
import 'package:endura/features/profile/edit_profile_screen.dart';
import 'package:endura/core/storage/hive_boxes.dart';
import 'package:endura/core/storage/hive_service.dart';
import 'package:endura/core/utils/biometric_service.dart';
import 'package:endura/signin.dart';
import 'package:endura/signup.dart';
import 'package:endura/main.dart' show themeNotifier;

/// Profile tab — user info, stats, activity history, and inline settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CachedUser? _user;

  // Settings state (inline)
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;

  // Theme mode: now only 'light' or 'dark' (system removed)
  String _themeMode = 'light';

  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSettings();
  }

  void _loadUser() {
    setState(() {
      _user = UserRepository.getProfile();
    });
  }

  Future<void> _loadSettings() async {
    final available = await BiometricService.canAuthenticate();
    final enabled = BiometricService.isEnabled();
    final theme = themeNotifier.mode;

    // if old value is 'system', default to 'light'
    final normalizedTheme = (theme == 'dark') ? 'dark' : 'light';

    if (!mounted) return;
    setState(() {
      _biometricsAvailable = available;
      _biometricsEnabled = enabled;
      _themeMode = normalizedTheme;
      _loadingSettings = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
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

              await HiveService.clearAll();
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
    final totalActivities = ActivityRepository.getCount();
    final totalDistance = ActivityRepository.getTotalDistance();
    final totalDuration = ActivityRepository.getTotalDuration();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            await Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => const EditProfileScreen(),
              ),
            );
            _loadUser();
          },
          child: const Icon(CupertinoIcons.pencil, size: 22),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            children: [
              const SizedBox(height: 10),

              EnduraAvatar(
                imagePath: _user?.avatarLocalPath,
                name: _user?.displayName,
                radius: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _user?.displayName ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textColor(context),
                ),
              ),
              if (_user != null && _user!.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _user!.bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_user != null && _user!.location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _user!.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(label: 'Activities', value: '$totalActivities'),
                    _ProfileStat(
                      label: 'Distance',
                      value: Formatters.distanceKm(totalDistance),
                    ),
                    _ProfileStat(
                      label: 'Time',
                      value: Formatters.duration(totalDuration),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _ProfileMenuItem(
                icon: CupertinoIcons.clock,
                label: 'Activity History',
                onTap: () async {
                  await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const ActivityListScreen(),
                    ),
                  );
                  _loadUser();
                },
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'SETTINGS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (_loadingSettings)
                const Center(child: CupertinoActivityIndicator(radius: 14))
              else ...[
                // ── Appearance (Theme) — System removed ────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
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
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<String>(
                          groupValue: _themeMode,
                          children: const {
                            'light': Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text('Light',
                                  style: TextStyle(fontSize: 13)),
                            ),
                            'dark': Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child:
                              Text('Dark', style: TextStyle(fontSize: 13)),
                            ),
                          },
                          onValueChanged: (value) async {
                            if (value == null) return;
                            setState(() => _themeMode = value);
                            await themeNotifier.setMode(value); // 'light' or 'dark'
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Security (Biometrics) ───────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textColor(context),
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
                          onChanged:
                          _biometricsAvailable ? _toggleBiometrics : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Account actions ────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Column(
                    children: [
                      _SettingsAction(
                        icon: CupertinoIcons.square_arrow_right,
                        iconColor: AppTheme.primary,
                        label: 'Log Out',
                        onTap: _handleLogout,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 0.5,
                          color: CupertinoColors.separator,
                        ),
                      ),
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

                const SizedBox(height: 18),

                Center(
                  child: Column(
                    children: [
                      Text(
                        'Endura v1.0.0',
                        style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Local-first fitness tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
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
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }
}