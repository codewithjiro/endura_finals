import 'package:flutter/cupertino.dart';
import 'package:endura/features/home/feed_screen.dart';
import 'package:endura/features/tracking/tracking_screen.dart';
import 'package:endura/features/explore/explore_screen.dart';
import 'package:endura/features/challenges/challenge_list_screen.dart';
import 'package:endura/features/profile/profile_screen.dart';

/// Main bottom tab navigation shell — 5 tabs.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: const Color(0xFF6F2DA8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location_fill),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map_fill),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flag_fill),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle_fill),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const FeedScreen();
              case 1:
                return const TrackingScreen();
              case 2:
                return const ExploreScreen();
              case 3:
                return const ChallengeListScreen();
              case 4:
                return const ProfileScreen();
              default:
                return const FeedScreen();
            }
          },
        );
      },
    );
  }
}
