import 'dart:io';

/// Desktop opens the WAV in the default app; mobile uses the system handler.
class MediaPlayer {
  Future<void> playUrl(String url) async {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return;
    }
    if (Platform.isAndroid) {
      await Process.run('am', ['start', '-a', 'android.intent.action.VIEW', '-d', url]);
      return;
    }
    if (Platform.isIOS) {
      await Process.run('open', [url]);
    }
  }

  Future<void> stop() async {}

  void dispose() {}
}
