import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/word_model.dart';
import 'package:zaban/theme/app_theme.dart';
import 'package:zaban/widgets/zaban_ui.dart';

class WordStudyScreen extends StatefulWidget {
  const WordStudyScreen({
    super.key,
    required this.unitTitle,
    required this.words,
  });

  final String unitTitle;
  final List<WordModel> words;

  @override
  State<WordStudyScreen> createState() => _WordStudyScreenState();
}

class _WordStudyScreenState extends State<WordStudyScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.unitTitle, style: GoogleFonts.vazirmatn()),
        ),
        body: Center(
          child: Text(
            'واژه‌ای برای این یونیت نیست',
            style: GoogleFonts.vazirmatn(color: AppColors.slate),
          ),
        ),
      );
    }

    final total = widget.words.length;

    return Scaffold(
      body: Container(
        color: AppColors.snow,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'بستن',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 28),
                      color: AppColors.locked,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ZProgressBar(
                        value: total == 0 ? 0 : (_currentPage + 1) / total,
                        color: AppColors.sky,
                        height: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentPage + 1}/$total',
                      style: AppTheme.latin(
                        fontSize: 15,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  widget.unitTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return _WordPage(word: widget.words[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentPage == 0
                            ? null
                            : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                ),
                        child: Text(
                          'قبلی',
                          style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentPage >= total - 1
                            ? () => Navigator.pop(context)
                            : () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                ),
                        child: Text(
                          _currentPage >= total - 1 ? 'پایان' : 'بعدی',
                          style: GoogleFonts.vazirmatn(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
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

class _WordPage extends StatelessWidget {
  const _WordPage({required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                Text(
                  word.word,
                  textAlign: TextAlign.center,
                  style: AppTheme.latin(fontSize: 40, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.skySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    word.persianMeaning,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.skyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (word.synonyms.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'مترادف‌ها',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.vazirmatn(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: word.synonyms
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.snow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line, width: 2),
                      ),
                      child: Text(
                        s,
                        style: AppTheme.latin(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (word.examples.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'مثال‌ها',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.vazirmatn(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...word.examples.map(
              (example) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      example.english,
                      style: AppTheme.latin(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      example.persian,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
