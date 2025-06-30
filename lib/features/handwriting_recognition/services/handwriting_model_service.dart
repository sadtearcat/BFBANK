import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../models/handwriting_prediction.dart';

/// 손글씨 인식 모델 서비스 - YOLO 기반 (업스케일링 포함)
/// 
/// 🎯 **궁극적인 목표: 1채널 그레이스케일 Classification 지원**
/// 
/// 🚨 **현재 가장 큰 문제:**
/// - 원본 YOLO 플러그인은 3채널 RGB Classification만 지원
/// - EMNIST 손글씨 모델은 1채널 그레이스케일 입력 필요
/// - 3채널 → 1채널 변환 시 정보 손실 및 성능 저하
/// - TensorFlow Lite 모델 입력 텐서 형태 불일치 ([1,28,28,1] vs [1,28,28,3])
/// 
/// 📋 **단계별 접근 전략:**
/// 
/// **1차 목표 (현재): 내 손글씨 인식 구현**
/// - 원본 YOLO 플러그인으로 일단 작동하도록 만들기
/// - 3채널 RGB 비효율성 감수하고 기본 기능 확보
/// - EMNIST 라벨 매핑 (10→✓, 11→✗) 구현
/// - 최소한의 전처리로 인식 가능한 수준 달성
/// 
/// **2차 목표 (로컬 패키지): 1채널 지원 추가**
/// - Classifier.kt에 1채널 그레이스케일 전용 파이프라인 구현
/// - ImageUtils.kt에 효율적인 전처리 함수들 추가
/// - YOLOPlugin.kt에서 모델 입력 채널 수 자동 감지
/// - YOLO.kt에서 1채널/3채널 분기 처리
/// 
/// **3차 목표 (오픈소스 기여): 범용 옵션화**
/// - ClassifierOptions로 전처리 옵션들 일반화
/// - 다양한 1채널 모델 지원 (MNIST, EMNIST, 커스텀 등)
/// - 성능 최적화 및 메모리 사용량 개선
/// - Ultralytics 커뮤니티에 기여
/// 
/// 📁 **연관된 파일들 및 수정 필요 사항:**
/// 
/// **🔧 [CRITICAL FIXES NEEDED] 핵심 수정 필요 파일들:**
/// 
/// 1. **handwriting_preprocessor.dart** (BFBANK/lib/features/handwriting_recognition/utils/)
///    ❌ 문제: 복잡한 전처리 → Float32List → 다시 RGB PNG 변환 (이중 전처리)
///    ✅ 수정: HandwritingPreprocessor에서 직접 PNG 생성하거나 YOLO 직접 호출
///    📊 영향: drawing_canvas.dart, benchmark_test_page.dart
/// 
/// 2. **drawing_canvas.dart** (BFBANK/lib/features/handwriting_recognition/widgets/)
///    ❌ 문제: predictFromFloat32List() 사용 → 내부에서 Float32List→RGB PNG 변환
///    ✅ 수정: 직접 이미지 바이트로 YOLO 호출하거나 전처리 통합
///    📊 영향: 모든 실시간 손글씨 인식 기능
/// 
/// 3. **benchmark_test_page.dart** (BFBANK/lib/features/handwriting_recognition/widgets/)
///    ❌ 문제: 벤치마크가 비효율적인 이중 전처리를 측정
///    ✅ 수정: 실제 최적화된 파이프라인 벤치마크로 변경
///    📊 영향: 성능 측정 정확도
/// 
/// 4. **handwriting_test_page.dart** (BFBANK/lib/features/handwriting_recognition/widgets/)
///    ❌ 문제: 테스트가 비효율적인 파이프라인 기반
///    ✅ 수정: 최적화된 파이프라인 테스트로 업데이트
///    📊 영향: 개발 디버깅 및 테스트
/// 
/// **🏗️ [ARCHITECTURE FIXES] 아키텍처 수정 필요:**
/// 
/// 5. **pubspec.yaml** (BFBANK/)
///    ⚠️ 현재: ultralytics_yolo: ^0.1.26 (원본 플러그인)
///    🔄 옵션 A: 로컬 패키지로 교체 (path: packages/ultralytics_yolo)
///    🔄 옵션 B: 로컬 YOLO 패키지 개발로 근본적 해결
///    📊 영향: 전체 의존성 구조
/// 
/// 6. **handwriting_recognition.dart** (BFBANK/lib/features/handwriting_recognition/)
///    ❌ 문제: export 구조가 현재 파이프라인 기반
///    ✅ 수정: 최적화된 API export로 변경
///    📊 영향: 다른 모듈에서의 import
/// 
/// **🔀 [ALTERNATIVE APPROACH] 대안 접근법:**
/// 
/// 7. **로컬 YOLO 패키지 개발** (packages/ultralytics_yolo/)
///    ✅ 장점: 기존 YOLO 기반, 커스텀 ClassifierOptions 추가 가능
///    ❌ 단점: 복잡한 6파일 수정, 유기적 연결 구조
///    🔄 선택: 단계별 개발 (1차: 기본 작동, 2차: 1채널 지원, 3차: 오픈소스)
///    📊 영향: 전체 손글씨 인식 아키텍처
/// 
/// **📊 [PERFORMANCE ISSUES] 성능 문제들:**
/// 
/// 8. **handwriting_preprocessor.dart** (BFBANK/lib/features/handwriting_recognition/utils/)
///    ❌ 문제: 복잡한 앙상블 전처리가 실시간 성능에 부적합
///    ✅ 수정: 실시간용 단순 전처리와 정확도용 복잡 전처리 분리
///    📊 영향: 사용자 경험 및 배터리 수명
/// 
/// 9. **drawing_stroke.dart** (BFBANK/lib/features/handwriting_recognition/models/)
///     ⚠️ 현재: 제스처 감지 기능 포함
///     🔄 고려: 제스처 감지를 별도 유틸리티로 분리
///     📊 영향: 코드 구조화 및 재사용성
/// 
/// **🎯 [INTEGRATION FIXES] 통합 수정 필요:**
/// 
/// 10. **handwriting_input_modal.dart** (BFBANK/lib/features/handwriting_recognition/widgets/)
///     ⚠️ 현재: drawing_canvas.dart 의존
///     🔄 고려: 최적화된 파이프라인 적용
///     📊 영향: 모달 방식 입력 성능
/// 
/// **🔬 [TENSOR FORMAT INVESTIGATION] 플러그인 개조 전 Flutter 단 검토:**
/// 
/// **핵심 질문: Flutter에서 [1,28,28,3] 텐서 형태로 변환 가능한가?**
/// 
/// **현재 상황:**
/// - EMNIST 모델 입력: [1,28,28,1] (1채널 그레이스케일)
/// - 원본 YOLO 플러그인: [1,28,28,3] (3채널 RGB)만 지원
/// - 현재 구현: Float32List(784) → RGB PNG → YOLO 처리
/// 
/// **검토 필요 사항:**
/// 1. **직접 텐서 조작**: Float32List(784) → Float32List(2352) 변환
///    ```dart
///    // [1,28,28,1] → [1,28,28,3] 직접 변환
///    Float32List grayscaleToRgb(Float32List grayscale) {
///      final rgb = Float32List(28 * 28 * 3);
///      for (int i = 0; i < 784; i++) {
///        rgb[i * 3] = grayscale[i];     // R
///        rgb[i * 3 + 1] = grayscale[i]; // G  
///        rgb[i * 3 + 2] = grayscale[i]; // B
///      }
///      return rgb;
///    }
///    ```
/// 
/// 2. **YOLO 플러그인 호출 방식 조사**:
///    - 현재: PNG 바이트 → YOLO.predict()
///    - 대안: Float32List 직접 전달 가능한지 확인
///    - YOLOPlugin.kt에서 텐서 형태 변경 가능한지 조사
/// 
/// 3. **성능 비교 테스트**:
///    - 방법 A: Float32List(784) → PNG → YOLO (현재 방식)
///    - 방법 B: Float32List(784) → Float32List(2352) → YOLO (제안 방식)
///    - 방법 C: 로컬 패키지 개조 (궁극적 해결책)
/// 
/// 4. **호환성 검증**:
///    - 원본 YOLO 플러그인에서 Float32List 직접 입력 지원 여부
///    - TensorFlow Lite 모델 입력 텐서 형태 변경 가능성
///    - 기존 어노테이션 시스템과의 충돌 여부
/// 
/// **예상 결과:**
/// - ✅ 성공 시: 플러그인 개조 없이 1채널 지원 (임시 해결책)
/// - ❌ 실패 시: 로컬 패키지 개조 필수 (근본적 해결책)
/// - 📊 성능 향상: PNG 인코딩/디코딩 과정 제거로 속도 개선
/// 
/// **구현 우선순위:**
/// 1. 먼저 Flutter 단에서 [1,28,28,3] 변환 시도
/// 2. 성공하면 임시 해결책으로 사용
/// 3. 실패하면 로컬 패키지 개조로 진행
/// 4. 최종적으로는 로컬 패키지가 더 나은 해결책
/// 
/// ❌ [MAJOR LIMITATIONS] 원본 YOLO 플러그인의 한계들:
/// 
/// 1. 🚫 **추론 (Inference) 한계:**
///    - ClassifierOptions 미지원 (색상 반전, 정규화 등)
///    - 1채널 그레이스케일 모델 자동 감지 불가
///    - EMNIST 특화 전처리 파이프라인 없음
/// 
/// 2. 🚫 **전처리 (Preprocessing) 한계:**
///    - 3채널 RGB만 지원, 1채널 그레이스케일 처리 불가 ⭐ **핵심 문제**
///    - 색상 반전 (enableColorInversion) 미지원
///    - 최대값 정규화 (enableMaxNormalization) 미지원
///    - React Native 방식의 단순한 전처리 불가능
/// 
/// 3. 🚫 **후처리 (Postprocessing) 한계:**
///    - top1Index 직접 반환 불가 (React Native 방식)
///    - 커스텀 classification 결과 형식 미지원
///    - EMNIST 라벨 매핑 (10→✓, 11→✗) 복잡함
/// 
/// 4. 🚫 **AnnotatedImage 이슈:**
///    - classification 태스크에서 어노테이션 렌더링 문제
///    - 1채널 그레이스케일 이미지에 RGB 어노테이션 오버레이 충돌
///    - 손글씨 인식에서는 어노테이션이 불필요하지만 자동 생성되어 성능 저하
///    - drawAnnotations() 메서드가 classification용으로 최적화되지 않음
/// 
/// 📁 **로컬 패키지 구현 시 수정 필요한 파일들:**
/// 
/// **Android/Kotlin 레이어 (5개 파일):**
/// - 🔧 YOLOPlugin.kt: classifierOptions 파라미터 추가, top1Index 직접 반환
/// - 🔧 YOLO.kt: taskOptions 전달, annotatedImage 생성 비활성화 옵션
/// - 🔧 YOLOInstanceManager.kt: taskOptions 지원, 인스턴스별 옵션 관리
/// - 🔧 Classifier.kt: 1채널 처리, processGrayscaleImage(), ClassifierOptions ⭐ **핵심**
/// - 🔧 ImageUtils.kt: 전처리 유틸 (resize, grayscale, invert, normalize) ⭐ **핵심**
/// 
/// **Flutter/Dart 레이어 (1개 파일):**
/// - 🔧 yolo.dart: ClassifierOptions 클래스, withClassifierOptions() 생성자
/// 
/// **🔄 [IMMEDIATE ACTION ITEMS] 즉시 수정 필요한 항목들:**
/// 
/// **우선순위 1 (성능 개선):**
/// 1. handwriting_preprocessor.dart에서 직접 PNG 생성하도록 수정
/// 2. predictFromFloat32List() 메서드에서 이중 변환 제거
/// 3. drawing_canvas.dart의 API 호출 최적화
/// 
/// **우선순위 2 (아키텍처 정리):**
/// 1. YOLO 로컬 패키지 개발 vs 원본 플러그인 최적화 결정
/// 2. 전처리 파이프라인 통합 및 단순화
/// 3. 벤치마크 및 테스트 코드 업데이트
/// 
/// **우선순위 3 (기능 완성):**
/// 1. 1채널 그레이스케일 지원 구현
/// 2. EMNIST 라벨 매핑 최적화
/// 3. AnnotatedImage 생성 비활성화 옵션
/// 
/// **복잡성의 이유:**
/// - 원본 Ultralytics는 범용 YOLO 라이브러리 (detection, segmentation, pose 등)
/// - EMNIST 손글씨 인식은 매우 특화된 use case
/// - React Native는 TensorFlow Lite 직접 호출로 단순함
/// - Flutter는 플랫폼 채널을 통한 Kotlin 브릿지 필요
/// - 6개 파일이 유기적으로 연결되어 하나라도 빠지면 전체 실패
/// 
/// 🎯 **성공 지표:**
/// 1차: 손글씨 숫자 인식 작동 (정확도 무관)
/// 2차: 1채널 지원으로 성능 개선 (React Native 수준)
/// 3차: 범용 옵션으로 오픈소스 기여
class HandwritingModelService {
  static final HandwritingModelService _instance = HandwritingModelService._internal();
  
