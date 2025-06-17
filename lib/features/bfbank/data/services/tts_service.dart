import 'global_tts_manager.dart';

// TtsState를 다시 export해서 기존 코드 호환성 유지
export 'global_tts_manager.dart' show TtsState;

/// TtsService는 이제 GlobalTtsManager의 래퍼 역할을 합니다.
/// 기존 코드 호환성을 유지하면서 전역 TTS 관리를 제공합니다.
class TtsService {
  final GlobalTtsManager _globalTts = GlobalTtsManager();
  bool _isRegistered = false;

  TtsState get ttsState => _globalTts.ttsState;

  Future<void> initialize() async {
    await _globalTts.initialize();
    if (!_isRegistered) {
      _globalTts.registerPage();
      _isRegistered = true;
    }
  }

  Future<void> speak(String text) async {
    await _globalTts.speak(text);
  }

  Future<void> stop() async {
    await _globalTts.stop();
  }

  Future<void> pause() async {
    await _globalTts.pause();
  }

  Future<bool> isLanguageAvailable(String language) async {
    return await _globalTts.isLanguageAvailable(language);
  }

  Future<List<Map>> getAvailableLanguages() async {
    return await _globalTts.getAvailableLanguages();
  }

  Future<List<Map>> getAvailableVoices() async {
    return await _globalTts.getAvailableVoices();
  }

  Future<void> setSpeechRate(double rate) async {
    await _globalTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    await _globalTts.setVolume(volume);
  }

  Future<void> setPitch(double pitch) async {
    await _globalTts.setPitch(pitch);
  }

  /// TTS 활성화/비활성화 설정
  void setEnabled(bool enabled) {
    _globalTts.setEnabled(enabled);
  }

  /// 페이지별 dispose에서는 TTS를 중단하지 않습니다.
  /// 대신 페이지가 더 이상 TTS를 사용하지 않음을 등록 해제만 합니다.
  void dispose() {
    if (_isRegistered) {
      _globalTts.unregisterPage();
      _isRegistered = false;
    }
  }
} 