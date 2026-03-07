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
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Strava-style Share Card ──────────────────────────
              _StravaShareCard(
                activity: widget.activity,
                routePoints: _routePoints,
                coverMedia: _photos.isNotEmpty ? _photos.first : null,
              ),
              const SizedBox(height: 20),

              // ── Stats Grid ──────────────────────────────────────
              _StatsSection(activity: widget.activity),
              const SizedBox(height: 20),

              // ── Caption ─────────────────────────────────────────
              Text('Caption',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context))),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _captionController,
                placeholder: 'How was your workout?',
                maxLines: 3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(height: 20),

              // ── Photo Attachments ──────────────────────────────
              Row(
                children: [
                  Text('Photos',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor(context))),
                  const Spacer(),
                  Text('${_photos.length} photo${_photos.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              _PhotoGrid(
                items: _photos,
                onAdd: _addPhoto,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STRAVA-STYLE SHARE CARD
// ═══════════════════════════════════════════════════════════════════

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
            // ── Background ────────────────────────────────────
            if (hasCover)
              Image.file(File(coverMedia!.localPath), fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                  ),
                ),
              ),

            // ── Dark overlay for readability ──────────────────
            if (hasCover)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0x00000000),
                      const Color(0x40000000),
                      const Color(0xCC000000),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

            // ── Content Overlay ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Stats
                  _OverlayStat(
                    label: 'Distance',
                    value: Formatters.distanceKm(activity.distance),
                    fontSize: 42,
                  ),
                  const SizedBox(height: 16),
                  _OverlayStat(
                    label: 'Pace',
                    value: activity.avgPace.isNotEmpty
                        ? activity.avgPace
                        : Formatters.pace(Duration(seconds: activity.duration),
                            activity.distance),
                    fontSize: 36,
                  ),
                  const SizedBox(height: 16),
                  _OverlayStat(
                    label: 'Time',
                    value: Formatters.duration(
                        Duration(seconds: activity.duration)),
                    fontSize: 36,
                  ),

                  const Spacer(flex: 2),

                  // Route polyline-only (no map tiles)
                  if (hasRoute)
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                CupertinoColors.white.withValues(alpha: 0.15),
                            width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: PolylineOnlyPreview(
                            routePoints: routePoints),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // App branding
                  Text(
                    'ENDURA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: CupertinoColors.white.withValues(alpha: 0.6),
                      letterSpacing: 3,
                    ),
                  ),

                  const Spacer(flex: 1),
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
    return Container(
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
              Text(
                '${activity.type.icon} ${activity.type.label}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
              const Spacer(),
              Text(
                Formatters.dateTime(activity.startTime),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _DetailStat(
                      label: 'Distance',
                      value: Formatters.distanceKm(activity.distance))),
              Expanded(
                  child: _DetailStat(
                      label: 'Duration',
                      value: Formatters.duration(
                          Duration(seconds: activity.duration)))),
              Expanded(
                  child: _DetailStat(
                      label: 'Avg Pace', value: activity.avgPace)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _DetailStat(
                      label: 'Speed',
                      value:
                          '${activity.avgSpeed.toStringAsFixed(1)} km/h')),
              Expanded(
                  child: _DetailStat(
                      label: 'Calories',
                      value: Formatters.calories(activity.calories))),
              if (activity.elevationGain > 0)
                Expanded(
                    child: _DetailStat(
                        label: 'Elevation',
                        value:
                            Formatters.elevation(activity.elevationGain))),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context))),
      ],
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
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
              color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.plus_circle_fill,
                color: AppTheme.primary, size: 28),
            SizedBox(height: 4),
            Text('Add Photo',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            width: 110,
            height: 110,
            child: Image.file(
              File(item.localPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: CupertinoColors.systemGrey5,
                child: const Icon(CupertinoIcons.photo,
                    color: CupertinoColors.systemGrey3),
              ),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xCC000000),
                shape: BoxShape.circle,
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























