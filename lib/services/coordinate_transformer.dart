import 'dart:ui';

/// 좌표 변환 관련 유틸리티
class CoordinateTransformer {
  /// Portrait 모드에서 회전이 필요한지 확인
  static bool needsRotationForPortrait(double imageWidth, double imageHeight) {
    return imageWidth > imageHeight; // 640x480 = Portrait에서 회전 필요
  }
  
  /// 회전 후 최종 이미지 크기 계산
  static Size getFinalImageSize(double originalWidth, double originalHeight, bool needsRotation) {
    if (needsRotation) {
      return Size(originalHeight, originalWidth); // 480x640
    }
    return Size(originalWidth, originalHeight); // 640x480
  }
  
  /// boundingBox 좌표를 최종 이미지 크기에 맞게 검증
  static Rect validateBoundingBox(Map boundingBox, Size finalSize) {
    return Rect.fromLTRB(
      (boundingBox['left'] as num).toDouble(),
      (boundingBox['top'] as num).toDouble(),
      (boundingBox['right'] as num).toDouble(),
      (boundingBox['bottom'] as num).toDouble(),
    ).intersect(Rect.fromLTWH(0, 0, finalSize.width, finalSize.height));
  }
  
  /// normalizedBox를 픽셀 좌표로 변환
  static Rect convertNormalizedBox(Map normalizedBox, Size finalSize) {
    final left = (normalizedBox['left'] as num).toDouble() * finalSize.width;
    final top = (normalizedBox['top'] as num).toDouble() * finalSize.height;
    final right = (normalizedBox['right'] as num).toDouble() * finalSize.width;
    final bottom = (normalizedBox['bottom'] as num).toDouble() * finalSize.height;
    
    return Rect.fromLTRB(left, top, right, bottom)
        .intersect(Rect.fromLTWH(0, 0, finalSize.width, finalSize.height));
  }
} 