import 'package:flutter/material.dart';
import 'package:zaban/screens/auth/auth_gate.dart';
import 'package:zaban/screens/auth/profile_screen.dart';
import 'package:zaban/screens/club/club_hub_screen.dart';
import 'package:zaban/screens/path/learning_path_screen.dart';
import 'package:zaban/screens/social/social_hub_screen.dart';
import 'package:zaban/theme/app_theme.dart';

/// Bottom navigation shell: Path · Club · Social · Me
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const LearningPathScreen(embedded: true),
      const ClubHubScreen(),
      const SocialHubScreen(),
      ProfileScreen(
        embedded: true,
        onLoggedOut: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const AuthGate()),
            (_) => false,
          );
        },
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line, width: 2)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.locked),
                selectedIcon:
                    const Icon(Icons.home_rounded, color: AppColors.flame),
                label: 'مسیر',
              ),
              NavigationDestination(
                icon:
                    Icon(Icons.emoji_events_outlined, color: AppColors.locked),
                selectedIcon: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.amber),
                label: 'باشگاه',
              ),
              NavigationDestination(
                icon:
                    Icon(Icons.people_outline_rounded, color: AppColors.locked),
                selectedIcon:
                    const Icon(Icons.people_rounded, color: AppColors.sky),
                label: 'دوستان',
              ),
              NavigationDestination(
                icon:
                    Icon(Icons.person_outline_rounded, color: AppColors.locked),
                selectedIcon:
                    const Icon(Icons.person_rounded, color: AppColors.grape),
                label: 'من',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
