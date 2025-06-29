// 📄 [CORE UTILITY] 손글씨 전처리 엔진 - EMNIST 모델용 이미지 변환
// 역할: 사용자 그리기 데이터를 28x28 텐서로 변환하여 YOLO 모델 입력 준비
// 기능: 무게중심 정렬, 기울기 보정, 동적 선굵기, 앙상블 처리 등 고급 전처리
// 주의: 현재 이중 전처리 문제의 핵심 - Float32List 생성 후 HandwritingModelService에서 다시 PNG 변환
// 사용: DrawingCanvas에서 그리기 완료 시 호출, HandwritingModelService에서 텐서 변환

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

/// 무게중심 정렬, 기울기 보정, 동적 선 굵기를 적용한 향상된 손글씨 전처리기
/// 
/// 🔗 **HandwritingModelService 연관성:**
/// - 📁 핵심 문제: 이 클래스가 이중 전처리의 주범
/// - 🔄 현재 흐름: preprocessStrokesToTensor() → Float32List → HandwritingModelService._convertToRgbPng()
/// - ⚡ 성능 이슈: 복잡한 전처리 → 간단한 Float32List → 다시 복잡한 RGB 변환
/// 
/// 🚨 **CRITICAL ARCHITECTURE ISSUES:**
/// 
/// **1. 이중 전처리의 핵심 원인:**
/// ```dart
/// // 현재 (비효율적):
/// HandwritingPreprocessor.preprocessStrokesToTensor() → Float32List (28x28x1)
/// ↓
/// HandwritingModelService.predictFromFloat32List() 
/// ↓
/// HandwritingModelService._convertToRgbPng() → RGB PNG (28x28x3)
/// ↓
/// YOLO.predict()
/// ```
/// ❌ 문제: 
/// - 1차: 복잡한 무게중심/기울기 보정 → 28x28 Float32List
/// - 2차: Float32List → RGB PNG 변환 (3배 메모리, 품질 손실)
/// ✅ 해결: 직접 PNG 생성 또는 YOLO 직접 호출
/// 
/// **2. 과도한 복잡성 vs 실시간 요구사항:**
/// ```dart
/// _processWithEnhancements() {
///   // 1. 무게중심 계산
///   // 2. PCA 기울기 보정  
///   // 3. 동적 스트로크 굵기
///   // 4. 복잡한 변환 행렬
/// }
/// ```
/// ❌ 문제: 실시간 입력에는 과도한 처리 (200-500ms)
/// ✅ 해결: 실시간용 단순 모드와 정확도용 복잡 모드 분리
/// 
/// **3. Temperature Ensemble 오버헤드:**
/// ```dart
/// _processWithEnsemble() {
///   // 여러 변형 생성 및 평균화
/// }
/// ```
/// ❌ 문제: 앙상블은 정확도 향상이지만 실시간에는 부적합
/// ✅ 해결: 오프라인 배치 처리용으로만 사용
/// 
/// **🔧 [IMMEDIATE FIXES NEEDED]:**
/// 
/// **Fix 1: PNG 직접 생성 메서드 추가 (우선순위: CRITICAL)**
/// ```dart
/// // 새로운 메서드 추가 필요:
/// static Future<Uint8List?> preprocessStrokesToPng(
///   List<DrawingStroke> strokes, {
///   bool enableAdvancedProcessing = false,
///   bool enableGrayscale = true,  // EMNIST용 1채널
/// }) async {
///   // 직접 PNG 바이트 생성하여 이중 전처리 제거
/// }
/// ```
/// 
/// **Fix 2: 실시간 모드 분리 (우선순위: HIGH)**
/// ```dart
/// enum PreprocessingMode {
///   realtime,    // 50-100ms, 기본 전처리만
///   balanced,    // 100-200ms, 무게중심 정렬
///   accuracy,    // 200-500ms, 모든 개선사항
///   ensemble,    // 500ms+, 앙상블 처리
/// }
/// ```
/// 
/// **Fix 3: 메모리 최적화 (우선순위: MEDIUM)**
/// ```dart
/// // 불필요한 중간 변환 제거
/// // Canvas → Image → ByteData → Float32List → PNG 
/// // 단순화: Canvas → PNG (직접)
/// ```
/// 
/// **📊 [PERFORMANCE IMPACT ANALYSIS]:**
/// 
/// **현재 성능 (이중 전처리):**
/// - 전처리 시간: 100-300ms (복잡한 변환)
/// - PNG 변환 시간: 50-150ms (Float32List → RGB)
/// - 총 시간: 150-450ms
/// - 메모리: 28x28x4 (Float32List) + 28x28x3 (RGB) = 7배
/// 
/// **목표 성능 (직접 PNG):**
/// - 전처리 시간: 50-100ms (직접 PNG)
/// - PNG 변환 시간: 0ms
/// - 총 시간: 50-100ms
/// - 메모리: 28x28x1 (Grayscale) = 1배
/// 
/// **🎯 [REQUIRED NEW METHODS]:**
/// 
/// ```dart
/// // 1. 직접 PNG 생성 (이중 전처리 해결)
/// static Future<Uint8List?> preprocessStrokesToPng(List<DrawingStroke> strokes, {...});
/// 
/// // 2. 실시간 모드 (성능 최적화)
/// static Future<Float32List?> preprocessStrokesToTensorRealtime(List<DrawingStroke> strokes);
/// 
/// // 3. 그레이스케일 PNG (EMNIST 최적화)
/// static Future<Uint8List?> preprocessStrokesToGrayscalePng(List<DrawingStroke> strokes);
/// 
/// // 4. 모드별 처리
/// static Future<dynamic> preprocessStrokes(
///   List<DrawingStroke> strokes, 
///   PreprocessingMode mode,
///   OutputFormat format,
/// );
/// ```
/// 
/// **🔗 [FILES THAT WILL BENEFIT]:**
/// - drawing_canvas.dart: 실시간 성능 개선
/// - benchmark_test_page.dart: 성능 측정 정확도 개선  
/// - handwriting_test_page.dart: 정확한 성능 측정
/// - handwriting_model_service.dart: 이중 전처리 제거
/// 
/// **⚠️ [BACKWARD COMPATIBILITY]:**
/// - 기존 preprocessStrokesToTensor() 메서드는 유지
/// - 새로운 메서드들을 점진적으로 도입
/// - 성능 테스트 후 기본값 변경
class HandwritingPreprocessor {
  static const int inputSize = 28;
  static const int targetSize = 14; // 28x28 이미지의 중심점
  
