import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/social_repository.dart';
import 'package:zaban/screens/social/chat_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = SocialRepository();
  final _friendCtrl = TextEditingController();
  final _feedCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<FriendItem> _friends = const [];
  List<FriendStreak> _streaks = const [];
  List<FeedEntry> _feed = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _friendCtrl.dispose();
    _feedCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final friends = await _repo.listFriends();
      List<FriendStreak> streaks = const [];
      try {
        streaks = await _repo.friendStreaks();
      } catch (_) {}
      final feed = await _repo.getFeed();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _streaks = streaks;
        _feed = feed;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'بارگذاری اجتماعی ناموفق بود';
      });
    }
  }

  Future<void> _addFriend() async {
    final value = _friendCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _repo.requestFriend(value);
      if (!mounted) return;
      _friendCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('درخواست دوستی ارسال شد', style: GoogleFonts.vazirmatn()),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.vazirmatn())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _postFeed() async {
    final value = _feedCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _repo.postFeed(value);
      _feedCtrl.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.vazirmatn())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _streakFor(String userId) {
    for (final s in _streaks) {
      if (s.userId == userId) return s.streakCount;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دوستان'),
          bottom: TabBar(
            controller: _tabs,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                icon: Icon(Icons.dynamic_feed_rounded, color: AppColors.sky),
                text: 'فید',
              ),
              Tab(
                icon: Icon(Icons.people_rounded, color: AppColors.grape),
                text: 'دوستان',
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.locked),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ZMessage(
                    icon: Icons.people_outline_rounded,
                    text: _error!,
                    actionLabel: 'تلاش دوباره',
                    onAction: _load,
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildFeed(),
                      _buildFriends(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFeed() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ZCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _feedCtrl,
                  decoration: const InputDecoration(
                    hintText: 'چه خبر؟ یک پست کوتاه بنویس…',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    onPressed: _busy ? null : _postFeed,
                    child: const Text('ارسال'),
                  ),
                ),
              ],
            ),
          ),
          const ZSectionTitle('فعالیت‌ها'),
          if (_feed.isEmpty)
            const ZMessage(
              icon: Icons.forum_rounded,
              color: AppColors.skyBorder,
              text: 'هنوز فعالیتی نیست. یک درس تمام کن یا پست بگذار.',
            )
          else
            ..._feed.map(
              (item) => ZCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ZAvatar(name: item.displayName, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            style: GoogleFonts.vazirmatn(
                              height: 1.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriends() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ZCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _friendCtrl,
                    decoration: const InputDecoration(
                      hintText: 'ایمیل یا شناسه کاربر',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: AppTheme.chunkyStyle(
                    face: AppColors.sky,
                    edge: AppColors.skyDark,
                    foreground: Colors.white,
                  ),
                  onPressed: _busy ? null : _addFriend,
                  child: const Text('دعوت'),
                ),
              ],
            ),
          ),
          const ZSectionTitle('دوستان من'),
          if (_friends.isEmpty)
            const ZMessage(
              icon: Icons.person_add_alt_1_rounded,
              color: AppColors.grape,
              text: 'هنوز دوستی نداری. با ایمیل دعوت کن تا با هم یاد بگیرید.',
            )
          else
            ZCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, f) in _friends.indexed) ...[
                    if (i > 0) const Divider(height: 2, color: AppColors.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          ZAvatar(name: f.displayName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              f.displayName,
                              style: GoogleFonts.vazirmatn(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.flame,
                            size: 20,
                          ),
                          Text(
                            '${_streakFor(f.userId)}',
                            style: AppTheme.latin(
                              fontSize: 15,
                              color: AppColors.flame,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'چت',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ChatScreen(
                                    peerUserId: f.userId,
                                    peerName: f.displayName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_rounded,
                              color: AppColors.sky,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
