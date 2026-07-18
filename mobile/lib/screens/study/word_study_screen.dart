import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/models/word_model.dart';
import 'package:zaban/theme/app_theme.dart';

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
    final total = widget.words.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FBFC), AppColors.mist, Color(0xFFE8F4F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.inkSoft,
                    ),
                    Expanded(
                      child: Text(
                        widget.unitTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${_currentPage + 1}/$total',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDeep,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (_currentPage + 1) / total,
                    minHeight: 6,
                    backgroundColor: AppColors.mistDeep,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (index) => setState(() => _currentPage = index),
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
                          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
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
                          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
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
          const SizedBox(height: 12),
          Text(
            word.word,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            word.persianMeaning,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'مترادف‌ها',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
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
                      color: AppColors.tealSoft.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'مثال‌ها',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.vazirmatn(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          ...word.examples.map(
            (example) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.mistDeep),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    example.english,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      height: 1.45,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
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
      ),
    );
  }
}