  factory HandwritingModelService() => _instance;
  
  HandwritingModelService._internal();
  
  /// Singleton instance getter
  static HandwritingModelService get instance => _instance;
  
  bool _isModelLoaded = false;
  
  // YOLO predictor instance
  YOLO? _predictor;
  
  // Model constants
  static const String MODEL_NAME = 'my_emnist_model2.tflite';

  /// 모델이 로드되었는지 확인
  bool get isModelLoaded => _isModelLoaded;

  /// 레거시 호환성을 위한 isReady getter
  bool get isReady => _isModelLoaded;

  /// 레거시 호환성을 위한 initialize 메서드
  Future<void> initialize() async {
    await loadModel();
  }

  /// 레거시 호환성을 위한 predictFromFloat32List 메서드
  Future<HandwritingPrediction?> predictFromFloat32List(Float32List imageData) async {
    final prediction = await recognizeHandwriting(imageData);
    return prediction;
  }

  /// 모델 로드 (앱 시작 시 한번만 호출)
  Future<bool> loadModel() async {
    if (_isModelLoaded) {
      print('✅ Model already loaded');
      return true;
    }

    try {
      print('🔄 Loading YOLO classification model...');
      
      // ❌ [DISABLED] 커스텀 ClassifierOptions는 원본 YOLO 플러그인에서 지원하지 않음
      // TODO: 로컬 패키지에서 다시 구현 예정
      // 📁 필요한 파일 수정: yolo.dart + YOLOPlugin.kt + YOLO.kt + Classifier.kt
      /*
      _predictor = YOLO.withClassifierOptions(
        modelPath: MODEL_NAME,
        classifierOptions: const ClassifierOptions(
          enableColorInversion: true,
          enableMaxNormalization: true,
        ),
      );
      */
      
      // ❌ [주석 오류 수정] YOLO.fromAssets, YOLO.fromPath 모두 존재하지 않음
      // ✅ [올바른 구현] 원본 YOLO 플러그인 실제 API 사용법
      _predictor = YOLO(
        modelPath: MODEL_NAME,
        task: YOLOTask.classify,
      );
      
      // 모델 로드 (필수!)
      final success = await _predictor!.loadModel();
      
      if (success) {
        print('✅ YOLO model loaded successfully');
        
        // 모델 정보 디버깅 (가능한 경우)
        try {
          print('🔍 Model debugging info:');
          print('   - Model path: $MODEL_NAME');
          print('   - Task type: ${YOLOTask.classify}');
          // ❌ [DISABLED] 커스텀 옵션은 현재 사용 불가
          // print('   - Classifier options: Custom(inversion:true, max-norm:true)');
          print('   - Using: Original YOLO plugin (basic classification)');
          print('   - Custom preprocessing: DISABLED (원본 플러그인 한계)');
          print('   - AnnotatedImage: 강제 생성됨 (성능 저하, 손글씨에 불필요)');
          
          // YOLO 객체 정보 출력 시도
          print('   - YOLO instance: ${_predictor.runtimeType}');
          
        } catch (debugError) {
          print('⚠️ Could not get model debug info: $debugError');
        }
        
        _isModelLoaded = true;
        return true;
      } else {
        print('❌ YOLO model load failed');
        _predictor = null;
        _isModelLoaded = false;
        return false;
      }
      
    } catch (e) {
      print('❌ Failed to load model: $e');
      _predictor = null;
      _isModelLoaded = false;
      return false;
    }
  }

