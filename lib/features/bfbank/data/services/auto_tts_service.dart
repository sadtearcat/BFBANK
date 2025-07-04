import 'package:flutter/material.dart';
import 'tts_service.dart';

class AutoTTSService {
  static final AutoTTSService _instance = AutoTTSService._internal();
  factory AutoTTSService() => _instance;
  static AutoTTSService get instance => _instance;
  
  // TtsService 인스턴스 생성
  final TtsService _ttsService = TtsService();
  
  AutoTTSService._internal();

  /// 페이지 진입 시 자동 TTS 기능
  void speakOnPageEnter(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _ttsService.speak(message);
      });
    });
  }

  /// 페이지 종료 시 TTS 중단
  void stopOnPageExit() {
    _ttsService.stop();
  }
} 