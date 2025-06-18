import 'package:flutter_tts/flutter_tts.dart';
import 'dart:collection';

enum TtsState { playing, stopped, paused, continued }

/// TTS 큐 아이템
class TtsQueueItem {
  final String text;
  final DateTime timestamp;
  final String? sourcePageId; // 어느 페이지에서 요청했는지 추적

  TtsQueueItem({
    required this.text,
    this.sourcePageId,
  }) : timestamp = DateTime.now();
}

/// 앱 전역에서 TTS를 관리하는 싱글톤 클래스
/// 페이지 전환 중에도 TTS가 지속되도록 보장합니다.
/// 큐 시스템으로 연속적인 음성 안내를 지원합니다.
class GlobalTtsManager {
  static final GlobalTtsManager _instance = GlobalTtsManager._internal();
  factory GlobalTtsManager() => _instance;
  GlobalTtsManager._internal();

  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  bool _isInitialized = false;
  int _activePages = 0; // 활성 페이지 수 추적
  
  // TTS 큐 관리
  final Queue<TtsQueueItem> _ttsQueue = Queue<TtsQueueItem>();
  bool _isProcessingQueue = false;
  
  // 설정 옵션
  bool _enableQueue = false; // 큐 모드 vs 즉시 재생 모드 - 기본값을 false로 변경
  int _maxQueueSize = 10; // 최대 큐 크기
  bool _isEnabled = true; // TTS 활성화/비활성화

  TtsState get ttsState => _ttsState;
  bool get isInitialized => _isInitialized;
  bool get enableQueue => _enableQueue;
  int get queueSize => _ttsQueue.length;
  int get maxQueueSize => _maxQueueSize;

  /// TTS 초기화 (앱 시작 시 한 번만 호출)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    
    // 한국어 설정
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // 이벤트 리스너 설정
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _processNextInQueue(); // TTS 완료 시 큐에서 다음 항목 처리
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      print("Global TTS Error: $msg");
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