  /// 손글씨 인식 실행
  Future<HandwritingPrediction> recognizeHandwriting(Float32List imageData) async {
    if (!_isModelLoaded || _predictor == null) {
      return HandwritingPrediction.error('Model not loaded');
    }

    try {
      print('🔄 Starting YOLO prediction...');
      print('📊 Input data: ${imageData.length} floats (should be 784 for 28x28)');
      
      // ❌ [DISABLED] 커스텀 그레이스케일 전처리는 원본 플러그인에서 지원하지 않음
      // TODO: 로컬 패키지에서 다시 구현 예정
      // 📁 필요한 파일 수정: Classifier.kt + ImageUtils.kt
      /*
      print('🖼️ Converting to grayscale PNG image...');
      final imageBytes = await _convertToGrayscalePng(imageData);
      print('📦 Grayscale PNG created: ${imageBytes.length} bytes');
      */
      
      // ✅ [TEMPORARY] 원본 플러그인용 RGB 이미지 변환
      print('🖼️ Converting to RGB PNG image (원본 플러그인 호환)...');
      final imageBytes = await _convertToRgbPng(imageData);
      print('📦 RGB PNG created: ${imageBytes.length} bytes');
      
      print('🚀 Calling YOLO predict...');
      // ❌ [LIMITATION] 원본 플러그인은 3채널 RGB만 지원, 1채널 그레이스케일 자동 처리 불가
      print('⚠️ Warning: 원본 플러그인은 RGB 전처리만 지원, EMNIST 최적화 불가');
      // 🖼️ [ANNOTATED IMAGE ISSUE] 불필요한 어노테이션 이미지가 자동 생성되어 성능 저하
      print('🖼️ Warning: AnnotatedImage 자동 생성됨 (손글씨 인식에 불필요, 성능 저하)');
      final result = await _predictor!.predict(imageBytes);
      print('✅ YOLO prediction completed successfully');
      print('📋 Raw result: $result');
      
      return _parseYoloResult(result);
      
    } catch (e, stackTrace) {
      print('❌ Recognition error: $e');
      print('📚 Stack trace: $stackTrace');
      
      // 에러 타입별 상세 분석
      if (e.toString().contains('input tensor shape')) {
        print('🔍 TENSOR SHAPE ERROR DETECTED:');
        print('   - This suggests model expects different input format');
        print('   - EMNIST model likely expects [1,28,28,1] but got different shape');
        print('   - 원본 플러그인은 3채널 RGB 전처리만 지원');
        print('   - 로컬 패키지에서 1채널 지원 필요');
        print('   📁 수정 필요: Classifier.kt의 processGrayscaleImage() 구현');
      }
      
      if (e.toString().contains('annotated') || e.toString().contains('annotation')) {
        print('🔍 ANNOTATED IMAGE ERROR DETECTED:');
        print('   - classification 태스크에서 어노테이션 렌더링 실패');
        print('   - 1채널 그레이스케일과 RGB 어노테이션 충돌');
        print('   - 손글씨 인식에서는 어노테이션이 불필요');
        print('   📁 수정 필요: YOLO.kt의 drawAnnotations() 비활성화 옵션');
      }
      
      return HandwritingPrediction.error('Recognition failed: $e');
    }
  }

