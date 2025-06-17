import 'package:shared_preferences/shared_preferences.dart';

/// 설정 영구 저장 서비스
class SettingsStorageService {
  static const String _keyTtsEnabled = 'tts_enabled';
  static const String _keyHapticEnabled = 'haptic_enabled';
  static const String _keyVoiceGuidanceOnPageEnter = 'voice_guidance_on_page_enter';
  static const String _keyAutoLogin = 'auto_login';
  static const String _keySpeechRate = 'speech_rate';
  static const String _keyVolume = 'volume';
  static const String _keyTtsQueueMode = 'tts_queue_mode';
  static const String _keyTtsMaxQueueSize = 'tts_max_queue_size';

  /// 설정 저장
  static Future<bool> saveSettings({
    required bool ttsEnabled,
    required bool hapticEnabled,
    required bool voiceGuidanceOnPageEnter,
    required bool autoLogin,
    required double speechRate,
    required double volume,
    required bool ttsQueueMode,
    required int ttsMaxQueueSize,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool(_keyTtsEnabled, ttsEnabled),
        prefs.setBool(_keyHapticEnabled, hapticEnabled),
        prefs.setBool(_keyVoiceGuidanceOnPageEnter, voiceGuidanceOnPageEnter),
        prefs.setBool(_keyAutoLogin, autoLogin),
        prefs.setDouble(_keySpeechRate, speechRate),
        prefs.setDouble(_keyVolume, volume),
        prefs.setBool(_keyTtsQueueMode, ttsQueueMode),
        prefs.setInt(_keyTtsMaxQueueSize, ttsMaxQueueSize),
      ]);
      
      print('Settings saved successfully');
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// 설정 불러오기
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'ttsEnabled': prefs.getBool(_keyTtsEnabled) ?? true,
        'hapticEnabled': prefs.getBool(_keyHapticEnabled) ?? true,
        'voiceGuidanceOnPageEnter': prefs.getBool(_keyVoiceGuidanceOnPageEnter) ?? true,
        'autoLogin': prefs.getBool(_keyAutoLogin) ?? false,
        'speechRate': prefs.getDouble(_keySpeechRate) ?? 0.5,
        'volume': prefs.getDouble(_keyVolume) ?? 1.0,
        'ttsQueueMode': prefs.getBool(_keyTtsQueueMode) ?? false, // 기본값 false로 설정
        'ttsMaxQueueSize': prefs.getInt(_keyTtsMaxQueueSize) ?? 5,
      };
    } catch (e) {
      print('Error loading settings: $e');
      // 에러 시 기본값 반환
      return _getDefaultSettings();
    }
  }

  /// 기본 설정값 반환
  static Map<String, dynamic> _getDefaultSettings() {
    return {
      'ttsEnabled': true,
      'hapticEnabled': true,
      'voiceGuidanceOnPageEnter': true,
      'autoLogin': false,
      'speechRate': 0.5,
      'volume': 1.0,
      'ttsQueueMode': false, // 기본값 false
      'ttsMaxQueueSize': 5,
    };
  }

  /// 설정 초기화
  static Future<bool> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove(_keyTtsEnabled),
        prefs.remove(_keyHapticEnabled),
        prefs.remove(_keyVoiceGuidanceOnPageEnter),
        prefs.remove(_keyAutoLogin),
        prefs.remove(_keySpeechRate),
        prefs.remove(_keyVolume),
        prefs.remove(_keyTtsQueueMode),
        prefs.remove(_keyTtsMaxQueueSize),
      ]);
      
      print('Settings reset successfully');
      return true;
    } catch (e) {
      print('Error resetting settings: $e');
      return false;
    }
  }

  /// 특정 설정 저장
  static Future<bool> saveBoolSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      return true;
    } catch (e) {
      print('Error saving bool setting $key: $e');
      return false;
    }
  }

  static Future<bool> saveDoubleSetting(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
      return true;
    } catch (e) {
      print('Error saving double setting $key: $e');
      return false;
    }
  }

  static Future<bool> saveIntSetting(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
      return true;
    } catch (e) {
      print('Error saving int setting $key: $e');
      return false;
    }
  }

  /// 설정 존재 여부 확인
  static Future<bool> hasSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyTtsEnabled);
    } catch (e) {
      return false;
    }
  }
} 