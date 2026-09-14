import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaban/config/api_config.dart';
import 'package:zaban/models/question_model.dart';
import 'package:zaban/services/media_player.dart';
import 'package:zaban/theme/app_theme.dart';

typedef ExerciseResponseCallback = void Function(Map<String, dynamic> response);

/// Routes each exercise `type` to its interactive module.
class ExerciseModuleRouter extends StatelessWidget {
  const ExerciseModuleRouter({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case 'listening':
        return ListeningModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      case 'multiple_choice':
      case 'image_word':
        return OptionsModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
          leading: question.type == 'image_word'
              ? const _MediaStub(
                  icon: Icons.image_rounded,
                  label: 'تصویر واژه (فاز ۱۲ کامل می‌شود)',
                )
              : null,
        );
      case 'matching':
        return MatchingModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      case 'cloze_typing':
        return ClozeModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      case 'word_bank':
      case 'reorder':
        return OrderBankModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      case 'translation':
        return TranslationModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      case 'speaking':
        return SpeakingModule(
          question: question,
          onSubmitResponse: onSubmitResponse,
        );
      default:
        return UnknownModule(
          type: question.type,
          prompt: question.prompt,
          onSkip: () => onSubmitResponse(const {}),
        );
    }
  }
}

class _MediaStub extends StatelessWidget {
  const _MediaStub({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.vazirmatn(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class ListeningModule extends StatefulWidget {
  const ListeningModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<ListeningModule> createState() => _ListeningModuleState();
}

class _ListeningModuleState extends State<ListeningModule> {
  final _player = MediaPlayer();
  String? _selected;
  String? _playingKey;
  String? _error;

  String? get _audioUrl =>
      widget.question.content['audioUrl']?.toString();
  String? get _slowAudioUrl =>
      widget.question.content['slowAudioUrl']?.toString() ?? _audioUrl;

  List<String> get _options {
    final raw = widget.question.content['options'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String key, String? path) async {
    if (path == null || path.isEmpty) {
      setState(() => _error = 'فایل صوتی موجود نیست');
      return;
    }
    setState(() {
      _error = null;
      _playingKey = key;
    });
    try {
      await _player.stop();
      await _player.playUrl(ApiConfig.resolveMediaUrl(path));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'پخش صوت ناموفق بود');
      }
    } finally {
      if (mounted) setState(() => _playingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _playingKey == 'normal'
                    ? null
                    : () => _play('normal', _audioUrl),
                icon: Icon(
                  _playingKey == 'normal'
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  'پخش',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _playingKey == 'slow'
                    ? null
                    : () => _play('slow', _slowAudioUrl),
                icon: Icon(
                  _playingKey == 'slow'
                      ? Icons.graphic_eq_rounded
                      : Icons.slow_motion_video_rounded,
                ),
                label: Text(
                  'آهسته',
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(color: AppColors.danger, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        ..._options.map((option) {
          final selected = _selected == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selected = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.amberSoft : Colors.white70,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.amber : AppColors.mistDeep,
                    width: 1.6,
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => widget.onSubmitResponse({'correctOption': _selected}),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class OptionsModule extends StatefulWidget {
  const OptionsModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
    this.leading,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;
  final Widget? leading;

  @override
  State<OptionsModule> createState() => _OptionsModuleState();
}

class _OptionsModuleState extends State<OptionsModule> {
  String? _selected;

  List<String> get _options {
    final raw = widget.question.content['options'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.leading != null) widget.leading!,
        ..._options.map((option) {
          final selected = _selected == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selected = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.amberSoft : Colors.white70,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.amber : AppColors.mistDeep,
                    width: 1.6,
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => widget.onSubmitResponse({'correctOption': _selected}),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class MatchingModule extends StatefulWidget {
  const MatchingModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<MatchingModule> createState() => _MatchingModuleState();
}

class _MatchingModuleState extends State<MatchingModule> {
  String? _selectedLeft;
  final Map<String, String> _pairs = {};

  List<String> get _left {
    final raw = widget.question.content['leftItems'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  List<String> get _right {
    final raw = widget.question.content['rightItems'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final remainingRight =
        _right.where((r) => !_pairs.values.contains(r)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'چپ را بزن، بعد راست را وصل کن',
          textAlign: TextAlign.right,
          style: GoogleFonts.vazirmatn(fontSize: 13, color: AppColors.slate),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  children: _left.map((item) {
                    final paired = _pairs[item];
                    final selected = _selectedLeft == item;
                    return _chip(
                      label: paired == null ? item : '$item → $paired',
                      selected: selected || paired != null,
                      onTap: () => setState(() {
                        if (paired != null) {
                          _pairs.remove(item);
                        }
                        _selectedLeft = item;
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListView(
                  children: remainingRight
                      .map(
                        (item) => _chip(
                          label: item,
                          selected: false,
                          onTap: () {
                            if (_selectedLeft == null) return;
                            setState(() {
                              _pairs[_selectedLeft!] = item;
                              _selectedLeft = null;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _pairs.length < _left.length
              ? null
              : () => widget.onSubmitResponse({'pairs': _pairs}),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealSoft : Colors.white70,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.mistDeep,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class ClozeModule extends StatefulWidget {
  const ClozeModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<ClozeModule> createState() => _ClozeModuleState();
}

class _ClozeModuleState extends State<ClozeModule> {
  final _controller = TextEditingController();

  String get _blankId {
    final blanks = widget.question.content['blanks'];
    if (blanks is List && blanks.isNotEmpty) {
      final first = blanks.first;
      if (first is Map && first['id'] != null) return first['id'].toString();
    }
    return 'blank_1';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.question.content['text']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          style: GoogleFonts.dmSans(fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'پاسخ جای خالی',
            labelStyle: GoogleFonts.vazirmatn(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            widget.onSubmitResponse({
              'blanks': {_blankId: _controller.text.trim()},
            });
          },
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class OrderBankModule extends StatefulWidget {
  const OrderBankModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<OrderBankModule> createState() => _OrderBankModuleState();
}

class _OrderBankModuleState extends State<OrderBankModule> {
  late List<String> _bank;
  final List<String> _built = [];

  @override
  void initState() {
    super.initState();
    final raw = widget.question.content['bank'] ??
        widget.question.content['items'];
    _bank = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mistDeep),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _built
                  .map(
                    (t) => ActionChip(
                      label: Text(t, style: GoogleFonts.dmSans()),
                      onPressed: () => setState(() {
                        _built.remove(t);
                        _bank.add(t);
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bank
              .map(
                (t) => ActionChip(
                  label: Text(t, style: GoogleFonts.dmSans()),
                  backgroundColor: AppColors.tealSoft,
                  onPressed: () => setState(() {
                    _bank.remove(t);
                    _built.add(t);
                  }),
                ),
              )
              .toList(),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _built.isEmpty
              ? null
              : () => widget.onSubmitResponse({'order': List<String>.from(_built)}),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class TranslationModule extends StatefulWidget {
  const TranslationModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<TranslationModule> createState() => _TranslationModuleState();
}

class _TranslationModuleState extends State<TranslationModule> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.question.content['source']?.toString() ?? '';
    final direction = widget.question.content['direction']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          direction == 'fa_to_en' ? 'فارسی → انگلیسی' : 'انگلیسی → فارسی',
          textAlign: TextAlign.right,
          style: GoogleFonts.vazirmatn(color: AppColors.slate, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          source,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          textDirection:
              direction == 'en_to_fa' ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'ترجمه شما',
            labelStyle: GoogleFonts.vazirmatn(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => widget.onSubmitResponse({
            'text': _controller.text.trim(),
          }),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class SpeakingModule extends StatefulWidget {
  const SpeakingModule({
    super.key,
    required this.question,
    required this.onSubmitResponse,
  });

  final QuestionModel question;
  final ExerciseResponseCallback onSubmitResponse;

  @override
  State<SpeakingModule> createState() => _SpeakingModuleState();
}

class _SpeakingModuleState extends State<SpeakingModule> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.question.content['targetText']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tealSoft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.tealDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ضبط صوت (STT) بعداً اضافه می‌شود. پاسخ شما توسط سرور نمره‌دهی می‌شود.',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          target,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'متن گفته‌شده (جایگزین موقت ضبط)',
            labelStyle: GoogleFonts.vazirmatn(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => widget.onSubmitResponse({
            'text': _controller.text.trim(),
          }),
          child: Text(
            'ثبت و ادامه',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class UnknownModule extends StatelessWidget {
  const UnknownModule({
    super.key,
    required this.type,
    required this.prompt,
    required this.onSkip,
  });

  final String type;
  final String prompt;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.vazirmatn(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mistDeep),
          ),
          child: Text(
            'نوع ناشناخته [$type] — بدون کرش رد می‌شود',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: onSkip,
          child: Text(
            'رد شدن',
            style: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
