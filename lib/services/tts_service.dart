import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  // Azure Neural TTS configuration fields (Pre-configured default credentials)
  static String azureKey = '';
  static String azureRegion = 'koreacentral';
  static String azureVoice = 'en-US-JennyNeural';

  /// Check whether Azure credentials are provided
  static bool get isAzureEnabled =>
      azureKey.trim().isNotEmpty && azureRegion.trim().isNotEmpty;

  /// Initialize Local TTS with English locale and optimal speaking rate for learners.
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45); // Slower speech rate for clear pronunciation guide
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
    await stop();

    if (isAzureEnabled) {
      try {
        final bytes = await _fetchAzureTtsAudio(text);
        if (bytes != null) {
          await _audioPlayer.play(BytesSource(bytes));
          return; // Azure TTS playback started successfully
        }
      } catch (e) {
        print('Azure Neural TTS playback failed ($e). Falling back to local TTS.');
      }
    }

    // Local Fallback Mode
    await init();
    try {
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

    final ssml = '''
<speak version='1.0' xml:lang='en-US'>
  <voice xml:lang='en-US' name='$voice'>
    $escapedText
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
    try {
      await _audioPlayer.stop();
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
