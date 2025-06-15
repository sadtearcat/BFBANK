import 'dart:typed_data';

/// OCR 처리를 위한 크롭된 이미지 데이터 (기존 JPEG 크롭 결과 재사용)
class Crop {
  final Uint8List jpegBytes; // 기존 JPEG 크롭 결과
  final String id;
  final DateTime timestamp;
  final String? className; // YOLO 탐지 클래스명
  final double? confidence; // YOLO 신뢰도

  const Crop({
    required this.jpegBytes,
    required this.id,
    required this.timestamp,
    this.className,
    this.confidence,
  });

  /// 디버그 정보
  String get debugInfo => 'Crop($id, ${jpegBytes.length}B JPEG)';

  @override
  String toString() => debugInfo;
} 