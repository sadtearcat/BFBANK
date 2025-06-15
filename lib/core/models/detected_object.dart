import 'dart:typed_data';

/// 갤러리에 저장되는 탐지된 객체 (이미지 + OCR 결과)
class DetectedObject {
  final String id;
  final Uint8List imageBytes; // JPEG 이미지 데이터
  final String? className; // YOLO 탐지 클래스
  final double? confidence; // YOLO 신뢰도
  final String? ocrText; // OCR 인식 결과
  final DateTime timestamp;

  const DetectedObject({
    required this.id,
    required this.imageBytes,
    required this.timestamp,
    this.className,
    this.confidence,
    this.ocrText,
  });

  /// OCR 결과가 있는지 확인
  bool get hasOcrText => ocrText != null && ocrText!.isNotEmpty;

  /// 디스플레이용 제목
  String get displayTitle {
    if (hasOcrText) {
      return ocrText!.length > 20 ? '${ocrText!.substring(0, 20)}...' : ocrText!;
    }
    return className ?? 'Unknown';
  }

  /// OCR 결과 추가한 새 객체 생성
  DetectedObject withOcrText(String text) {
    return DetectedObject(
      id: id,
      imageBytes: imageBytes,
      className: className,
      confidence: confidence,
      ocrText: text,
      timestamp: timestamp,
    );
  }

  @override
  String toString() => 'DetectedObject($id, ${className ?? 'Unknown'}, OCR: ${hasOcrText ? "Yes" : "No"})';
} 