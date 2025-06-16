import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/crop.dart';
import '../models/ocr_result.dart';
import 'ocr_processing_service.dart';

/// OCR 결과 콜백 함수 타입 (신뢰도 포함)
typedef OnOcrReadyCallback = void Function(Crop crop, OcrResult result);

/// OCR 큐 및 인식 서비스 (분리된 구조)
class OcrQueueService {
  static final OcrQueueService _instance = OcrQueueService._internal();
  factory OcrQueueService() => _instance;
  OcrQueueService._internal();

  // 큐 관련 - 무제한 큐로 변경
  final Queue<Crop> _queue = Queue<Crop>();
  
  // OCR 처리 서비스
  final OcrProcessingService _processingService = OcrProcessingService();
  
  // 콜백 및 상태
  OnOcrReadyCallback? _onOcrReady;
  bool _isProcessing = false;
  bool _isRunning = false;
  
  // 통계
  int _totalProcessed = 0;
  int _totalDropped = 0; // 이제 드롭되지 않지만 호환성을 위해 유지
  int _maxQueueLength = 0; // 최대 큐 길이 추적
  
  /// 현재 큐 길이
  int get queueLength => _queue.length;
  
  /// 총 처리된 항목 수
  int get totalProcessed => _totalProcessed;
  
  /// 총 드롭된 항목 수 (이제 0이 됨)
  int get totalDropped => _totalDropped;
  
  /// 최대 큐 길이
  int get maxQueueLength => _maxQueueLength;
  
  /// 처리 중인지 여부
  bool get isProcessing => _isProcessing;
  
  /// 실행 중인지 여부
  bool get isRunning => _isRunning;

  /// OCR 큐에 크롭 추가 (YOLO 스레드에서 호출) - 무제한 큐로 변경
  bool enqueue(Crop crop) {
    // 큐 크기 제한 제거 - 모든 이미지를 순차적으로 처리
    _queue.add(crop);
    
    // 최대 큐 길이 추적
    if (_queue.length > _maxQueueLength) {
      _maxQueueLength = _queue.length;
    }
    
    print('[OCR_QUEUE] Enqueued: ${crop.debugInfo}, queue: ${_queue.length} (max: $_maxQueueLength)');
    return true;
  }

  /// OCR 큐 처리 시작
  bool start({OnOcrReadyCallback? onOcrReady}) {
    if (_isRunning) {
      print('[OCR_QUEUE] Already running');
      return false;
    }
    
    // OCR 처리 서비스 초기화
    if (!_processingService.initialize()) {
      print('[OCR_QUEUE] Failed to initialize OCR processing service');
      return false;
    }
    
    _onOcrReady = onOcrReady;
    _isRunning = true;
    
    print('[OCR_QUEUE] Started OCR queue processing with Korean script (unlimited queue)');
    
    // 백그라운드에서 큐 처리
    _processQueue();
    return true;
  }

  /// OCR 큐 처리 중지 및 리소스 릴리스
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    // OCR 처리 서비스 해제
    _processingService.dispose();
    
    _queue.clear();
    
    print('[OCR_QUEUE] Stopped OCR queue processing and released resources');
  }

  /// 백그라운드 큐 처리 루프
  Future<void> _processQueue() async {
    while (_isRunning) {
      try {
        if (_queue.isEmpty) {
          // 큐가 비어있으면 잠시 대기
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        
        final crop = _queue.removeFirst();
        _isProcessing = true;
        
        print('[OCR_QUEUE] Processing: ${crop.debugInfo} (remaining: ${_queue.length})');
        
        // OCR 처리 (분리된 서비스 사용)
        final result = await _processingService.processOcr(crop);
        
        // 결과 콜백 호출
        if (_onOcrReady != null && result.isNotEmpty) {
          _onOcrReady!(crop, result);
        }
        
        _totalProcessed++;
        _isProcessing = false;
        
        print('[OCR_QUEUE] Completed: ${crop.debugInfo} -> "${result.text.replaceAll('\n', ' ')}" (${result.displayConfidence})');
        
      } catch (e) {
        _isProcessing = false;
        print('[OCR_QUEUE] Error processing OCR: $e');
        
        // 에러 발생 시 잠시 대기 후 계속
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// 통계 정보 출력
  void printStats() {
    print('[OCR_QUEUE] Stats - Queue: ${_queue.length}, Max: $_maxQueueLength, '
          'Processed: $_totalProcessed, Dropped: $_totalDropped (no longer dropping), '
          'Processing: $_isProcessing');
  }
} 