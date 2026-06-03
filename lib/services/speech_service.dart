import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _useDemoMode = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
  bool get useDemoMode => _useDemoMode;

  set useDemoMode(bool value) {
    _useDemoMode = value;
  }

  /// Request microphone permission using permission_handler.
  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true; // Permissions are handled by browser prompts

    // speech_to_text needs microphone permission
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final requestStatus = await Permission.microphone.request();
    return requestStatus.isGranted;
  }

  /// Initialize the Speech-to-Text service.
  /// Returns true if successful, false if not supported or failed.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied.');
        _useDemoMode = true;
        return false;
      }

      // Initialize the speech engine
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg} (permanent: ${error.permanent})');
        },
      );

      if (!_isInitialized) {
        debugPrint('Speech recognition is not available on this device. Activating Demo Mode.');
        _useDemoMode = true;
      }
    } catch (e) {
      debugPrint('Speech initialization exception: $e. Activating Demo Mode.');
      _isInitialized = false;
      _useDemoMode = true;
    }

    return _isInitialized;
  }

  /// Starts listening to audio input and returns recognized text.
  Future<void> startListening({
    required Function(String recognizedText, bool isFinal) onResult,
    required Function(String status) onStatus,
    String localeId = 'en_US', // Standard pronunciation practice locale
  }) async {
    if (_useDemoMode) {
      onStatus('listening');
      // Simulate listening in demo mode
      return;
    }

    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onStatus('error');
        return;
      }
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: kIsWeb 
          ? const Duration(seconds: 4) // Web browser speech API needs longer timeout buffer
          : const Duration(milliseconds: 2500),
      localeId: localeId,
      cancelOnError: false, // Prevents transient browser STT errors from shutting down listener completely
      partialResults: true,
    );
    onStatus('listening');
  }

  /// Stops the current listening session and processes whatever was recognized.
  Future<void> stopListening() async {
    if (_useDemoMode) return;
    await _speech.stop();
  }

  /// Cancels the current listening session and discards any input.
  Future<void> cancelListening() async {
    if (_useDemoMode) return;
    await _speech.cancel();
  }

  /// Simulates speech input for testing/fallback purposes.
  void simulateSpeechInput({
    required String targetSentence,
    required double accuracy, // 0.0 to 1.0 accuracy simulation
    required Function(String text, bool isFinal) onResult,
  }) {
    // Generate a simulated spoken text based on target sentence
    final words = targetSentence.split(RegExp(r'\s+'));
    final List<String> simulatedWords = [];

    // Simple simulation: substitute or skip words based on accuracy
    for (var word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()??"“”]'), '');
      if (cleanWord.isEmpty) continue;

      final rand = double.parse((word.hashCode % 100 / 100.0).toStringAsFixed(2));
      
      if (rand < accuracy) {
        // Correct word
        simulatedWords.add(cleanWord);
      } else {
        // Simulate typos or acoustic mishearing
        if (cleanWord.toLowerCase() == 'fox') {
          simulatedWords.add('box');
        } else if (cleanWord.toLowerCase() == 'applications') {
          simulatedWords.add('application');
        } else if (cleanWord.toLowerCase() == 'jumps') {
          simulatedWords.add('jump');
        } else if (cleanWord.toLowerCase() == 'artificial') {
          simulatedWords.add('art');
        } else if (cleanWord.toLowerCase() == 'intelligence') {
          simulatedWords.add('intelligent');
        } else if (cleanWord.length > 3) {
          // General typo: change last character
          simulatedWords.add(cleanWord.substring(0, cleanWord.length - 1));
        } else {
          // Skip word (deletion)
        }
      }
    }

    final simulatedText = simulatedWords.join(' ');
    
    // Simulate speech-to-text incremental update
    Timer(const Duration(milliseconds: 500), () {
      onResult(simulatedText, true);
    });
  }
}
