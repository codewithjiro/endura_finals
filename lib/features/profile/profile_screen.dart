import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/utils/formatters.dart';
import 'package:endura/shared/models/cached_user.dart';
import 'package:endura/shared/widgets/endura_avatar.dart';
import 'package:endura/features/activity/activity_repository.dart';
import 'package:endura/features/activity/activity_list_screen.dart';
import 'package:endura/features/profile/user_repository.dart';
import 'package:endura/features/profile/edit_profile_screen.dart';
import 'package:endura/features/settings/settings_screen.dart';

/// Profile tab — user info, stats, and navigation to history/settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CachedUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() {
      _user = UserRepository.getProfile();
    });
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
              // Avatar
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
                        fontSize: 14, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_user != null && _user!.location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.location_solid,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _user!.location,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(
                        label: 'Activities', value: '$totalActivities'),
                    _ProfileStat(
                        label: 'Distance',
                        value: Formatters.distanceKm(totalDistance)),
                    _ProfileStat(
                        label: 'Time',
                        value: Formatters.duration(totalDuration)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items
              _ProfileMenuItem(
                icon: CupertinoIcons.clock,
                label: 'Activity History',
                onTap: () async {
                  await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const ActivityListScreen(),
                    ),
                  );
                  _loadUser(); // refresh stats
                },
              ),
              const SizedBox(height: 10),
              _ProfileMenuItem(
                icon: CupertinoIcons.settings,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
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
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context))),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
              child: Text(label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor(context))),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}




