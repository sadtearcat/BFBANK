import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;

  TtsState get ttsState => _ttsState;

  Future<void> initialize() async {
    _flutterTts = FlutterTts();
    
    // 한국어 설정
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5); // 속도 (0.0 ~ 1.0)
    await _flutterTts.setVolume(1.0); // 볼륨 (0.0 ~ 1.0)
    await _flutterTts.setPitch(1.0); // 음성 높이 (0.5 ~ 2.0)

    // 이벤트 리스너 설정
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      print("TTS Error: $msg");
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
    });

    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.continued;
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
  }

  Future<bool> isLanguageAvailable(String language) async {
    return await _flutterTts.isLanguageAvailable(language) ?? false;
  }

  Future<List<Map>> getAvailableLanguages() async {
    return await _flutterTts.getLanguages ?? [];
  }

  Future<List<Map>> getAvailableVoices() async {
    return await _flutterTts.getVoices ?? [];
  }

  void dispose() {
    _flutterTts.stop();
  }
} 