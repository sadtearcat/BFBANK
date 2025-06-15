import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models/crop.dart';

/// OCR 결과 콜백 함수 타입
typedef OnOcrReadyCallback = void Function(Crop crop, String text);

/// OCR 큐 및 인식 서비스
class OcrQueueService {
  static final OcrQueueService _instance = OcrQueueService._internal();
  factory OcrQueueService() => _instance;
  OcrQueueService._internal();

  // 큐 관련
  final Queue<Crop> _queue = Queue<Crop>();
  static const int _maxQueueSize = 32;
  
  // ML Kit 인식기
  TextRecognizer? _recognizer;
  
  // 콜백 및 상태
  OnOcrReadyCallback? _onOcrReady;
  bool _isProcessing = false;
  bool _isRunning = false;
  
  // 통계
  int _totalProcessed = 0;
  int _totalDropped = 0;
  
  /// 현재 큐 길이
  int get queueLength => _queue.length;
  
  /// 총 처리된 항목 수
  int get totalProcessed => _totalProcessed;
  
  /// 총 드롭된 항목 수
  int get totalDropped => _totalDropped;
  
  /// 처리 중인지 여부
  bool get isProcessing => _isProcessing;
  
  /// 실행 중인지 여부
  bool get isRunning => _isRunning;

  /// OCR 큐에 크롭 추가 (YOLO 스레드에서 호출)
  bool enqueue(Crop crop) {
    if (_queue.length >= _maxQueueSize) {
      // 큐가 가득 차면 가장 오래된 항목 제거
      final dropped = _queue.removeFirst();
      _totalDropped++;
      print('[OCR_QUEUE] Queue full, dropped: ${dropped.debugInfo}');
    }
    
    _queue.add(crop);
    print('[OCR_QUEUE] Enqueued: ${crop.debugInfo}, queue: ${_queue.length}/$_maxQueueSize');
    return true;
  }

  /// OCR 큐 처리 시작
  void start({OnOcrReadyCallback? onOcrReady}) {
    if (_isRunning) {
      print('[OCR_QUEUE] Already running');
      return;
    }
    
    _onOcrReady = onOcrReady;
    _isRunning = true;
    
    // ML Kit Korean Text Recognizer 초기화 (정확한 방식)
    _recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    
    print('[OCR_QUEUE] Started OCR queue processing with Korean script');
    
    // 백그라운드에서 큐 처리
    _processQueue();
  }

  /// OCR 큐 처리 중지 및 리소스 릴리스
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    // ML Kit TextRecognizer 리소스 해제 (close() 호출)
    _recognizer?.close();
    _recognizer = null;
    
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
        
        print('[OCR_QUEUE] Processing: ${crop.debugInfo}');
        
        // OCR 처리
        final text = await _processOcr(crop);
        
        // 결과 콜백 호출
        if (_onOcrReady != null && text.isNotEmpty) {
          _onOcrReady!(crop, text);
        }
        
        _totalProcessed++;
        _isProcessing = false;
        
        print('[OCR_QUEUE] Completed: ${crop.debugInfo} -> "${text.replaceAll('\n', ' ')}"');
        
      } catch (e) {
        _isProcessing = false;
        print('[OCR_QUEUE] Error processing OCR: $e');
        
        // 에러 발생 시 잠시 대기 후 계속
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// 단일 크롭에 대한 OCR 처리 (임시 파일 방식 - 가장 안정적)
  Future<String> _processOcr(Crop crop) async {
    if (_recognizer == null) {
      throw Exception('OCR recognizer not initialized');
    }
    
    File? tempFile;
    try {
      // 임시 파일로 JPEG 저장
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/ocr_temp_${crop.id}.jpg');
      await tempFile.writeAsBytes(crop.jpegBytes);
      
      // 파일에서 InputImage 생성 (가장 안정적인 방법)
      final inputImage = InputImage.fromFile(tempFile);
      
      // ML Kit Korean Text Recognition으로 텍스트 인식
      final RecognizedText recognizedText = await _recognizer!.processImage(inputImage);
      
      String text = recognizedText.text;
      
      // 블록별로 상세 정보 출력 (디버깅용)
      for (TextBlock block in recognizedText.blocks) {
        final String blockText = block.text;
        final List<String> languages = block.recognizedLanguages;
        print('[OCR_DETAIL] Block: "$blockText", Languages: $languages');
        
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            print('[OCR_ELEMENT] "${element.text}"');
          }
        }
      }
      
      print('[OCR_SUCCESS] Korean text recognition completed: "$text"');
      return text.trim();
      
    } catch (e) {
      print('[OCR_QUEUE] OCR processing error: $e');
      return '';
    } finally {
      // 임시 파일 정리
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// 통계 정보 출력
  void printStats() {
    print('[OCR_QUEUE] Stats - Queue: ${_queue.length}/$_maxQueueSize, '
          'Processed: $_totalProcessed, Dropped: $_totalDropped, '
          'Processing: $_isProcessing');
  }
} 