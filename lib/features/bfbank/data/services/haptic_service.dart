import 'package:gaimon/gaimon.dart';
import 'dart:async';

/// 햅틱 피드백 서비스
/// React Native CustomVibrationModule과 동일한 패턴 구현
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  Timer? _heartbeatTimer;
  bool _isHeartbeatActive = false;
  bool _isEnabled = true;

  bool get isHeartbeatActive => _isHeartbeatActive;

  /// 햅틱 지원 여부 확인
  Future<bool> canSupportsHaptic() async {
    try {
      // Gaimon으로 간단한 테스트 진동
      Gaimon.selection();
      return true;
    } catch (e) {
      print('Haptic not supported: $e');
      return false;
    }
  }

  /// 햅틱 활성화/비활성화 설정
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopHeartbeat();
    }
  }
  
  /// 인스턴스 getter 추가 (싱글톤 접근용)
  static HapticService get instance => _instance;

  /// React Native CustomVibration과 동일한 패턴으로 진동 실행
  Future<void> vibrateCustomSequence(String name) async {
    if (!_isEnabled) return;

    // 심장박동 상태 관리
    if (name == "heartbeat_start") {
      _isHeartbeatActive = true;
    } else if (name == "heartbeat_stop" || name == "cancel") {
      _isHeartbeatActive = false;
      _heartbeatTimer?.cancel();
    }

    try {
      switch (name.toLowerCase()) {
        // 알림 유형 (강한 진동)
        case 'notification':
          _vibrateNotification();
          break;
        case 'success':
          _vibrateSuccess();
          break;
        case 'error':
          _vibrateError();
          break;
        case 'warning':
          _vibrateWarning();
          break;
        case 'cheerful_success':
          _vibrateCheerfulSuccess();
          break;

        // 상호작용 유형 (중간 강도)
        case 'tick':
          _vibrateTick();
          break;
        case 'double_tick':
          _vibrateDoubleTick();
          break;
        case 'long_press':
          _vibrateLongPress();
          break;

        // 특수 시퀀스
        case 'sos':
          _vibrateSOS();
          break;
        case 'doorbell':
          _vibrateDoorbell();
          break;
        case 'typing':
          _vibrateTyping();
          break;
        case 'camera':
          _vibrateCamera();
          break;
        case 'countdown':
          _vibrateCountdown();
          break;

        // 심장박동 패턴 제어
        case 'heartbeat_start':
          startHeartbeat();
          break;
        case 'heartbeat_stop':
          stopHeartbeat();
          break;

        // 기본값
        default:
          _vibrateNotification();
          break;
      }

      // 심장박동 재개 로직
      if (_isHeartbeatActive && !['heartbeat_start', 'heartbeat_stop', 'cancel'].contains(name.toLowerCase())) {
        final delayTime = _getDelayTime(name);
        Timer(Duration(milliseconds: delayTime), () {
          if (_isHeartbeatActive) {
            _vibrateHeartbeat();
          }
        });
      }
    } catch (e) {
      print('Haptic vibration error: $e');
    }
  }

  /// 패턴별 지연 시간 계산
  int _getDelayTime(String name) {
    switch (name.toLowerCase()) {
      case 'tick':
        return 100;
      case 'double_tick':
        return 200;
      case 'notification':
        return 500;
      case 'success':
        return 300;
      case 'error':
        return 600;
      case 'warning':
        return 1000;
      case 'cheerful_success':
        return 700;
      default:
        return 500;
    }
  }

  // React Native 패턴 구현 - 알림용 진동 패턴: 짧게-긴 진동 (매우 강함)
  void _vibrateNotification() {
    Gaimon.heavy(); // 100ms 강한 진동
    Timer(const Duration(milliseconds: 50), () => Gaimon.heavy()); // 추가 강도
    Timer(const Duration(milliseconds: 100), () {
      Gaimon.heavy(); // 추가 강한 진동
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 150), () => Gaimon.heavy()); // 300ms 효과 - 더 강하게
    });
  }

  // 성공 알림용 진동 패턴: 짧게-짧게-길게 (매우 강함)
  void _vibrateSuccess() {
    Gaimon.heavy(); // 강한 진동으로 변경
    Timer(const Duration(milliseconds: 25), () => Gaimon.heavy());
    Timer(const Duration(milliseconds: 50), () {
      Gaimon.heavy(); // 강한 진동으로 변경
      Timer(const Duration(milliseconds: 25), () => Gaimon.heavy());
    });
    Timer(const Duration(milliseconds: 100), () {
      Gaimon.heavy(); // 150ms 효과 - 더 강하게
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 150), () => Gaimon.heavy());
    });
  }

  // 에러 알림용 진동 패턴: 길게-짧게-길게
  void _vibrateError() {
    Gaimon.heavy(); // 100ms
    Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
    Timer(const Duration(milliseconds: 100), () {
      Gaimon.heavy(); // 100ms
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
    });
    Timer(const Duration(milliseconds: 200), () {
      Gaimon.heavy(); // 300ms 효과
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 150), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 200), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 250), () => Gaimon.heavy());
    });
  }

  // 경고 알림용 진동 패턴: 길게 3번
  void _vibrateWarning() {
    for (int i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: i * 400), () {
        Gaimon.heavy(); // 300ms 효과
        Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
        Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
        Timer(const Duration(milliseconds: 150), () => Gaimon.heavy());
        Timer(const Duration(milliseconds: 200), () => Gaimon.heavy());
        Timer(const Duration(milliseconds: 250), () => Gaimon.heavy());
      });
    }
  }

  // 길게 누르기용 진동 패턴: 중간 강도로 한번 길게
  void _vibrateLongPress() {
    Gaimon.medium(); // 300ms 효과
    Timer(const Duration(milliseconds: 50), () => Gaimon.medium());
    Timer(const Duration(milliseconds: 100), () => Gaimon.medium());
    Timer(const Duration(milliseconds: 150), () => Gaimon.medium());
    Timer(const Duration(milliseconds: 200), () => Gaimon.medium());
    Timer(const Duration(milliseconds: 250), () => Gaimon.medium());
  }

  // 짧은 틱 진동 (버튼 터치 등): 매우 강한 진동으로 변경
  void _vibrateTick() {
    Gaimon.heavy(); // React Native처럼 강한 진동으로 변경
    Timer(const Duration(milliseconds: 25), () => Gaimon.heavy()); // 추가 강도
  }

  // 두 번 연속 강한 틱 진동
  void _vibrateDoubleTick() {
    Gaimon.heavy(); // 강한 진동
    Timer(const Duration(milliseconds: 25), () => Gaimon.heavy()); // 추가 강도
    Timer(const Duration(milliseconds: 150), () {
      Gaimon.heavy(); // 강한 진동
      Timer(const Duration(milliseconds: 25), () => Gaimon.heavy()); // 추가 강도
    });
  }

  // 심장 박동 효과: 짧게-간격-짧게-긴 간격 반복
  void _vibrateHeartbeat() {
    if (!_isHeartbeatActive) return;
    
    Gaimon.light(); // 50ms
    Timer(const Duration(milliseconds: 180), () {
      if (_isHeartbeatActive) {
        Gaimon.light(); // 50ms
      }
    });
    
    // 반복 설정
    if (_isHeartbeatActive) {
      _heartbeatTimer = Timer(const Duration(milliseconds: 730), () {
        if (_isHeartbeatActive) {
          _vibrateHeartbeat();
        }
      });
    }
  }

  // 경쾌한 성공 진동 패턴: 짧게-짧게-길게 올라가는 강도
  void _vibrateCheerfulSuccess() {
    // 빠른 연속 진동으로 경쾌함 표현
    for (int i = 0; i < 7; i++) {
      Timer(Duration(milliseconds: i * 50), () {
        Gaimon.light(); // 10ms 효과
      });
    }
    Timer(const Duration(milliseconds: 400), () {
      // 마지막 강한 진동
      Gaimon.heavy();
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 150), () => Gaimon.heavy());
    });
  }

  // 모스 부호 SOS: ... --- ...
  void _vibrateSOS() {
    // S (...)
    for (int i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: i * 200), () {
        Gaimon.medium(); // 100ms
      });
    }
    Timer(const Duration(milliseconds: 800), () {
      // O (---)
      for (int i = 0; i < 3; i++) {
        Timer(Duration(milliseconds: i * 400), () {
          Gaimon.heavy(); // 300ms 효과
          Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
          Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
        });
      }
    });
    Timer(const Duration(milliseconds: 2000), () {
      // S (...)
      for (int i = 0; i < 3; i++) {
        Timer(Duration(milliseconds: i * 200), () {
          Gaimon.medium(); // 100ms
        });
      }
    });
  }

  // 초인종 스타일 진동
  void _vibrateDoorbell() {
    for (int i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: i * 300), () {
        Gaimon.medium(); // 100ms
        Timer(const Duration(milliseconds: 100), () => Gaimon.heavy()); // 100ms
      });
    }
  }

  // 타이핑 효과 - 여러 번의 짧은 진동
  void _vibrateTyping() {
    for (int i = 0; i < 5; i++) {
      Timer(Duration(milliseconds: i * 50), () {
        Gaimon.light(); // 10ms
      });
    }
  }

  // 카메라 셔터 효과
  void _vibrateCamera() {
    Gaimon.heavy(); // 50ms 강한 진동
  }

  // 카운트다운 효과 (3-2-1)
  void _vibrateCountdown() {
    Gaimon.medium(); // 100ms
    Timer(const Duration(milliseconds: 1000), () {
      Gaimon.medium(); // 100ms (더 강함)
      Timer(const Duration(milliseconds: 25), () => Gaimon.medium());
    });
    Timer(const Duration(milliseconds: 2000), () {
      Gaimon.heavy(); // 100ms (가장 강함)
      Timer(const Duration(milliseconds: 50), () => Gaimon.heavy());
      Timer(const Duration(milliseconds: 100), () => Gaimon.heavy());
    });
  }

  /// 심장박동 시작
  void startHeartbeat() {
    if (!_isEnabled) return;
    _isHeartbeatActive = true;
    _vibrateHeartbeat();
  }

  /// 심장박동 중단
  void stopHeartbeat() {
    _isHeartbeatActive = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 진동 취소
  void cancelVibration() {
    _isHeartbeatActive = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 서비스 정리
  void dispose() {
    stopHeartbeat();
  }
} 