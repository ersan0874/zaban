import 'package:flutter/material.dart';
import 'package:zaban/screens/club/league_tab.dart';
import 'package:zaban/screens/gamification/gamification_screen.dart';
import 'package:zaban/screens/shop/shop_screen.dart';
import 'package:zaban/theme/app_theme.dart';

/// Club area: play stats, weekly league, shop.
class ClubHubScreen extends StatelessWidget {
  const ClubHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('باشگاه'),
            bottom: const TabBar(
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  icon: Icon(Icons.emoji_events_rounded, color: AppColors.sun),
                  text: 'پیشرفت',
                ),
                Tab(
                  icon: Icon(Icons.shield_rounded, color: AppColors.flame),
                  text: 'لیگ',
                ),
                Tab(
                  icon: Icon(Icons.storefront_rounded, color: AppColors.grape),
                  text: 'فروشگاه',
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              GamificationScreen(embedded: true),
              LeagueTab(),
              ShopScreen(embedded: true),
            ],
          ),
        ),
      ),
    );
  }
}
