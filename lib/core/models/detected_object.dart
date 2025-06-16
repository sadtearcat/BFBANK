import 'dart:typed_data';
import '../../features/object_ocr/models/ocr_result.dart';

/// 갤러리에 저장되는 탐지된 객체 (이미지 + OCR 결과)
class DetectedObject {
  final String id;
  final Uint8List imageBytes; // JPEG 이미지 데이터
  final String? className; // YOLO 탐지 클래스
  final double? confidence; // YOLO 신뢰도
  final String? ocrText; // OCR 인식 결과
  final double? ocrConfidence; // OCR 신뢰도
  final OcrResult? ocrResult; // 상세한 OCR 결과 (박스 정보 포함)
  final DateTime timestamp;

  const DetectedObject({
    required this.id,
    required this.imageBytes,
    required this.timestamp,
    this.className,
    this.confidence,
    this.ocrText,
    this.ocrConfidence,
    this.ocrResult,
  });

  /// OCR 결과가 있는지 확인
  bool get hasOcrText => ocrText != null && ocrText!.isNotEmpty;

  /// OCR 신뢰도가 있는지 확인
  bool get hasOcrConfidence => ocrConfidence != null;

  /// 디스플레이용 제목
  String get displayTitle {
    if (hasOcrText) {
      return ocrText!.length > 20 ? '${ocrText!.substring(0, 20)}...' : ocrText!;
    }
    return className ?? 'Unknown';
  }

  /// 디스플레이용 OCR 신뢰도 텍스트
  String get displayOcrConfidence {
    if (hasOcrConfidence) {
      return '${(ocrConfidence! * 100).toStringAsFixed(1)}%';
    }
    return 'N/A';
  }

  /// OCR 결과와 신뢰도를 추가한 새 객체 생성
  DetectedObject withOcrResult(String text, double confidence) {
    return DetectedObject(
      id: id,
      imageBytes: imageBytes,
      className: className,
      confidence: this.confidence, // YOLO 신뢰도 유지
      ocrText: text,
      ocrConfidence: confidence,
      ocrResult: ocrResult,
      timestamp: timestamp,
    );
  }

  /// 상세한 OCR 결과를 추가한 새 객체 생성
  DetectedObject withDetailedOcrResult(OcrResult result) {
    return DetectedObject(
      id: id,
      imageBytes: imageBytes,
      className: className,
      confidence: this.confidence, // YOLO 신뢰도 유지
      ocrText: result.text,
      ocrConfidence: result.confidence,
      ocrResult: result,
      timestamp: timestamp,
    );
  }

  /// OCR 결과만 추가한 새 객체 생성 (기존 호환성 유지)
  DetectedObject withOcrText(String text) {
    return DetectedObject(
      id: id,
      imageBytes: imageBytes,
      className: className,
      confidence: this.confidence,
      ocrText: text,
      ocrConfidence: ocrConfidence,
      ocrResult: ocrResult,
      timestamp: timestamp,
    );
  }

  @override
  String toString() => 'DetectedObject($id, ${className ?? 'Unknown'}, OCR: ${hasOcrText ? "Yes" : "No"}, Confidence: ${displayOcrConfidence})';
} 