import 'package:gaimon/gaimon.dart';
import 'dart:async';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  Timer? _heartbeatTimer;
  bool _isHeartbeatActive = false;

  bool get isHeartbeatActive => _isHeartbeatActive;

  /// React Native의 vibrateCustomSequence와 동일한 기능
  void vibrateCustomSequence(String name) {
    // 심장박동 상태 관리
    if (name == "heartbeat_start") {
      _isHeartbeatActive = true;
    } else if (name == "heartbeat_stop" || name == "cancel") {
      _isHeartbeatActive = false;
      _heartbeatTimer?.cancel();
    }

    switch (name.toLowerCase()) {
      // 알림 유형 (gaimon 기본 제공)
      case "success":
        Gaimon.success();
        break;
      case "error":
        Gaimon.error();
        break;
      case "warning":
        Gaimon.warning();
        break;
      
      // 상호작용 유형
      case "tick":
        Gaimon.light();
        break;
      case "double_tick":
        _vibrateDoubleTick();
        break;
      case "long_press":
        Gaimon.heavy();
        break;
      
      // 알림 (커스텀)
      case "notification":
        _vibrateNotification();
        break;
      case "cheerful_success":
        _vibrateCheerfulSuccess();
        break;
      
      // 특수 시퀀스
      case "camera":
        Gaimon.rigid();
        break;
      case "typing":
        _vibrateTyping();
        break;
      case "countdown":
        _vibrateCountdown();
        break;
      
      // 심장박동 제어
      case "heartbeat_start":
        startHeartbeat();
        break;
      case "heartbeat_stop":
        stopHeartbeat();
        break;
      
      default:
        Gaimon.selection();
        break;
    }

    // 심장박동이 활성화된 경우 다른 진동 후 재개
    if (_isHeartbeatActive && name != "heartbeat_start" && name != "heartbeat_stop") {
      _scheduleHeartbeatResume(name);
    }
  }

  /// 심장박동 시작
  void startHeartbeat() {
    _isHeartbeatActive = true;
    _heartbeatTimer?.cancel();
    
    // 심장박동 패턴: 짧게-간격-짧게-긴 간격 반복
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_isHeartbeatActive) {
        Gaimon.light(); // 첫 번째 박동
        Timer(const Duration(milliseconds: 180), () {
          if (_isHeartbeatActive) {
            Gaimon.light(); // 두 번째 박동
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 심장박동 중지
  void stopHeartbeat() {
    _isHeartbeatActive = false;
    _heartbeatTimer?.cancel();
  }

  /// 진동 취소
  void cancelVibration() {
    _isHeartbeatActive = false;
    _heartbeatTimer?.cancel();
  }

  // === 커스텀 진동 패턴들 ===

  void _vibrateNotification() {
    Gaimon.light();
    Timer(const Duration(milliseconds: 100), () {
      Gaimon.medium();
    });
  }

  void _vibrateDoubleTick() {
    Gaimon.light();
    Timer(const Duration(milliseconds: 150), () {
      Gaimon.light();
    });
  }

  void _vibrateCheerfulSuccess() {
    // 경쾌한 성공 패턴: 점진적으로 강해지는 진동
    Gaimon.light();
    Timer(const Duration(milliseconds: 50), () {
      Gaimon.light();
      Timer(const Duration(milliseconds: 50), () {
        Gaimon.medium();
        Timer(const Duration(milliseconds: 50), () {
          Gaimon.heavy();
        });
      });
    });
  }

  void _vibrateTyping() {
    // 타이핑/로딩 효과: 여러 번의 가벼운 진동
    for (int i = 0; i < 5; i++) {
      Timer(Duration(milliseconds: i * 50), () {
        Gaimon.light();
      });
    }
  }

  void _vibrateCountdown() {
    // 카운트다운: 3-2-1
    Gaimon.light();
    Timer(const Duration(milliseconds: 1000), () {
      Gaimon.medium();
      Timer(const Duration(milliseconds: 1000), () {
        Gaimon.heavy();
      });
    });
  }

  /// 심장박동 재개 스케줄링
  void _scheduleHeartbeatResume(String patternName) {
    final delayTime = _getDelayTimeForPattern(patternName);
    
    Timer(Duration(milliseconds: delayTime), () {
      if (_isHeartbeatActive) {
        startHeartbeat();
      }
    });
  }

  /// 패턴별 지연 시간
  int _getDelayTimeForPattern(String patternName) {
    switch (patternName.toLowerCase()) {
      case "tick":
        return 100;
      case "double_tick":
        return 200;
      case "notification":
        return 500;
      case "success":
        return 300;
      case "error":
        return 600;
      case "warning":
        return 1000;
      case "cheerful_success":
        return 700;
      default:
        return 500;
    }
  }

  /// 심장박동과 함께 다른 진동 실행
  void vibrateWithHeartbeatResume(String patternName) {
    final wasHeartbeatActive = _isHeartbeatActive;
    
    // 현재 진동 중지
    if (_isHeartbeatActive) {
      _heartbeatTimer?.cancel();
    }
    
    // 요청된 진동 실행
    vibrateCustomSequence(patternName);
    
    // 심장박동 재개
    if (wasHeartbeatActive) {
      Timer(const Duration(milliseconds: 1000), () {
        if (_isHeartbeatActive) {
          startHeartbeat();
        }
      });
    }
  }

  /// 햅틱 지원 여부 확인
  Future<bool> canSupportsHaptic() async {
    return Gaimon.canSupportsHaptic;
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _isHeartbeatActive = false;
  }
} 