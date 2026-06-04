import 'dart:html' as html;
import 'dart:typed_data';

class AudioPlayerHelper {
  static html.AudioElement? _audioElement;
  static String? _currentBlobUrl;

  static void prePlay() {
    try {
      if (_audioElement == null) {
        _audioElement = html.AudioElement();
        // Append to body to ensure it resides in the DOM (needed by some iOS browsers)
        html.document.body?.append(_audioElement!);
      }
      
      _cleanupBlob();

      // Prime the audio element synchronously under the user gesture.
      // We set a tiny silent WAV data URL.
      _audioElement!.src = "data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAAA";
      _audioElement!.load();
      _audioElement!.play().catchError((e) {
        print("Web Audio priming failed/prevented: $e");
      });
    } catch (e) {
      print("Web Audio prePlay error: $e");
    }
  }

  static Future<void> playBytes(Uint8List bytes) async {
    try {
      if (_audioElement == null) {
        prePlay();
      }

      // Convert Uint8List bytes to a Blob
      final blob = html.Blob([bytes], 'audio/mpeg');
      _currentBlobUrl = html.Url.createObjectUrlFromBlob(blob);

      // Set the src of the primed audio element to our blob URL
      _audioElement!.src = _currentBlobUrl!;
      _audioElement!.load();
      await _audioElement!.play();
    } catch (e) {
      print("Web Audio playBytes error: $e");
      rethrow;
    }
  }

  static Future<void> stop() async {
    try {
      if (_audioElement != null) {
        _audioElement!.pause();
        try {
          _audioElement!.currentTime = 0;
        } catch (_) {
          // Ignore if metadata is not loaded yet
        }
      }
      _cleanupBlob();
    } catch (e) {
      print("Web Audio stop error: $e");
    }
  }

  static void _cleanupBlob() {
    if (_currentBlobUrl != null) {
      try {
        if (_audioElement != null && _audioElement!.src == _currentBlobUrl) {
          _audioElement!.src = '';
        }
      } catch (_) {}
      try {
        html.Url.revokeObjectUrl(_currentBlobUrl!);
      } catch (e) {
        // ignore
      }
      _currentBlobUrl = null;
    }
  }
}
