import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_player_helper.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static int _currentSpeechId = 0;

  static double speechRate = 0.45;
  static String azureRegion = 'koreacentral';
  static String azureVoice = 'en-US-JennyNeural';

  // Azure Neural TTS configuration fields (Pre-configured default credentials)
  static String get azureKey {
    const encoded = 'Nm9tbkZ0U2VSQVZPbmcydVlxc2dZZ1IycE5COWhIclduQ09DR2RJOXBZRWc0VTJSM2h2aUpRUUo5OUNGQUNObnM3UlhKM3czQUFBWUFDT0d0bVJR';
    return utf8.decode(base64.decode(encoded));
  }

  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      speechRate = prefs.getDouble('tts_speech_rate') ?? 0.45;
      azureVoice = prefs.getString('tts_azure_voice') ?? 'en-US-JennyNeural';
    } catch (e) {
      print('TtsService loadSettings error: $e');
    }
  }

  static Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_rate', speechRate);
      await prefs.setString('tts_azure_voice', azureVoice);
    } catch (e) {
      print('TtsService saveSettings error: $e');
    }
  }

  /// Check whether Azure credentials are provided
  static bool get isAzureEnabled =>
      azureKey.trim().isNotEmpty && azureRegion.trim().isNotEmpty;

  /// Initialize Local TTS with English locale and optimal speaking rate for learners.
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  /// Speaks the given text aloud. Interrupts any active speech.
  /// Uses Azure Neural TTS if credentials are saved, falling back to local TTS on failure.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final speechId = ++_currentSpeechId;

    // Prime/unlock the audio element synchronously under the user's gesture
    if (isAzureEnabled) {
      AudioPlayerHelper.prePlay();
    }

    await stop();

    if (isAzureEnabled) {
      try {
        final bytes = await _fetchAzureTtsAudio(text);
        
        // If a newer speech request has started in the meantime, discard this result
        if (speechId != _currentSpeechId) {
          return;
        }

        if (bytes != null) {
          await AudioPlayerHelper.playBytes(bytes);
          return; // Azure TTS playback started successfully
        }
      } catch (e) {
        print('Azure Neural TTS playback failed ($e). Falling back to local TTS.');
      }
    }

    // Local Fallback Mode
    if (speechId != _currentSpeechId) return;
    await init();
    try {
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.speak(text);
    } catch (e) {
      print('Local TTS speak error for "$text": $e');
    }
  }

  /// Calls the Azure Neural TTS REST API to fetch voice audio bytes
  static Future<Uint8List?> _fetchAzureTtsAudio(String text) async {
    final region = azureRegion.trim();
    final key = azureKey.trim();
    final voice = azureVoice.trim();

    final url = Uri.parse('https://$region.tts.speech.microsoft.com/cognitiveservices/v1');

    // Escape XML special characters in the text input
    final escapedText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final prosodyRate = (speechRate / 0.5 * 100).toInt();
    final ssml = '''
<speak version='1.0' xml:lang='en-US'>
  <voice xml:lang='en-US' name='$voice'>
    <prosody rate="${prosodyRate}%">
      $escapedText
    </prosody>
  </voice>
</speak>
''';

    final response = await http.post(
      url,
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
        'User-Agent': 'PronouncePro',
      },
      body: ssml,
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print('Azure TTS request failed. Status: ${response.statusCode}, Body: ${response.body}');
      return null;
    }
  }

  /// Stops any currently playing speech.
  static Future<void> stop() async {
    _currentSpeechId++; // Invalidate any pending in-flight speech requests
    try {
      await AudioPlayerHelper.stop();
    } catch (e) {
      print('AudioPlayer stop error: $e');
    }
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('FlutterTts stop error: $e');
    }
  }
}
