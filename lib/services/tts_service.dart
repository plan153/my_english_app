import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_player_helper.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static int _currentSpeechId = 0;

  static double speechRate = 0.45;
  static String azureRegion = 'koreacentral';
  static String azureVoice = 'en-US-AriaNeural';

  // Azure Neural TTS configuration fields (Pre-configured default credentials)
  static String get azureKey {
    const encoded = 'Nm9tbkZ0U2VSQVZPbmcydVlxc2dZZ1IycE5COWhIclduQ09DR2RJOXBZRWc0VTJSM2h2aUpRUUo5OUNGQUNObnM3UlhKM3czQUFBWUFDT0d0bVJR';
    return utf8.decode(base64.decode(encoded));
  }

  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      speechRate = prefs.getDouble('tts_speech_rate') ?? 0.45;
      azureVoice = prefs.getString('tts_azure_voice') ?? 'en-US-AriaNeural';
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

    // 이 요청의 ID 확보. (stop()은 더 이상 카운터를 증가시키지 않으므로
    // 이후 가드는 "더 새로운 speak 호출이 있었는가"만 정확히 판별한다.)
    final speechId = ++_currentSpeechId;

    // 웹: Azure REST 엔드포인트는 브라우저 CORS 정책상 호출이 차단되므로
    // 브라우저 내장 TTS(flutter_tts → SpeechSynthesis)를 직접 사용한다.
    //
    // 주의: Chrome에는 speechSynthesis.cancel() 직후 곧바로 speak()를 호출하면
    // 새 발화가 무시되어 소리가 나지 않는 버그가 있다. 따라서 stop()(=cancel)
    // 이후 짧은 지연을 두고 speak()를 호출한다.
    if (kIsWeb) {
      await init();
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 150));
      if (speechId != _currentSpeechId) return;
      try {
        await _flutterTts.setSpeechRate(speechRate);
        await _flutterTts.speak(text);
      } catch (e) {
        print('Web TTS speak error for "$text": $e');
      }
      return;
    }

    // 네이티브: 사용자 제스처 컨텍스트에서 오디오 엘리먼트를 동기적으로 언락
    if (isAzureEnabled) {
      AudioPlayerHelper.prePlay();
    }

    await stop();

    if (isAzureEnabled) {
      try {
        final bytes = await _fetchAzureTtsAudio(text);
        if (speechId != _currentSpeechId) return;
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
    await _speakLocal(text);
  }

  /// 기기 내장 TTS로 재생한다 (웹: 브라우저 SpeechSynthesis, 네이티브: 플랫폼 TTS).
  static Future<void> _speakLocal(String text) async {
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
  ///
  /// 주의: 여기서 _currentSpeechId를 증가시키면 안 된다. speak()가 내부에서
  /// stop()을 호출하므로, 증가시키면 자기 자신의 speechId 가드가 깨져
  /// 재생 직전에 항상 return 되는 버그가 발생한다. ID 무효화는 speak() 진입 시
  /// (++_currentSpeechId) 한 곳에서만 수행한다.
  static Future<void> stop() async {
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
