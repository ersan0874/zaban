// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// In-browser audio via HTML5 `<audio>` (no pub package required).
class MediaPlayer {
  html.AudioElement? _audio;

  Future<void> playUrl(String url) async {
    await stop();
    _audio = html.AudioElement(url);
    await _audio!.play();
  }

  Future<void> stop() async {
    _audio?.pause();
    _audio = null;
  }

  void dispose() {
    _audio?.pause();
    _audio = null;
  }
}
