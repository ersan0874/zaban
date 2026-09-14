import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/repositories/social_repository.dart';
import 'package:zaban/screens/social/chat_screen.dart';
import 'package:zaban/services/api_client.dart';
import 'package:zaban/theme/app_theme.dart';

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
          content: Text('درخواست دوستی ارسال شد', style: GoogleFonts.vazirmatn()),
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
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          title: Text(
            'دوستان',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            controller: _tabs,
            labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.vazirmatn(),
            indicatorColor: AppColors.tealDeep,
            labelColor: AppColors.tealDeep,
            unselectedLabelColor: AppColors.slate,
            tabs: const [
              Tab(text: 'فید'),
              Tab(text: 'دوستان'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: GoogleFonts.vazirmatn()),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(
                            'تلاش دوباره',
                            style: GoogleFonts.vazirmatn(),
                          ),
                        ),
                      ],
                    ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _feedCtrl,
                  decoration: InputDecoration(
                    hintText: 'چه خبر؟ یک پست کوتاه بنویس…',
                    hintStyle: GoogleFonts.vazirmatn(color: AppColors.slate),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.vazirmatn(),
                  maxLines: 2,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _busy ? null : _postFeed,
                    child: Text('ارسال', style: GoogleFonts.vazirmatn()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_feed.isEmpty)
            Text(
              'هنوز فعالیتی نیست. یک درس تمام کن یا پست بگذار.',
              style: GoogleFonts.vazirmatn(color: AppColors.slate),
            )
          else
            ..._feed.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mistDeep),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.w800,
                        color: AppColors.tealDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: GoogleFonts.vazirmatn(height: 1.4),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _friendCtrl,
                    decoration: InputDecoration(
                      hintText: 'ایمیل یا شناسه کاربر',
                      hintStyle: GoogleFonts.vazirmatn(color: AppColors.slate),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.vazirmatn(),
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : _addFriend,
                  child: Text('دعوت', style: GoogleFonts.vazirmatn()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_friends.isEmpty)
            Text(
              'هنوز دوستی نداری. با ایمیل دعوت کن.',
              style: GoogleFonts.vazirmatn(color: AppColors.slate),
            )
          else
            ..._friends.map((f) {
              final streak = _streakFor(f.userId);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.mistDeep),
                ),
                child: ListTile(
                  title: Text(
                    f.displayName,
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'استریک $streak روز',
                    style: GoogleFonts.vazirmatn(fontSize: 12),
                  ),
                  trailing: IconButton(
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
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.tealDeep,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