  /// ❌ [DISABLED] Float32List → 그레이스케일 PNG 이미지 변환 (원본 플러그인 미지원)
  /// TODO: 로컬 패키지에서 다시 구현 예정
  /// 📁 구현 위치: Classifier.kt의 processGrayscaleImage() + ImageUtils.kt 유틸리티
  /*
  Future<Uint8List> _convertToGrayscalePng(Float32List grayscaleData) async {
    // 커스텀 그레이스케일 전처리 로직
    // 원본 플러그인에서는 지원하지 않음
    // React Native 방식: 단순한 1.0 - (r+g+b)/(3*255) 변환
    // Flutter 필요: 복잡한 6개 파일 수정으로 동일 효과 구현
  }
  */

  /// ✅ [TEMPORARY] Float32List → RGB PNG 이미지 변환 (원본 플러그인 호환용)
  /// 성능이 떨어지지만 원본 플러그인에서 작동하도록 임시 구현
  /// 🚫 [ANNOTATED IMAGE ISSUE] RGB 이미지는 불필요한 어노테이션 생성을 유발함
  Future<Uint8List> _convertToRgbPng(Float32List grayscaleData) async {
    const int imageSize = 28; // EMNIST 모델 크기
    
    print('🎯 RGB conversion details (원본 플러그인 호환):');
    print('   - Size: ${imageSize}x${imageSize} = ${imageSize * imageSize} pixels');
    print('   - Input data length: ${grayscaleData.length}');
    print('   - Target: 3-channel RGB PNG (비효율적이지만 호환성 위해)');
    print('   🖼️ Side effect: 불필요한 annotatedImage 생성됨 (성능 저하)');
    
    // ⚠️ [SUBOPTIMAL] 그레이스케일을 RGB로 변환 (3배 용량 증가)
    final Uint8List rgbaData = Uint8List(imageSize * imageSize * 4);
    
    int nonZeroPixels = 0;
    for (int i = 0; i < grayscaleData.length && i < imageSize * imageSize; i++) {
      // ❌ [LIMITATION] 색상 반전 및 최대값 정규화 불가 (원본 플러그인 한계)
      // 📁 로컬 패키지에서 구현 필요: ImageUtils.kt의 invertColors(), normalizePixels()
      final int grayValue = (grayscaleData[i] * 255).round().clamp(0, 255);
      
      // 그레이스케일을 RGB로 복제 (비효율적)
      final int rgbaIndex = i * 4;
      rgbaData[rgbaIndex] = grayValue;     // R
      rgbaData[rgbaIndex + 1] = grayValue; // G  
      rgbaData[rgbaIndex + 2] = grayValue; // B
      rgbaData[rgbaIndex + 3] = 255;       // A
      
      if (grayValue > 0) nonZeroPixels++;
    }
    
    print('   - Non-zero pixels: $nonZeroPixels/${imageSize * imageSize}');
    print('🖼️ Creating ${imageSize}x${imageSize} RGBA image (원본 플러그인용)');
    
    // RGBA 이미지를 PNG로 인코딩
    final Completer<Uint8List> completer = Completer<Uint8List>();
    
    ui.decodeImageFromPixels(
      rgbaData,
      imageSize,
      imageSize,
      ui.PixelFormat.rgba8888,
      (ui.Image image) async {
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List pngBytes = byteData!.buffer.asUint8List();
        print('📦 RGB PNG encoding completed (원본 플러그인 호환):');
        print('   - Final PNG size: ${pngBytes.length} bytes');
        print('   - Image dimensions: ${image.width}x${image.height}');
        print('   - Channels: 3 (RGB) - 비효율적이지만 호환성 확보');
        print('   🖼️ Warning: 이 이미지로 인해 불필요한 어노테이션 생성됨');
        completer.complete(pngBytes);
      },
    );
    
    return completer.future;
  }

