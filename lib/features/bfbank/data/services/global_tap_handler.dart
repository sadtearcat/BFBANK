import 'dart:async';
import 'package:flutter/material.dart';
import 'haptic_service.dart';
import 'tts_service.dart';

class GlobalTapHandler {
  static final GlobalTapHandler _instance = GlobalTapHandler._internal();
  factory GlobalTapHandler() => _instance;
  static GlobalTapHandler get instance => _instance;
  GlobalTapHandler._internal();

  static const int doubleTapDelay = 300; // milliseconds
  int _lastTapTime = 0;
  Timer? _tapTimer;

  /// 전역 탭 핸들러
  /// 한번 탭: TTS 메시지 + tick 진동
  /// 더블탭: 페이지 이동 + double_tick 진동
  void handleTap({
    required String message,
    String? route,
    Map<String, dynamic>? arguments,
    VoidCallback? doubleTapAction,
    required BuildContext context,
  }) {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    if (_lastTapTime != 0 && currentTime - _lastTapTime < doubleTapDelay) {
      // 더블탭 감지
      if (_tapTimer != null) {
        _tapTimer!.cancel();
      }
      
      HapticService.instance.vibrateCustomSequence('double_tick');
      
      // 페이지 이동 또는 콜백 실행
      if (route != null) {
        if (route == 'back') {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushNamed(route, arguments: arguments);
        }
      }
      
      doubleTapAction?.call();
      
    } else {
      // 싱글탭
              HapticService.instance.vibrateCustomSequence('tick');
      TtsService().speak(message);
      
      _tapTimer = Timer(const Duration(milliseconds: doubleTapDelay), () {
        _lastTapTime = 0;
      });
    }
    
    _lastTapTime = currentTime;
  }

  /// 즉시 더블탭 액션 실행 (기존 타이머 무시)
  void forceDoubleTap({
    String? route,
    Map<String, dynamic>? arguments,
    VoidCallback? doubleTapAction,
    required BuildContext context,
  }) {
    HapticService.instance.vibrateCustomSequence('double_tick');
    
    if (route != null) {
      if (route == 'back') {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushNamed(route, arguments: arguments);
      }
    }
    
    doubleTapAction?.call();
  }

  /// 타이머 정리
  void dispose() {
    _tapTimer?.cancel();
  }
} 