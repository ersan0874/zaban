import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Fx { correct, wrong, combo, complete, tap }

/// Short sound effects + haptics for answer feedback, combos and lesson end.
/// Failures (no audio device, web autoplay rules) are ignored silently.
class FeedbackFx {
  FeedbackFx._();
  static final FeedbackFx instance = FeedbackFx._();

  /// Turned off from the profile settings; kept for the app session.
  static final ValueNotifier<bool> soundOn = ValueNotifier(true);

  final Map<Fx, AudioPlayer> _players = {};

  Future<void> play(Fx fx) async {
    _haptic(fx);
    if (!soundOn.value) return;
    try {
      final player = _players.putIfAbsent(fx, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        p.setReleaseMode(ReleaseMode.stop);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/${fx.name}.wav'));
    } catch (_) {
      // Sound is a nicety; never break the lesson over it.
    }
  }

  void _haptic(Fx fx) {
    switch (fx) {
      case Fx.correct:
        HapticFeedback.lightImpact();
      case Fx.wrong:
        HapticFeedback.heavyImpact();
      case Fx.combo:
      case Fx.complete:
        HapticFeedback.mediumImpact();
      case Fx.tap:
        HapticFeedback.selectionClick();
    }
  }
}