  /// YOLO 결과 파싱
  HandwritingPrediction _parseYoloResult(dynamic result) {
    // ❌ [LIMITATION] 원본 플러그인은 커스텀 classification 결과 형식을 지원하지 않을 수 있음
    // TODO: 로컬 패키지에서 top1Index 직접 반환 구현 예정
    // 📁 필요한 파일 수정: YOLOPlugin.kt + Classifier.kt (React Native 방식)
    
    // 🖼️ [ANNOTATED IMAGE WASTE] result에 불필요한 annotatedImage 포함됨
    if (result is Map<String, dynamic> && result.containsKey('annotatedImage')) {
      print('🖼️ Unnecessary annotatedImage detected in result (${result['annotatedImage']?.length ?? 0} bytes)');
      print('   - 손글씨 인식에서는 어노테이션 불필요');
      print('   - 메모리 및 처리 시간 낭비');
      print('   📁 로컬 패키지에서 YOLO.kt 수정으로 어노테이션 비활성화 필요');
    }
    
    // 결과 파싱 시도
    if (result is Map<String, dynamic> && result.containsKey('classification')) {
      final classificationResult = result['classification'];
      
      if (classificationResult is Map<String, dynamic>) {
        final rawDigit = classificationResult['topClass']?.toString() ?? 'unknown';
        final confidence = (classificationResult['topConfidence'] as num?)?.toDouble() ?? 0.0;
        
        // ✅ EMNIST 라벨 매핑 (React Native와 동일)
        String digit;
        if (rawDigit == '10') {
          digit = '✓'; // 체크/완료
        } else if (rawDigit == '11') {
          digit = '✗'; // 지우기/취소
        } else {
          digit = rawDigit; // 0-9 숫자
        }
        
        print('🎯 Recognition result: $digit (${(confidence * 100).toStringAsFixed(1)}%)');
        
        return HandwritingPrediction.success(
          digit: digit,
          confidence: confidence,
        );
      }
    }
    
    // ❌ [FALLBACK] 원본 플러그인의 기본 결과 형식 처리 시도
    // 원본 플러그인은 다른 결과 형식을 사용할 수 있음
    if (result is List && result.isNotEmpty) {
      print('📋 Result as List (원본 플러그인 형식): $result');
      // List 형태의 결과 처리
      if (result[0] is Map) {
        final digit = result[0].keys.first.toString();
        final confidence = (result[0].values.first as num?)?.toDouble() ?? 0.0;
        
        // 간단한 라벨 매핑 시도
        String mappedDigit = digit;
        if (digit == '10') mappedDigit = '✓';
        else if (digit == '11') mappedDigit = '✗';
        
        return HandwritingPrediction.success(digit: mappedDigit, confidence: confidence);
      }
    }
    
    print('📋 Unknown result format (원본 플러그인): $result');
    print('⚠️ 원본 플러그인의 결과 형식이 예상과 다름 - 로컬 패키지 구현 필요');
    print('📁 React Native 방식 구현 필요: top1Index 직접 반환');
    return HandwritingPrediction.error('Invalid result format: $result');
  }

  /// 더미 테스트용 28x28 숫자 5 패턴 생성
  Float32List generateDummyDigit5() {
    final Float32List data = Float32List(28 * 28);
    
    // 숫자 5 패턴을 28x28 배열로 생성
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        int pixelValue = 0;
        
        // 숫자 5 패턴 정의
        if ((y >= 5 && y <= 7 && x >= 5 && x <= 20) ||    // 상단 가로선
            (y >= 8 && y <= 15 && x >= 5 && x <= 7) ||     // 왼쪽 세로선  
            (y >= 13 && y <= 15 && x >= 5 && x <= 18) ||   // 중간 가로선
            (y >= 16 && y <= 20 && x >= 16 && x <= 18) ||  // 오른쪽 세로선
            (y >= 18 && y <= 20 && x >= 5 && x <= 18)) {   // 하단 가로선
          pixelValue = 1;
        }
        
        final int index = y * 28 + x;
        data[index] = pixelValue.toDouble();
      }
    }
    
    return data;
  }

  /// 서비스 정리
  void dispose() {
    _predictor = null;
    _isModelLoaded = false;
    print('[HandwritingModelService] 서비스가 정리되었습니다.');
  }
} 