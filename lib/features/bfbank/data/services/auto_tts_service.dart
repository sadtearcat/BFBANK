import 'package:flutter/material.dart';
import 'tts_service.dart';

class AutoTTSService {
  static final AutoTTSService _instance = AutoTTSService._internal();
  factory AutoTTSService() => _instance;
  static AutoTTSService get instance => _instance;
  AutoTTSService._internal();

  /// React Native의 useTTSOnFocus와 동일한 기능
  /// 페이지 진입 시 자동으로 TTS 재생
  void speakOnPageEnter(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        TtsService.instance.speak(message);
      });
    });
  }

  /// 페이지 종료 시 TTS 중단
  void stopOnPageExit() {
    TtsService.instance.stop();
  }
} 