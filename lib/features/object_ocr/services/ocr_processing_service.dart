import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../models/crop.dart';
import '../models/ocr_result.dart';

/// OCR 처리 전용 서비스 (ML Kit 연동)
class OcrProcessingService {
  static final OcrProcessingService _instance = OcrProcessingService._internal();
  factory OcrProcessingService() => _instance;
  OcrProcessingService._internal();

  TextRecognizer? _recognizer;
  bool _isInitialized = false;

  /// OCR 인식기 초기화
  bool initialize({TextRecognitionScript script = TextRecognitionScript.korean}) {
    if (_isInitialized) return true;
    
    try {
      _recognizer = TextRecognizer(script: script);
      _isInitialized = true;
      print('[OCR_PROCESSING] Initialized with script: $script');
      return true;
    } catch (e) {
      print('[OCR_PROCESSING] Failed to initialize: $e');
      return false;
    }
  }

  /// OCR 인식기 해제
  void dispose() {
    if (_recognizer != null) {
      _recognizer!.close();
      _recognizer = null;
      _isInitialized = false;
      print('[OCR_PROCESSING] Disposed resources');
    }
  }

  /// 단일 크롭에 대한 OCR 처리
  Future<OcrResult> processOcr(Crop crop) async {
    if (!_isInitialized || _recognizer == null) {
      throw Exception('OCR recognizer not initialized');
    }

    File? tempFile;
    try {
      // 임시 파일로 JPEG 저장
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/ocr_temp_${crop.id}.jpg');
      await tempFile.writeAsBytes(crop.jpegBytes);

      // 파일에서 InputImage 생성
      final inputImage = InputImage.fromFile(tempFile);

      // ML Kit Korean Text Recognition으로 텍스트 인식
      final recognizedText = await _recognizer!.processImage(inputImage);

      // OCR 결과 변환
      return _convertToOcrResult(recognizedText, crop.id);

    } catch (e) {
      print('[OCR_PROCESSING] Error processing crop ${crop.id}: $e');
      return OcrResult(
        text: '',
        confidence: 0.0,
        timestamp: DateTime.now(),
      );
    } finally {
      // 임시 파일 정리
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// ML Kit RecognizedText를 OcrResult로 변환 (박스별 신뢰도 포함)
  OcrResult _convertToOcrResult(RecognizedText recognizedText, String cropId) {
    final String text = recognizedText.text;
    double totalConfidence = 0.0;
    int elementCount = 0;

    // 블록 정보 수집 (상세한 박스별 정보 포함)
    final List<OcrBlock> blocks = [];

    for (TextBlock block in recognizedText.blocks) {
      final String blockText = block.text;
      final List<String> languages = block.recognizedLanguages;
      
      // 블록 위치 정보
      final blockRect = block.boundingBox != null 
          ? Rect.fromLTRB(
              block.boundingBox!.left.toDouble(),
              block.boundingBox!.top.toDouble(),
              block.boundingBox!.right.toDouble(),
              block.boundingBox!.bottom.toDouble(),
            )
          : null;
      
      print('[OCR_DETAIL] Block: "$blockText", Languages: $languages, Box: $blockRect');

      // 라인 정보 수집
      final List<OcrLine> lines = [];
      
      for (TextLine line in block.lines) {
        // 라인 위치 정보
        final lineRect = line.boundingBox != null 
            ? Rect.fromLTRB(
                line.boundingBox!.left.toDouble(),
                line.boundingBox!.top.toDouble(),
                line.boundingBox!.right.toDouble(),
                line.boundingBox!.bottom.toDouble(),
              )
            : null;
        
        print('[OCR_LINE] "${line.text}" (confidence: ${line.confidence?.toStringAsFixed(3) ?? 'N/A'}, box: $lineRect)');
        
        // 라인 신뢰도도 집계에 포함
        if (line.confidence != null) {
          totalConfidence += line.confidence!;
          elementCount++;
        }
        
        // 요소 정보 수집
        final List<OcrElement> elements = [];
        
        for (TextElement element in line.elements) {
          // 요소 위치 정보
          final elementRect = element.boundingBox != null 
              ? Rect.fromLTRB(
                  element.boundingBox!.left.toDouble(),
                  element.boundingBox!.top.toDouble(),
                  element.boundingBox!.right.toDouble(),
                  element.boundingBox!.bottom.toDouble(),
                )
              : null;
          
          print('[OCR_ELEMENT] "${element.text}" (confidence: ${element.confidence?.toStringAsFixed(3) ?? 'N/A'}, level: ${_getConfidenceLevel(element.confidence)}, box: $elementRect)');
          
          // 신뢰도 집계
          if (element.confidence != null) {
            totalConfidence += element.confidence!;
            elementCount++;
          }

          elements.add(OcrElement(
            text: element.text,
            confidence: element.confidence,
            boundingBox: elementRect,
            angle: element.angle?.toDouble(),
          ));
        }

        lines.add(OcrLine(
          text: line.text,
          confidence: line.confidence?.toDouble(),
          elements: elements,
          boundingBox: lineRect,
          angle: line.angle?.toDouble(),
        ));
      }

      blocks.add(OcrBlock(
        text: blockText,
        languages: languages,
        lines: lines,
        boundingBox: blockRect,
      ));
    }

    // 평균 신뢰도 계산
    final double averageConfidence = elementCount > 0 ? totalConfidence / elementCount : 0.8;

    final result = OcrResult(
      text: text.trim(),
      confidence: averageConfidence,
      timestamp: DateTime.now(),
      language: 'ko', // Korean script
      blocks: blocks,
    );

    // 박스별 신뢰도 통계 출력
    final stats = result.confidenceStats;
    print('[OCR_SUCCESS] Processed crop $cropId: "${text.trim()}"');
    print('[OCR_CONFIDENCE] Overall: ${result.displayConfidence}');
    print('[OCR_CONFIDENCE] Line avg: ${(stats['avgLine']! * 100).toStringAsFixed(1)}% (${(stats['minLine']! * 100).toStringAsFixed(1)}% - ${(stats['maxLine']! * 100).toStringAsFixed(1)}%)');
    print('[OCR_CONFIDENCE] Element avg: ${(stats['avgElement']! * 100).toStringAsFixed(1)}% (${(stats['minElement']! * 100).toStringAsFixed(1)}% - ${(stats['maxElement']! * 100).toStringAsFixed(1)}%)');
    
    // 낮은 신뢰도 텍스트 경고
    final lowConfidenceTexts = result.getLowConfidenceTexts(threshold: 0.6);
    if (lowConfidenceTexts.isNotEmpty) {
      print('[OCR_WARNING] Low confidence texts detected:');
      for (final lowText in lowConfidenceTexts) {
        print('[OCR_WARNING] $lowText');
      }
    }
    
    return result;
  }

  /// 신뢰도 레벨 판정
  String _getConfidenceLevel(double? confidence) {
    if (confidence == null) return 'Unknown';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  /// 인식기 상태 확인
  bool get isInitialized => _isInitialized;
} 