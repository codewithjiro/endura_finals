import 'package:flutter/cupertino.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/maps/endura_map.dart';

/// Explore tab — route browsing (post-MVP, placeholder for now).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Explore'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Map preview
            Expanded(
              flex: 2,
              child: ClipRRect(
                child: EnduraMap(interactive: true),
              ),
            ),
            // Placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.map_fill,
                        size: 48, color: CupertinoColors.systemGrey3),
                    const SizedBox(height: 12),
                    Text(
                      'Routes Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Browse and save routes in a future update.',
                      style:
                          TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