  /// 모든 개선사항을 포함한 메인 전처리 함수
  static Future<Float32List?> preprocessStrokesToTensor(
    List<DrawingStroke> strokes, {
    bool enableAdvancedProcessing = true,
    bool enableTemperatureEnsemble = false,
  }) async {
    if (strokes.isEmpty) return null;

    print('🔄 ${strokes.length}개 스트로크로 향상된 전처리 시작');

    if (enableAdvancedProcessing) {
      if (enableTemperatureEnsemble) {
        return _processWithEnsemble(strokes);
      } else {
        return _processWithEnhancements(strokes);
      }
    } else {
      return _processBasic(strokes);
    }
  }

  /// 4가지 개선사항 모두 적용: 무게중심, 기울기보정, 동적선굵기, 정규화
  static Future<Float32List?> _processWithEnhancements(List<DrawingStroke> strokes) async {
    // 1. 무게중심 계산
    final centerOfMass = _calculateCenterOfMass(strokes);
    print('📍 무게중심: (${centerOfMass.dx.toStringAsFixed(1)}, ${centerOfMass.dy.toStringAsFixed(1)})');

    // 2. PCA를 이용한 기울기 보정 각도 계산
    final deskewAngle = _calculateDeskewAngle(strokes, centerOfMass);
    print('📐 기울기 보정 각도: ${(deskewAngle * 180 / pi).toStringAsFixed(1)}°');

    // 3. 동적 스트로크 굵기 계산
    final dynamicStrokeWidth = _calculateDynamicStrokeWidth(strokes);
    print('✏️ 동적 선 굵기: ${dynamicStrokeWidth.toStringAsFixed(2)}');

    // 4. 적절한 변환으로 이미지 렌더링
    return _renderImage(strokes, centerOfMass, deskewAngle, dynamicStrokeWidth);
  }

