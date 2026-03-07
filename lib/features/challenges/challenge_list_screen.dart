import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/shared/models/cached_challenge.dart';
import 'package:endura/features/challenges/challenge_repository.dart';
import 'package:endura/features/challenges/challenge_detail_screen.dart';

/// Challenges tab — list of all challenges with join/progress.
class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ChallengeRepository.seedDefaults();
    // Recalculate streaks on screen open
    await ChallengeRepository.recalculateStreaks();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Challenges')),
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Challenges')),
      child: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: ChallengeRepository.listenable,
          builder: (context, box, _) {
            final joined = ChallengeRepository.getJoined();
            final available = ChallengeRepository.getAvailable();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (joined.isNotEmpty) ...[
                    Text(
                      'Active Challenges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...joined.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChallengeCard(
                            challenge: c,
                            onTap: () => _openDetail(c),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Available Challenges',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text('All challenges joined!',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ...available.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChallengeCard(
                            challenge: c,
                            onTap: () => _openDetail(c),
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(CachedChallenge c) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ChallengeDetailScreen(challengeId: c.id),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final CachedChallenge challenge;
  final VoidCallback onTap;

  const _ChallengeCard({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isJoined = challenge.joined && !challenge.completed;
    final percent = (challenge.progressPercent * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x08000000),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                gradient: challenge.completed
                    ? const LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30D158)])
                    : isJoined
                        ? const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF5AC8FA)])
                        : const LinearGradient(
                            colors: [
                                Color(0xFFAEAEB2),
                                Color(0xFFC7C7CC)
                              ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (challenge.badge != null)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(challenge.badge!,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      if (challenge.badge != null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              challenge.type.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (challenge.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.checkmark_circle_fill,
                                  size: 14, color: AppTheme.success),
                              const SizedBox(width: 4),
                              const Text('Done',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success)),
                            ],
                          ),
                        )
                      else if (!challenge.joined)
                        const Icon(CupertinoIcons.chevron_right,
                            size: 16, color: CupertinoColors.systemGrey3),
                    ],
                  ),
                  if (isJoined) ...[
                    const SizedBox(height: 14),
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 6,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: constraints.maxWidth,
                                        color: CupertinoColors.systemGrey5,
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: constraints.maxWidth *
                                            challenge.progressPercent,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.primary,
                                                Color(0xFF5AC8FA)
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${challenge.progress.toStringAsFixed(challenge.type == ChallengeType.activityCount || challenge.type == ChallengeType.streak ? 0 : 1)} / ${challenge.target.toStringAsFixed(0)} ${_unitForType(challenge.type)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _unitForType(ChallengeType type) {
  switch (type) {
    case ChallengeType.distance:
      return 'km';
    case ChallengeType.time:
      return 'min';
    case ChallengeType.activityCount:
      return 'activities';
    case ChallengeType.streak:
      return 'days';
  }
}