    _isInitialized = true;
    print("Global TTS Manager initialized");
  }

  /// 페이지가 TTS를 사용하기 시작할 때 호출
  void registerPage() {
    _activePages++;
    print("Page registered. Active pages: $_activePages");
  }

  /// 페이지가 TTS 사용을 종료할 때 호출
  void unregisterPage() {
    if (_activePages > 0) {
      _activePages--;
    }
    print("Page unregistered. Active pages: $_activePages");
    
    // 모든 페이지가 종료되면 TTS 정리 (앱 종료 시)
    if (_activePages <= 0) {
      _cleanupIfNeeded();
    }
  }

  /// TTS 음성 재생 (큐 모드 지원)
  Future<void> speak(String text, {String? sourcePageId}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (text.isEmpty || !_isEnabled) return;

    final queueItem = TtsQueueItem(text: text, sourcePageId: sourcePageId);

    if (_enableQueue) {
      // 큐 모드: 큐에 추가하고 순서대로 처리
      _addToQueue(queueItem);
      _processNextInQueue();
    } else {
      // 즉시 재생 모드: 기존 방식 (기존 음성 중단하고 새로운 음성 재생)
      if (_ttsState == TtsState.playing) {
        await _flutterTts.stop();
      }
      _clearQueue(); // 큐도 비우기
      await _directSpeak(text);
    }
  }

  /// 큐에 TTS 항목 추가
  void _addToQueue(TtsQueueItem item) {
    // 큐 크기 제한
    while (_ttsQueue.length >= _maxQueueSize) {
      final removed = _ttsQueue.removeFirst();
      final preview = removed.text.length > 20 ? removed.text.substring(0, 20) + "..." : removed.text;
      print("TTS Queue full, removed: $preview");
    }
    
    _ttsQueue.add(item);
    final preview = item.text.length > 20 ? item.text.substring(0, 20) + "..." : item.text;
    print("Added to TTS queue: $preview (Queue size: ${_ttsQueue.length})");
  }

  /// 큐에서 다음 항목 처리
  Future<void> _processNextInQueue() async {
    if (_isProcessingQueue || _ttsQueue.isEmpty || _ttsState == TtsState.playing) {
      return;
    }

    _isProcessingQueue = true;
    
    try {
      final nextItem = _ttsQueue.removeFirst();
      final preview = nextItem.text.length > 20 ? nextItem.text.substring(0, 20) + "..." : nextItem.text;
      print("Processing TTS from queue: $preview");
      await _directSpeak(nextItem.text);
    } catch (error) {
      print("Error processing TTS queue: $error");
      _ttsState = TtsState.stopped;
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// 직접 TTS 재생 (큐 시스템 우회)
  Future<void> _directSpeak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  /// TTS 중단 (긴급 상황에서만 사용)
  Future<void> stop() async {
    if (_isInitialized) {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      _clearQueue(); // 큐도 비우기
      _isProcessingQueue = false;
    }
  }

  /// 큐 비우기
  void _clearQueue() {
    final clearedCount = _ttsQueue.length;
    _ttsQueue.clear();
    if (clearedCount > 0) {
      print("Cleared TTS queue: $clearedCount items removed");
    }
  }

  /// 큐 모드 설정
  void setQueueMode(bool enabled) {
    _enableQueue = enabled;
    print("TTS Queue mode ${enabled ? 'enabled' : 'disabled'}");
    
    if (!enabled) {
      // 즉시 재생 모드로 전환 시 큐 비우기
      _clearQueue();
    }
  }

  /// 최대 큐 크기 설정
  void setMaxQueueSize(int size) {
    _maxQueueSize = size.clamp(1, 20);
    
    // 현재 큐가 새로운 최대 크기보다 크면 조정
    while (_ttsQueue.length > _maxQueueSize) {
      _ttsQueue.removeFirst();
    }
    
    print("TTS max queue size set to: $_maxQueueSize");
  }

  /// 우선순위 높은 TTS (큐 맨 앞에 추가)
  Future<void> speakPriority(String text, {String? sourcePageId}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (text.isEmpty) return;

    if (_enableQueue) {
      // 현재 재생 중이면 중단하고 우선순위 음성 재생
      if (_ttsState == TtsState.playing) {
        await _flutterTts.stop();
      }
      
      // 큐 맨 앞에 추가
      final priorityItem = TtsQueueItem(text: text, sourcePageId: sourcePageId);
      _ttsQueue.addFirst(priorityItem);
      final preview = text.length > 20 ? text.substring(0, 20) + "..." : text;
      print("Added priority TTS: $preview");
      
      _processNextInQueue();
    } else {
      // 즉시 재생 모드와 동일
      await speak(text, sourcePageId: sourcePageId);
    }
  }

  /// TTS 일시정지
  Future<void> pause() async {
    if (_isInitialized) {
      await _flutterTts.pause();
      _ttsState = TtsState.paused;
    }
  }

  /// TTS 재개
  Future<void> resume() async {
    if (_isInitialized && _ttsState == TtsState.paused) {
      // Flutter TTS에서는 resume 대신 continue 사용
      await _flutterTts.stop(); // 현재 상태를 리셋하고 새로 시작
    }
  }

  /// 음성 속도 설정
  Future<void> setSpeechRate(double rate) async {
    if (_isInitialized) {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
    }
  }

  /// 음성 볼륨 설정
  Future<void> setVolume(double volume) async {
    if (_isInitialized) {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    }
  }

  /// 음성 높이 설정
  Future<void> setPitch(double pitch) async {
    if (_isInitialized) {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    }
  }

  /// 사용 가능한 언어 목록
  Future<List<Map>> getAvailableLanguages() async {
    if (!_isInitialized) return [];
    return await _flutterTts.getLanguages ?? [];
  }

  /// 사용 가능한 음성 목록
  Future<List<Map>> getAvailableVoices() async {
    if (!_isInitialized) return [];
    return await _flutterTts.getVoices ?? [];
  }

  /// 언어 사용 가능 여부 확인
  Future<bool> isLanguageAvailable(String language) async {
    if (!_isInitialized) return false;
    return await _flutterTts.isLanguageAvailable(language) ?? false;
  }

  /// TTS 활성화/비활성화 설정
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print("TTS ${enabled ? 'enabled' : 'disabled'}");
    
    if (!enabled && _ttsState == TtsState.playing) {
      // TTS 비활성화 시 현재 재생 중인 음성 중단
      _flutterTts.stop();
    }
  }

  /// 필요시에만 정리 (모든 페이지가 종료된 경우)
  void _cleanupIfNeeded() {
    // 실제로는 앱이 완전히 종료될 때만 정리
    // 일반적인 페이지 전환에서는 TTS를 유지
    print("All pages closed, but keeping TTS alive for app lifecycle");
  }

  /// 앱 종료 시 최종 정리
  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
      _isInitialized = false;
      _activePages = 0;
      print("Global TTS Manager disposed");
    }
  }
} 