  /// 1. 모든 스트로크 포인트의 무게중심 계산
  static Offset _calculateCenterOfMass(List<DrawingStroke> strokes) {
    double sumX = 0.0, sumY = 0.0;
    int totalPoints = 0;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        sumX += point.dx;
        sumY += point.dy;
        totalPoints++;
      }
    }

    return totalPoints > 0 ? Offset(sumX / totalPoints, sumY / totalPoints) : Offset.zero;
  }

  /// 2. 잉크 픽셀에 대한 PCA를 이용한 기울기 보정 각도 계산
  static double _calculateDeskewAngle(List<DrawingStroke> strokes, Offset centerOfMass) {
    final allPoints = <Offset>[];
    for (final stroke in strokes) {
      allPoints.addAll(stroke.points);
    }
    
    if (allPoints.length < 3) return 0.0;

    // 공분산 행렬 요소 계산
    double covXX = 0.0, covXY = 0.0, covYY = 0.0;

    for (final point in allPoints) {
      final dx = point.dx - centerOfMass.dx;
      final dy = point.dy - centerOfMass.dy;
      covXX += dx * dx;
      covXY += dx * dy;
      covYY += dy * dy;
    }

    // 포인트 수로 정규화
    final n = allPoints.length.toDouble();
    covXX /= n;
    covXY /= n;
    covYY /= n;

    // 주성분 각도 계산
    // 가장 큰 고유값의 고유벡터가 주방향을 제공
    double angle;
    if (covXX.abs() < 1e-6 && covYY.abs() < 1e-6) {
      angle = 0.0; // 의미있는 방향성 없음
    } else {
      angle = 0.5 * atan2(2 * covXY, covXX - covYY);
    }

    // 안정성을 위해 ±15도로 제한
    return max(-pi/12, min(pi/12, angle));
  }

  /// 3. 평균 포인트 간격에 기반한 동적 스트로크 굵기 계산
  static double _calculateDynamicStrokeWidth(List<DrawingStroke> strokes) {
    double totalDistance = 0.0;
    int totalSegments = 0;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      
      for (int i = 1; i < stroke.points.length; i++) {
        final distance = (stroke.points[i] - stroke.points[i-1]).distance;
        totalDistance += distance;
        totalSegments++;
      }
    }

    if (totalSegments == 0) return 2.0;
    
    final avgDelta = totalDistance / totalSegments;
    
    // 평균 간격에 기반한 동적 굵기
    // 제안된 0.5 배수 사용
    final dynamicWidth = max(2.0, avgDelta * 0.5);
    
    // 모바일 성능을 위해 합리적인 최대값으로 제한
    return min(6.0, dynamicWidth);
  }

  /// 4. 무게중심 정렬과 기울기 보정으로 이미지 렌더링
  static Future<Float32List?> _renderImage(
    List<DrawingStroke> strokes,
    Offset centerOfMass,
    double deskewAngle,
    double strokeWidth,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // 흰색 배경으로 지우기
    canvas.drawRect(
      Rect.fromLTWH(0, 0, inputSize.toDouble(), inputSize.toDouble()),
      Paint()..color = Colors.white,
    );

    // 올바른 순서로 변환 적용
    canvas.save();
    
    // 1. 이미지를 (14, 14)에서 중앙에 위치시키기 위해 이동
    canvas.translate(targetSize.toDouble(), targetSize.toDouble());
    
    // 2. 기울기 보정을 위해 회전 (음수 각도로 보정)
    canvas.rotate(-deskewAngle);
    
    // 3. 무게중심이 원점이 되도록 이동
    canvas.translate(-centerOfMass.dx, -centerOfMass.dy);

    // 동적 굵기로 스트로크 그리기
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();

    // 텐서로 변환
    final picture = recorder.endRecording();
    final image = await picture.toImage(inputSize, inputSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    
    if (byteData == null) return null;
    
    return _convertToGrayscaleTensor(byteData.buffer.asUint8List());
  }

  /// 4. 다중 변형을 이용한 Temperature Ensemble 처리
  static Future<Float32List?> _processWithEnsemble(List<DrawingStroke> strokes) async {
    print('🌡️ Temperature Ensemble로 처리');
    
    final centerOfMass = _calculateCenterOfMass(strokes);
    final deskewAngle = _calculateDeskewAngle(strokes, centerOfMass);
    final strokeWidth = _calculateDynamicStrokeWidth(strokes);
    
    final ensembleResults = <Float32List>[];
    
    // 9개 변형 생성: ±2° 회전과 ±1px 이동
    final rotations = [-2.0, 0.0, 2.0]; // 각도
    final translations = [Offset(-1, -1), Offset(0, 0), Offset(1, 1)];
    
    for (final rotDeg in rotations) {
      for (final translate in translations) {
        final modifiedAngle = deskewAngle + (rotDeg * pi / 180);
        final modifiedCenter = Offset(
          centerOfMass.dx + translate.dx,
          centerOfMass.dy + translate.dy,
        );
        
        final result = await _renderImage(strokes, modifiedCenter, modifiedAngle, strokeWidth);
        if (result != null) {
          ensembleResults.add(result);
        }
      }
    }
    
    if (ensembleResults.isEmpty) return null;
    
    // 모든 앙상블 결과 평균화
    final averaged = Float32List(inputSize * inputSize);
    for (int i = 0; i < averaged.length; i++) {
      double sum = 0.0;
      for (final result in ensembleResults) {
        sum += result[i];
      }
      averaged[i] = sum / ensembleResults.length;
    }
    
    print('✅ 앙상블 완료: ${ensembleResults.length}개 변형 평균화');
    return averaged;
  }

  /// 폴백용 기본 전처리
  static Future<Float32List?> _processBasic(List<DrawingStroke> strokes) async {
    final bounds = _getCombinedBounds(strokes);
    if (bounds.width == 0 || bounds.height == 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, inputSize.toDouble(), inputSize.toDouble()),
      Paint()..color = Colors.white,
    );

    // 맞춤을 위한 간단한 크기 조정
    final maxDim = max(bounds.width, bounds.height);
    final scale = (inputSize - 4) / maxDim; // 각 면에 2px 패딩
    final offsetX = (inputSize - bounds.width * scale) / 2 - bounds.left * scale;
    final offsetY = (inputSize - bounds.height * scale) / 2 - bounds.top * scale;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final path = Path();
      final firstPoint = _transformPoint(stroke.points.first, offsetX, offsetY, scale);
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final point = _transformPoint(stroke.points[i], offsetX, offsetY, scale);
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(inputSize, inputSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    
    if (byteData == null) return null;
    
    return _convertToGrayscaleTensor(byteData.buffer.asUint8List());
  }

  /// RGBA 바이트를 정규화된 그레이스케일 텐서로 변환
  static Float32List _convertToGrayscaleTensor(Uint8List pixels) {
    final grayscale = Float32List(inputSize * inputSize);
    
    // 첫 번째 패스: 휘도 공식을 사용하여 그레이스케일로 변환
    for (int i = 0; i < inputSize * inputSize; i++) {
      final r = pixels[i * 4];
      final g = pixels[i * 4 + 1];
      final b = pixels[i * 4 + 2];
      
      // 흰색 배경을 0으로, 검은색 잉크를 1로 변환
      // 휘도 공식 사용: 0.299*R + 0.587*G + 0.114*B
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      grayscale[i] = 1.0 - luminance; // 반전: 흰색=0, 검은색=1
    }

    // 정규화를 위한 최대값 찾기
    double maxValue = 0.0;
    int nonZeroPixels = 0;
    for (int i = 0; i < grayscale.length; i++) {
      if (grayscale[i] > 0) {
        maxValue = max(maxValue, grayscale[i]);
        nonZeroPixels++;
      }
    }

    // [0, 1] 범위로 정규화
    if (maxValue > 0) {
      for (int i = 0; i < grayscale.length; i++) {
        grayscale[i] /= maxValue;
      }
    }

    print('📊 0이 아닌 픽셀: $nonZeroPixels / ${grayscale.length}');
    print('📈 최대 그레이스케일 값: ${maxValue.toStringAsFixed(4)}');

    return grayscale;
  }

  /// 헬퍼 메서드들
  static Offset _transformPoint(Offset point, double offsetX, double offsetY, double scale) {
    return Offset(
      point.dx * scale + offsetX,
      point.dy * scale + offsetY,
    );
  }

  static Rect _getCombinedBounds(List<DrawingStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;

    Rect? combinedBounds;
    for (final stroke in strokes) {
      final bounds = stroke.bounds;
      if (bounds != Rect.zero) {
        combinedBounds = combinedBounds?.expandToInclude(bounds) ?? bounds;
      }
    }

    return combinedBounds ?? Rect.zero;
  }

  /// 디버그 헬퍼: 시각화 이미지 생성
  static Future<ui.Image?> createDebugImage(List<DrawingStroke> strokes) async {
    if (strokes.isEmpty) return null;

    final centerOfMass = _calculateCenterOfMass(strokes);
    final deskewAngle = _calculateDeskewAngle(strokes, centerOfMass);
    final strokeWidth = _calculateDynamicStrokeWidth(strokes);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // 더 나은 가시성을 위해 더 큰 디버그 이미지 생성
    final debugSize = 280; // 모델 입력보다 10배 큰 크기
    canvas.scale(10.0); // 모든 것을 확대

    canvas.drawRect(
      Rect.fromLTWH(0, 0, inputSize.toDouble(), inputSize.toDouble()),
      Paint()..color = Colors.white,
    );

    canvas.save();
    canvas.translate(targetSize.toDouble(), targetSize.toDouble());
    canvas.rotate(-deskewAngle);
    canvas.translate(-centerOfMass.dx, -centerOfMass.dy);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    return await picture.toImage(debugSize, debugSize);
  }
} 