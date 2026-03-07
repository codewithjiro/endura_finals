import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/shared/models/cached_user.dart';
import 'package:endura/shared/widgets/endura_avatar.dart';
import 'package:endura/shared/widgets/photo_action_sheet.dart';
import 'package:endura/features/profile/user_repository.dart';

/// Edit profile screen with photo, name, bio, and preferences.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _goalsCtrl;
  String _preferredSport = 'running';
  String _measurementUnit = 'metric';
  String _visibility = 'public';
  String? _avatarPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = UserRepository.getProfile();
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
    _goalsCtrl = TextEditingController(text: user?.goals ?? '');
    _preferredSport = user?.preferredSport ?? 'running';
    _measurementUnit = user?.measurementUnit ?? 'metric';
    _visibility = user?.profileVisibility ?? 'public';
    _avatarPath = user?.avatarLocalPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _goalsCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final hasPhoto = _avatarPath != null && _avatarPath!.isNotEmpty;
    final path = await showPhotoActionSheet(
      context,
      showRemove: hasPhoto,
      onRemove: () => setState(() => _avatarPath = null),
    );
    if (path != null && mounted) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final existing = UserRepository.getProfile();
    final user = (existing ?? CachedUser(id: 'local', displayName: ''))
        .copyWith(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      goals: _goalsCtrl.text.trim(),
      preferredSport: _preferredSport,
      measurementUnit: _measurementUnit,
      profileVisibility: _visibility,
      avatarLocalPath: _avatarPath,
    );

    await UserRepository.saveProfile(user);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Profile'),
        previousPageTitle: 'Profile',
        trailing: _saving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
              GestureDetector(
                onTap: _changePhoto,
                child: Stack(
                  children: [
                    EnduraAvatar(
                      imagePath: _avatarPath,
                      name: _nameCtrl.text,
                      radius: 48,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: CupertinoColors.white, width: 2),
                        ),
                        child: const Icon(CupertinoIcons.camera_fill,
                            size: 14, color: CupertinoColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.only(top: 6),
                onPressed: _changePhoto,
                child: const Text('Change Photo',
                    style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),

              // Fields
              _FormField(controller: _nameCtrl, label: 'Display Name'),
              const SizedBox(height: 12),
              _FormField(controller: _bioCtrl, label: 'Bio', maxLines: 3),
              const SizedBox(height: 12),
              _FormField(controller: _locationCtrl, label: 'Location'),
              const SizedBox(height: 12),
              _FormField(controller: _goalsCtrl, label: 'Goals', maxLines: 2),
              const SizedBox(height: 20),

              // Preferred sport
              _SectionLabel('Preferred Sport'),
              const SizedBox(height: 6),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _preferredSport,
                children: const {
                  'running': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text('Running', style: TextStyle(fontSize: 13))),
                  'cycling': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text('Cycling', style: TextStyle(fontSize: 13))),
                  'walking': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text('Walking', style: TextStyle(fontSize: 13))),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _preferredSport = v);
                },
              ),
              const SizedBox(height: 20),

              // Measurement unit
              _SectionLabel('Measurement Unit'),
              const SizedBox(height: 6),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _measurementUnit,
                children: const {
                  'metric': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Metric', style: TextStyle(fontSize: 13))),
                  'imperial': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child:
                          Text('Imperial', style: TextStyle(fontSize: 13))),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _measurementUnit = v);
                },
              ),
              const SizedBox(height: 20),

              // Visibility
              _SectionLabel('Profile Visibility'),
              const SizedBox(height: 6),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _visibility,
                children: const {
                  'public': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Public', style: TextStyle(fontSize: 13))),
                  'followers': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child:
                          Text('Followers', style: TextStyle(fontSize: 13))),
                  'private': Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Private', style: TextStyle(fontSize: 13))),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _visibility = v);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
        ),
        CupertinoTextField(
          controller: controller,
          maxLines: maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary)),
      ),
    );
  }
}


