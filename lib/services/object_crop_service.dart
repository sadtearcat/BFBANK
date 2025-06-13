import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'coordinate_transformer.dart';
import 'image_processing_service.dart';
import 'gallery_service.dart';

/// 객체 탐지 결과 처리 및 크롭 서비스
class ObjectCropService {
  final GalleryService _galleryService;
  
  ObjectCropService(this._galleryService);
  
  /// 스트리밍 데이터로부터 고신뢰도 탐지 결과 필터링
  List<dynamic> _filterHighConfidenceDetections(List<dynamic>? detectionsRaw, {double threshold = 0.70}) {
    if (detectionsRaw == null) return [];
    
    return detectionsRaw.where((d) => (d['confidence'] as num) >= threshold).toList();
  }
  
  /// 탐지 결과로부터 크롭 영역들 추출
  List<Rect> _extractCropRegions(List<dynamic> detections, Size finalImageSize) {
    final cropRects = <Rect>[];
    
    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final boundingBox = detection['boundingBox'] as Map?;
      final normalizedBox = detection['normalizedBox'] as Map?;
      final className = detection['className'] as String? ?? 'unknown';
      final confidence = (detection['confidence'] as num).toDouble();
      
      print('[CROP][$i] $className (${(confidence * 100).toStringAsFixed(1)}%)');
      print('[CROP][$i] boundingBox: $boundingBox');
      print('[CROP][$i] normalizedBox: $normalizedBox');
      
      Rect? cropRect;
      
      // boundingBox를 우선 사용 (회전된 이미지에서 직접 적용)
      if (boundingBox != null) {
        print('[CROP][$i] Using boundingBox (primary) - direct coordinates on rotated image');
        cropRect = CoordinateTransformer.validateBoundingBox(boundingBox, finalImageSize);
        print('[CROP][$i] BoundingBox rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
      } else if (normalizedBox != null) {
        print('[CROP][$i] Using normalizedBox as fallback - converting to ${finalImageSize.width}x${finalImageSize.height}');
        cropRect = CoordinateTransformer.convertNormalizedBox(normalizedBox, finalImageSize);
        print('[CROP][$i] NormalizedBox rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
      } else {
        print('[CROP][$i] No valid bounding box found');
        continue;
      }
      
      if (cropRect.width > 10 && cropRect.height > 10) {
        cropRects.add(cropRect);
      } else {
        print('[CROP][$i] Skipped - too small: ${cropRect.width}x${cropRect.height}');
      }
    }
    
    return cropRects;
  }
  
  /// 메인 처리 함수 - 스트리밍 데이터를 받아서 크롭 처리
  Future<List<Uint8List>> processStreamingData(Map<String, dynamic> data) async {
    print('[YOLO] ═══════════════════════════════════════════════════');
    print('[YOLO] ObjectCropService processing streaming data');
    
    final jpeg = data['originalImage'] as Uint8List?;
    final detectionsRaw = data['detections'] as List<dynamic>?;
    
    if (jpeg == null || detectionsRaw == null) {
      print('[CROP] Missing originalImage or detections data');
      return [];
    }
    
    print('[YOLO] JPEG: ${jpeg.length} bytes');
    print('[YOLO] Detections: ${detectionsRaw.length} items');
    
    // ── ① 70% 이상 신뢰도 필터 ─────────────────────────────────────
    final highConfidenceDetections = _filterHighConfidenceDetections(detectionsRaw);
    if (highConfidenceDetections.isEmpty) {
      print('[CROP] No high confidence detections found');
      return [];
    }
    
    // ── ② 이미지 크기 및 회전 설정 ─────────────────────────────────────
    final originalImageSize = await ImageProcessingService.getImageSize(jpeg);
    final needsRotation = CoordinateTransformer.needsRotationForPortrait(
      originalImageSize.width, 
      originalImageSize.height
    );
    final finalImageSize = CoordinateTransformer.getFinalImageSize(
      originalImageSize.width, 
      originalImageSize.height, 
      needsRotation
    );
    
    print('[CROP] Original image: ${originalImageSize.width}x${originalImageSize.height}');
    print('[CROP] Portrait mode detected: $needsRotation (needs rotation)');
    print('[CROP] Final crop target: ${finalImageSize.width}x${finalImageSize.height}');
    
    // ── ③ 크롭 영역 추출 ────────────────────────────────
    final cropRects = _extractCropRegions(highConfidenceDetections, finalImageSize);
    if (cropRects.isEmpty) {
      print('[CROP] No valid crop regions found');
      return [];
    }
    
    // ── ④ 크롭 실행 ────────────────────────────────
    final croppedImages = await ImageProcessingService.cropMultipleObjects(
      imageBytes: jpeg,
      cropRects: cropRects,
      needsRotation: needsRotation,
    );
    
    if (croppedImages.isNotEmpty) {
      // 갤러리에 추가
      _galleryService.addCroppedImages(croppedImages);
      print('[CROP] ${croppedImages.length} objects cropped, total gallery: ${_galleryService.count}');
    }
    
    return croppedImages;
  }
} 