// 📄 [CORE WIDGET] 손글씨 그리기 캔버스 - 실시간 입력 및 인식 처리
// 역할: 사용자 터치 입력을 받아 스트로크로 변환하고 자동으로 손글씨 인식 수행
// 기능: 제스처 감지(X=삭제, V=완료), 자동 처리 타이머, 점프 감지, 햅틱 피드백
// 성능 이슈: 현재 이중 전처리 문제 - HandwritingPreprocessor → HandwritingModelService 체인
// 사용: HandwritingInputModal에서 메인 입력 위젯으로 사용

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/drawing_stroke.dart';
import '../models/handwriting_prediction.dart';
import '../services/handwriting_model_service.dart';
import '../utils/handwriting_preprocessor.dart';

/// 스트로크 그리기를 위한 커스텀 페인터
class StrokePainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  
  StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      
      // 🔧 FIX: 스마트 연결 렌더링으로 숫자 3 → 8 왜곡 방지
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      
      for (int i = 1; i < stroke.points.length; i++) {
        final currentPoint = stroke.points[i];
        final previousPoint = stroke.points[i - 1];
        
        // 점 사이 거리 계산
        final distance = (currentPoint - previousPoint).distance;
        
        // 🎯 거리 임계값: 너무 큰 점프는 연결하지 않음 (숫자 3의 라인 간 이동)
        const double maxConnectionDistance = 50.0;
        
        if (distance <= maxConnectionDistance) {
          // 정상적인 그리기: 연결
          path.lineTo(currentPoint.dx, currentPoint.dy);
        } else {
          // 큰 점프 감지: 새로운 시작점으로 이동 (펜을 떼고 다시 대는 효과)
          path.moveTo(currentPoint.dx, currentPoint.dy);
        }
      }
      
      canvas.drawPath(path, stroke.paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 손글씨 입력을 위한 메인 드로잉 캔버스 위젯
/// 
/// 🔗 **HandwritingModelService 연관성:**
/// - 📁 주요 연결: handwriting_model_service.dart (Line 206: modelService.predictFromFloat32List())
/// - 🔄 API 흐름: DrawingCanvas → HandwritingPreprocessor → HandwritingModelService → YOLO
/// - ⚡ 성능 이슈: 이중 전처리로 인한 지연 및 메모리 낭비
/// 
/// 🚨 **CRITICAL PERFORMANCE ISSUES:**
/// 
/// **1. 이중 전처리 문제 (Line 186-196):**
/// ```dart
/// final inputTensor = await HandwritingPreprocessor.preprocessStrokesToTensor(...)  // 1차 전처리
/// final prediction = await modelService.predictFromFloat32List(inputTensor);       // 2차 전처리 (내부)
/// ```
/// ❌ 문제: HandwritingPreprocessor가 복잡한 전처리 수행 → Float32List 생성
///          HandwritingModelService가 Float32List → RGB PNG 재변환
/// ✅ 해결: HandwritingPreprocessor에서 직접 PNG 바이트 생성하거나 YOLO 직접 호출
/// 📊 영향: 실시간 성능 저하, 메모리 3배 사용, 품질 손실
/// 
/// **2. 불필요한 복잡성 (Line 186-190):**
/// ```dart
/// enableAdvancedProcessing: true,  // 무게중심 정렬, 기울기 보정, 동적 선 굵기
/// enableTemperatureEnsemble: false, // 실시간 성능을 위해 앙상블 비활성화
/// ```
/// ❌ 문제: 고급 전처리는 정확도 향상이지만 실시간에는 과도
/// ✅ 해결: 실시간용 단순 전처리와 정확도용 복잡 전처리 분리
/// 📊 영향: 사용자 경험, 배터리 수명
/// 
/// **3. API 불일치 (Line 206):**
/// ```dart
/// final prediction = await modelService.predictFromFloat32List(inputTensor);
/// ```
/// ❌ 문제: predictFromFloat32List()는 레거시 호환성 메서드
///          내부에서 recognizeHandwriting() 호출하여 추가 오버헤드
/// ✅ 해결: 직접 PNG 바이트로 YOLO 호출하거나 최적화된 API 사용
/// 📊 영향: 불필요한 메서드 체인, 성능 저하
/// 
/// **🔧 [IMMEDIATE FIXES NEEDED]:**
/// 
/// **Fix 1: 전처리 통합 (우선순위: HIGH)**
/// ```dart
/// // 현재 (비효율적):
/// final inputTensor = await HandwritingPreprocessor.preprocessStrokesToTensor(_strokes, ...);
/// final prediction = await modelService.predictFromFloat32List(inputTensor);
/// 
/// // 수정 후 (효율적):
/// final imageBytes = await HandwritingPreprocessor.preprocessStrokesToPng(_strokes, ...);
/// final prediction = await modelService.predictFromImageBytes(imageBytes);
/// ```
/// 
/// **Fix 2: 실시간 최적화 (우선순위: MEDIUM)**
/// ```dart
/// // 실시간용 단순 전처리 옵션 추가
/// final inputTensor = await HandwritingPreprocessor.preprocessStrokesToTensor(
///   _strokes,
///   enableAdvancedProcessing: false,  // 실시간에는 기본 전처리만
///   enableTemperatureEnsemble: false,
/// );
/// ```
/// 
/// **Fix 3: 제스처 감지 최적화 (우선순위: LOW)**
/// ```dart
/// // 제스처 감지를 별도 유틸리티로 분리
/// final gestureResult = GestureDetector.detectFromStrokes(_strokes);
/// ```
/// 
/// **📊 [PERFORMANCE METRICS]:**
/// - 현재 처리 시간: ~200-500ms (이중 전처리)
/// - 목표 처리 시간: ~50-100ms (단일 전처리)
/// - 메모리 사용: 현재 3배 → 목표 1배
/// - 품질 손실: RGB 변환으로 인한 정보 손실
/// 
/// **🔗 [RELATED FILES TO UPDATE]:**
/// - benchmark_test_page.dart: 비효율적인 파이프라인 벤치마크 문제
/// - handwriting_test_page.dart: 비효율적인 파이프라인 테스트
/// - handwriting_model_service.dart: predictFromFloat32List() 최적화 필요
/// - handwriting_preprocessor.dart: PNG 직접 생성 기능 추가 필요
class DrawingCanvas extends StatefulWidget {
  final Function(HandwritingPrediction)? onPrediction;
  final VoidCallback? onClear;
  final VoidCallback? onDrawingStart;  // 🔧 ADD: 그리기 시작 콜백
  final VoidCallback? onDrawingEnd;    // 🔧 ADD: 그리기 종료 콜백
  final bool isVisible;
  final Duration autoProcessDelay;
  final double? width;
  final double? height;

  const DrawingCanvas({
    Key? key,
    this.onPrediction,
    this.onClear,
    this.onDrawingStart,
    this.onDrawingEnd,
    this.isVisible = true,
    this.autoProcessDelay = const Duration(milliseconds: 1000),
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<DrawingStroke> _strokes = [];
  DrawingStroke? _currentStroke;
  Timer? _autoProcessTimer;
  bool _isProcessing = false;
  Offset? _lastPoint;
  HandwritingPrediction? _latestPrediction;
  
  // 점프 감지 (React Native 구현과 유사)
  static const double maxJumpDistance = 100.0;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _autoProcessTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    final modelService = HandwritingModelService();
    if (!modelService.isReady) {
      await modelService.initialize();
    }
  }

  /// 스트로크 페인트 설정 생성
  Paint _createStrokePaint() {
    return Paint()
      ..color = Colors.black  // 흰색 배경에 검은색 선으로 변경
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  /// 터치 시작 처리
  void _handlePanStart(DragStartDetails details) {
    _cancelAutoProcessTimer();
    
    final point = details.localPosition;
    _lastPoint = point;
    
    _currentStroke = DrawingStroke(
      points: [point],
      paint: _createStrokePaint(),
    );
    
    setState(() {
      _strokes.add(_currentStroke!);
    });

    // 스트로크 시작 시 햅틱 피드백
    HapticFeedback.lightImpact();
    
    // 🔧 ADD: 그리기 시작 콜백 호출
    widget.onDrawingStart?.call();
  }

  /// 터치 이동 처리
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    
    final point = details.localPosition;
    
    // 점프 감지 - 마지막 점에서 너무 먼 점들은 무시
    if (_lastPoint != null) {
      final distance = (point - _lastPoint!).distance;
      if (distance > maxJumpDistance) {
        return; // 이 점을 무시
      }
    }
    
    _lastPoint = point;
    
    // 현재 스트로크 업데이트
    _currentStroke = _currentStroke!.addPoint(point);
    
    setState(() {
      _strokes[_strokes.length - 1] = _currentStroke!;
    });
  }

  /// 터치 종료 처리
  void _handlePanEnd(DragEndDetails details) {
    if (_currentStroke == null) return;
    
    // 현재 스트로크 마무리
    final finalizedStroke = _currentStroke!.copyWith();
    setState(() {
      _strokes[_strokes.length - 1] = finalizedStroke;
    });
    
    _currentStroke = null;
    _lastPoint = null;
    
    // 스트로크 종료 시 가벼운 햅틱 피드백
    HapticFeedback.selectionClick();
    
    // 🔧 ADD: 그리기 종료 콜백 호출
    widget.onDrawingEnd?.call();
    
    // 자동 처리 타이머 시작
    _startAutoProcessTimer();
  }

  /// 자동 처리를 위한 타이머 시작
  void _startAutoProcessTimer() {
    _cancelAutoProcessTimer();
    _autoProcessTimer = Timer(widget.autoProcessDelay, () {
      _processStrokes();
    });
  }

  /// 자동 처리 타이머 취소
  void _cancelAutoProcessTimer() {
    _autoProcessTimer?.cancel();
    _autoProcessTimer = null;
  }

  Future<void> _processStrokes() async {
    if (_strokes.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _latestPrediction = null;
    });

    try {
      final modelService = HandwritingModelService();
      
      // 🔍 [DEBUG] 원본 스트로크 데이터 확인
      print('🔍 === 원본 스트로크 데이터 분석 ===');
      for (int i = 0; i < _strokes.length; i++) {
        final stroke = _strokes[i];
        final bounds = stroke.bounds;
        print('스트로크 $i: ${stroke.points.length}개 점');
        print('  경계상자: (${bounds.left.toStringAsFixed(1)}, ${bounds.top.toStringAsFixed(1)}) ~ (${bounds.right.toStringAsFixed(1)}, ${bounds.bottom.toStringAsFixed(1)})');
        print('  크기: ${bounds.width.toStringAsFixed(1)} x ${bounds.height.toStringAsFixed(1)}');
        
        // 🎨 [DEBUG] 스트로크 경로 시각화 (더 자세히)
        print('  터치 경로:');
        final stepSize = (stroke.points.length / 10).ceil(); // 최대 10개 점만 출력
        for (int j = 0; j < stroke.points.length; j += stepSize) {
          final point = stroke.points[j];
          print('    ${(j / stroke.points.length * 100).toStringAsFixed(0)}%: (${point.dx.toStringAsFixed(1)}, ${point.dy.toStringAsFixed(1)})');
        }
        // 마지막 점도 출력
        if (stroke.points.isNotEmpty) {
          final lastPoint = stroke.points.last;
          print('    100%: (${lastPoint.dx.toStringAsFixed(1)}, ${lastPoint.dy.toStringAsFixed(1)})');
        }
      }
      
      // ✅ 기본 전처리 사용 (좌표 변환 문제 해결)
      final inputTensor = await HandwritingPreprocessor.preprocessStrokesToTensor(
        _strokes,
        enableAdvancedProcessing: false,  // ✅ 기본 처리로 변경 (좌표 스케일링 적용)
        enableTemperatureEnsemble: false, // 실시간 성능을 위해 앙상블 비활성화
      );
      
      if (inputTensor == null) {
        print('⚠️ Failed to preprocess strokes');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      print('✅ Recognized digit: ${_latestPrediction?.digit}');

      // Get prediction from model
      final prediction = await modelService.predictFromFloat32List(inputTensor);
      
      if (prediction != null) {
        setState(() {
          _latestPrediction = prediction;
        });

        // Handle prediction
        _handlePrediction(prediction);
      }
    } catch (e) {
      print('❌ Processing error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Detects special gestures (X for delete, V for complete)
  HandwritingPrediction? _detectGesture(List<DrawingStroke> strokes) {
    if (strokes.isEmpty) return null;

    // Simple X gesture detection
    if (_isXGesture(strokes)) {
      return HandwritingPrediction.success(
        digit: 'delete', 
        confidence: 1.0, 
        threshold: 0.7,
      );
    }

    // Simple V gesture detection  
    if (_isVGesture(strokes)) {
      return HandwritingPrediction.success(
        digit: 'complete', 
        confidence: 1.0, 
        threshold: 0.7,
      );
    }

    return null;
  }

  /// Simple X gesture detection
  bool _isXGesture(List<DrawingStroke> strokes) {
    if (strokes.length != 2) return false;
    
    final stroke1 = strokes[0];
    final stroke2 = strokes[1];
    
    if (stroke1.points.length < 2 || stroke2.points.length < 2) return false;
    
    // Check if the two strokes form an X shape
    final start1 = stroke1.points.first;
    final end1 = stroke1.points.last;
    final start2 = stroke2.points.first;
    final end2 = stroke2.points.last;
    
    // Simple diagonal check
    final isStroke1Diagonal = (end1.dx - start1.dx).abs() > 20 && (end1.dy - start1.dy).abs() > 20;
    final isStroke2Diagonal = (end2.dx - start2.dx).abs() > 20 && (end2.dy - start2.dy).abs() > 20;
    
    return isStroke1Diagonal && isStroke2Diagonal;
  }

  /// Simple V gesture detection
  bool _isVGesture(List<DrawingStroke> strokes) {
    if (strokes.length != 2) return false;
    
    final stroke1 = strokes[0];
    final stroke2 = strokes[1];
    
    if (stroke1.points.length < 2 || stroke2.points.length < 2) return false;
    
    // Check if strokes form a V shape (both going down from a common area)
    final start1 = stroke1.points.first;
    final end1 = stroke1.points.last;
    final start2 = stroke2.points.first;
    final end2 = stroke2.points.last;
    
    // Simple V check: both strokes should go downward
    final isStroke1Downward = end1.dy > start1.dy;
    final isStroke2Downward = end2.dy > start2.dy;
    
    return isStroke1Downward && isStroke2Downward;
  }

  /// Handles prediction
  void _handlePrediction(HandwritingPrediction prediction) {
    if (prediction.digit == 'delete') {
      _deleteLastDigit();
    } else if (prediction.digit == 'complete') {
      // Clear after completing
      _clearCanvas();
    } else {
      widget.onPrediction?.call(prediction);
    }
  }

  /// Deletes the last digit (removes last stroke)
  void _deleteLastDigit() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      HapticFeedback.mediumImpact();
    }
  }

  /// Clears the entire canvas
  void _clearCanvas() {
    setState(() {
      _strokes.clear();
    });
    _currentStroke = null;
    _lastPoint = null;
    widget.onClear?.call();
  }

  /// Manual process trigger (for testing)
  void processNow() {
    _cancelAutoProcessTimer();
    _processStrokes();
  }

  /// Get current strokes (for testing)
  List<DrawingStroke> getStrokes() {
    return List.from(_strokes);
  }

  /// Clear canvas programmatically
  void clearCanvas() {
    _clearCanvas();
  }

  /// Get image data as 28x28 Float32List for recognition
  Future<Float32List?> getImageData() async {
    if (_strokes.isEmpty) {
      return null;
    }

    try {
      // 스트로크를 28x28 Float32List로 변환
      final tensorData = await HandwritingPreprocessor.preprocessStrokesToTensor(
        _strokes,
        enableAdvancedProcessing: false,  // ✅ 기본 처리로 변경 (좌표 스케일링 적용)
        enableTemperatureEnsemble: false,
      );
      
      return tensorData;
    } catch (e) {
      print('❌ Failed to get image data: $e');
      return null;
    }
  }

  /// Clear the canvas (alias for compatibility)
  void clear() {
    clearCanvas();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Drawing area
          GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: CustomPaint(
              painter: StrokePainter(_strokes),
              size: Size.infinite,
            ),
          ),
          
          // Loading indicator
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          
          // Debug info (only in debug mode)
          if (kDebugMode)
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strokes: ${_strokes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'Processing: $_isProcessing',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'Model Ready: ${HandwritingModelService().isReady}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 