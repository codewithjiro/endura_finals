import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/utils/formatters.dart';
import 'package:endura/core/media/media_picker_service.dart';
import 'package:endura/shared/models/cached_activity.dart';
import 'package:endura/shared/widgets/photo_action_sheet.dart';
import 'package:endura/shared/widgets/polyline_preview.dart';
import 'package:endura/features/profile/user_repository.dart';
import 'package:endura/features/feed/feed_repository.dart';
import 'package:endura/features/challenges/challenge_repository.dart';
import 'package:endura/features/activity/activity_repository.dart';

/// Strava-inspired post-workout summary screen.
class SummaryScreen extends StatefulWidget {
  final CachedActivity activity;

  const SummaryScreen({super.key, required this.activity});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<PhotoItem> _photos = [];
  bool _saving = false;

  List<LatLng> get _routePoints => widget.activity.routePoints
      .map((p) => LatLng(p[0], p[1]))
      .toList();

  @override
  void initState() {
    super.initState();
    // Auto-open camera when summary opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final path = await MediaPickerService.pickFromCamera();
    if (path != null && mounted) {
      setState(() {
        _photos.add(PhotoItem(localPath: path));
      });
    }
  }

  Future<void> _addPhoto() async {
    final result = await showMediaActionSheet(context);
    if (result != null && mounted) {
      setState(() {
        _photos.add(PhotoItem(localPath: result.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = UserRepository.getProfile();
      final userId = user?.id ?? '';

      final toSave = CachedActivity(
        localId: widget.activity.localId,
        userId: userId,
        type: widget.activity.type,
        distance: widget.activity.distance,
        duration: widget.activity.duration,
        avgPace: widget.activity.avgPace,
        avgSpeed: widget.activity.avgSpeed,
        calories: widget.activity.calories,
        elevationGain: widget.activity.elevationGain,
        routePoints: widget.activity.routePoints,
        startTime: widget.activity.startTime,
        endTime: widget.activity.endTime,
        caption: _captionController.text.trim(),
        photos: _photos,
      );

      await ActivityRepository.save(toSave);
      if (user != null) {
        await FeedRepository.createFromActivity(toSave, user);
      }
      await ChallengeRepository.updateProgressFromActivity(toSave);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Save Failed'),
            content: Text('Could not save activity: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _discard() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('This workout will not be saved.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Discard'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Workout Summary'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _discard,
          child:
              const Text('Discard', style: TextStyle(color: AppTheme.danger)),
        ),
        trailing: _saving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHero(
                activity: widget.activity,
                routePoints: _routePoints,
                coverMedia: _photos.isNotEmpty ? _photos.first : null,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _SectionHeader(
                eyebrow: 'OVERVIEW',
                title: 'Session recap',
                subtitle: 'Your workout details are ready to review and share.',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _StatsSection(activity: widget.activity),
              const SizedBox(height: AppTheme.spacingLg),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      eyebrow: 'CAPTION',
                      title: 'Add your thoughts',
                      subtitle: 'Keep it short, personal, and ready for your feed.',
                      compact: true,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    CupertinoTextField(
                      controller: _captionController,
                      placeholder: 'How was your workout?',
                      maxLines: 4,
                      minLines: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGrey6,
                          context,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      eyebrow: 'MEDIA',
                      title: 'Photos',
                      subtitle:
                          '${_photos.length} photo${_photos.length == 1 ? '' : 's'} attached to this workout.',
                      compact: true,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _PhotoGrid(
                      items: _photos,
                      onAdd: _addPhoto,
                      onRemove: _removePhoto,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final CachedActivity activity;
  final List<LatLng> routePoints;
  final PhotoItem? coverMedia;

  const _SummaryHero({
    required this.activity,
    required this.routePoints,
    this.coverMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StravaShareCard(
          activity: activity,
          routePoints: routePoints,
          coverMedia: coverMedia,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _HeroMetrics(activity: activity),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppTheme.primary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 20 : 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.withValues(alpha: 0.18)
              : CupertinoColors.systemGrey4.withValues(alpha: 0.35),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  final CachedActivity activity;

  const _HeroMetrics({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            icon: CupertinoIcons.flame_fill,
            label: 'Calories',
            value: Formatters.calories(activity.calories),
            tint: AppTheme.warning,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _MetricChip(
            icon: CupertinoIcons.speedometer,
            label: 'Speed',
            value: '${activity.avgSpeed.toStringAsFixed(1)} km/h',
            tint: AppTheme.primary,
          ),
        ),
        if (activity.elevationGain > 0) ...[
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: _MetricChip(
              icon: CupertinoIcons.arrow_up_right_circle_fill,
              label: 'Elevation',
              value: Formatters.elevation(activity.elevationGain),
              tint: AppTheme.success,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? tint.withValues(alpha: 0.16)
            : tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StravaShareCard extends StatelessWidget {
  final CachedActivity activity;
  final List<LatLng> routePoints;
  final PhotoItem? coverMedia;

  const _StravaShareCard({
    required this.activity,
    required this.routePoints,
    this.coverMedia,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover =
        coverMedia != null && File(coverMedia!.localPath).existsSync();
    final hasRoute = routePoints.length >= 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCover)
              Image.file(File(coverMedia!.localPath), fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF150E26),
                      Color(0xFF26183D),
                      Color(0xFF43216E),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hasCover
                      ? [
                          const Color(0x12000000),
                          const Color(0x66000000),
                          const Color(0xD9000000),
                        ]
                      : [
                          AppTheme.primary.withValues(alpha: 0.10),
                          AppTheme.primary.withValues(alpha: 0.18),
                          const Color(0xCC09090B),
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${activity.type.icon} ${activity.type.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      Formatters.dateTime(activity.startTime),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  _OverlayStat(
                    label: 'Distance',
                    value: Formatters.distanceKm(activity.distance),
                    fontSize: 44,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _OverlayStat(
                          label: 'Pace',
                          value: activity.avgPace.isNotEmpty
                              ? activity.avgPace
                              : Formatters.pace(
                                  Duration(seconds: activity.duration),
                                  activity.distance,
                                ),
                          fontSize: 28,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: CupertinoColors.white.withValues(alpha: 0.18),
                      ),
                      Expanded(
                        child: _OverlayStat(
                          label: 'Time',
                          value: Formatters.duration(
                            Duration(seconds: activity.duration),
                          ),
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  if (hasRoute)
                    SizedBox(
                      height: 138,
                      child: PolylineOnlyPreview(
                        routePoints: routePoints,
                        backgroundColor: CupertinoColors.transparent,
                        lineColor: const Color(0xFF4B1E78),
                        lineWidth: 4,
                        showGlow: false,
                        showEndpoints: true,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'ENDURA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: CupertinoColors.white.withValues(alpha: 0.72),
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayStat extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const _OverlayStat({
    required this.label,
    required this.value,
    this.fontSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.white.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STATS SECTION
// ═══════════════════════════════════════════════════════════════════

class _StatsSection extends StatelessWidget {
  final CachedActivity activity;
  const _StatsSection({required this.activity});

  @override
  Widget build(BuildContext context) {
    final paceValue = activity.avgPace.isNotEmpty
        ? activity.avgPace
        : Formatters.pace(
            Duration(seconds: activity.duration),
            activity.distance,
          );

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activity.type.icon} ${activity.type.label}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.dateTime(activity.startTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Saved locally',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  label: 'Distance',
                  value: Formatters.distanceKm(activity.distance),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _DetailStat(
                  label: 'Duration',
                  value: Formatters.duration(
                    Duration(seconds: activity.duration),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _DetailStat(label: 'Avg Pace', value: paceValue),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _DetailStat(
                  label: 'Avg Speed',
                  value: '${activity.avgSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  label: 'Calories',
                  value: Formatters.calories(activity.calories),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _DetailStat(
                  label: 'Elevation',
                  value: activity.elevationGain > 0
                      ? Formatters.elevation(activity.elevationGain)
                      : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PHOTO GRID
// ═══════════════════════════════════════════════════════════════════

class _PhotoGrid extends StatelessWidget {
  final List<PhotoItem> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoGrid({
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddMediaTile(onTap: onAdd);
          }
          final item = items[index - 1];
          return _MediaTile(
            item: item,
            onRemove: () => onRemove(index - 1),
          );
        },
      ),
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMediaTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.22), width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.plus_circle_fill,
                color: AppTheme.primary, size: 28),
            SizedBox(height: 6),
            Text('Add Photo',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final PhotoItem item;
  final VoidCallback onRemove;

  const _MediaTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: SizedBox(
              width: 110,
              height: 110,
              child: Image.file(
                File(item.localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => Container(
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey3),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.white.withValues(alpha: 0.14),
                ),
              ),
              child: const Icon(CupertinoIcons.xmark,
                  size: 12, color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

