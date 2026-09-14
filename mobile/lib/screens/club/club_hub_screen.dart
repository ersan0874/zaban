import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          backgroundColor: AppColors.mist,
          appBar: AppBar(
            title: Text(
              'باشگاه',
              style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
            ),
            bottom: TabBar(
              labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.vazirmatn(),
              indicatorColor: AppColors.tealDeep,
              labelColor: AppColors.tealDeep,
              unselectedLabelColor: AppColors.slate,
              tabs: const [
                Tab(text: 'بازی'),
                Tab(text: 'لیگ'),
                Tab(text: 'فروشگاه'),
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
