import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'coordinate_transformer.dart';
import 'image_processing_service.dart';
import 'gallery_service.dart';
import 'ocr_queue_service.dart';
import '../core/models/crop.dart';
import '../core/models/detected_object.dart';
import 'dart:math' as math;

/// 객체 탐지 결과 처리 및 크롭 서비스
class ObjectCropService {
  final GalleryService _galleryService;
  final OcrQueueService _ocrQueueService = OcrQueueService();
  
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

  /// DetectedObject로 갤러리에 추가 (OCR 연동을 위해)
  void _addDetectedObjectsToGallery(List<Uint8List> croppedImages, List<dynamic> detections) {
    print('[GALLERY] Adding ${croppedImages.length} DetectedObjects to gallery');
    
    for (int i = 0; i < croppedImages.length && i < detections.length; i++) {
      try {
        final jpegBytes = croppedImages[i];
        final detection = detections[i];
        final className = detection['className'] as String? ?? 'ID_CARD';
        final confidence = (detection['confidence'] as num?)?.toDouble() ?? 0.0;
        
        final detectedObject = DetectedObject(
          id: 'object_${DateTime.now().millisecondsSinceEpoch}_$i',
          imageBytes: jpegBytes,
          timestamp: DateTime.now(),
          className: className,
          confidence: confidence,
          // OCR 결과는 나중에 업데이트됨
        );
        
        _galleryService.addDetectedObject(detectedObject);
        print('[GALLERY] Added DetectedObject: ${detectedObject.id}');
        
      } catch (e) {
        print('[GALLERY] Error adding DetectedObject $i: $e');
      }
    }
  }

  /// OCR 큐에 기존 JPEG 크롭 이미지들 추가 (기존 로직 재사용)
  void _addToOcrQueue(List<Uint8List> croppedImages, List<dynamic> detections) {
    print('[OCR_QUEUE] Adding ${croppedImages.length} JPEG crops to OCR queue');
    
    for (int i = 0; i < croppedImages.length && i < detections.length; i++) {
      try {
        final jpegBytes = croppedImages[i];
        final detection = detections[i];
        final className = detection['className'] as String? ?? 'ID_CARD';
        final confidence = (detection['confidence'] as num?)?.toDouble() ?? 0.0;
        
        final crop = Crop(
          jpegBytes: jpegBytes,
          id: 'object_${DateTime.now().millisecondsSinceEpoch}_$i', // DetectedObject와 동일한 ID
          timestamp: DateTime.now(),
          className: className,
          confidence: confidence,
        );
        
        // OCR 큐에 추가 (※ label 체크 불필요 - 항상 신분증으로 간주)
        final enqueued = _ocrQueueService.enqueue(crop);
        if (enqueued) {
          print('[OCR_QUEUE] Enqueued: ${crop.debugInfo}');
        } else {
          print('[OCR_QUEUE] Failed to enqueue: ${crop.debugInfo}');
        }
        
      } catch (e) {
        print('[OCR_QUEUE] Error adding crop $i to OCR queue: $e');
      }
    }
  }
  
  /// 메인 처리 함수 - OBB 스트리밍 데이터를 받아서 크롭 처리
  Future<List<Uint8List>> processStreamingData(Map<String, dynamic> data) async {
    print('[YOLO] ═══════════════════════════════════════════════════');
    print('[YOLO] ObjectCropService processing OBB streaming data');
    
    final jpeg = data['originalImage'] as Uint8List?;
    final obbDataRaw = data['detections'] as List<dynamic>?;  // Native 수정 후 OBB 데이터가 detections 키로 전달됨
    
    if (jpeg == null || obbDataRaw == null) {
      print('[CROP] Missing originalImage or OBB data');
      return [];
    }
    
    print('[YOLO] JPEG: ${jpeg.length} bytes');
    print('[YOLO] OBB Data: ${obbDataRaw.length} items');
    
    // ── ① 25% 이상 신뢰도 필터 ─────────────────────────────────────
    final highConfidenceOBBs = _filterHighConfidenceOBBs(obbDataRaw);
    if (highConfidenceOBBs.isEmpty) {
      print('[CROP] No high confidence OBB detections found');
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
    
    // ── ③ OBB 데이터 정리 및 크롭 방식 결정 ────────────────────────────────
    final (polygonsList, fallbackRects) = _extractOBBDataForCrop(highConfidenceOBBs, finalImageSize);
    
    List<Uint8List> croppedImages = [];
    
    // ── ④-A 정확한 polygon 크롭 실행 (1순위) ────────────────────────────────
    if (polygonsList.isNotEmpty) {
      print('[CROP] Using precise polygon cropping for ${polygonsList.length} OBB objects');
      croppedImages = await ImageProcessingService.cropMultipleOBBsWithPolygonMask(
        imageBytes: jpeg,
        polygonsList: polygonsList,
        needsRotation: needsRotation,
        maskColor: 0xFF000000, // 검은색 마스킹 (OCR에 최적)
      );
    } 
    // ── ④-B 대안 직사각형 크롭 실행 (2순위) ────────────────────────────────
    else if (fallbackRects.isNotEmpty) {
      print('[CROP] Using fallback rectangular cropping for ${fallbackRects.length} objects');
      croppedImages = await ImageProcessingService.cropMultipleObjectsWithMask(
        imageBytes: jpeg,
        cropRects: fallbackRects,
        needsRotation: needsRotation,
        maskColor: 0xFF000000, // 검은색 마스킹 (OCR에 최적)
      );
    } else {
      print('[CROP] No valid OBB data found for cropping');
      return [];
    }
    
    if (croppedImages.isNotEmpty) {
      // (A) 마스킹된 이미지들을 갤러리에 추가
      _galleryService.addCroppedImages(croppedImages);
      print('[CROP] ${croppedImages.length} OBB objects masked & cropped for OCR, total gallery: ${_galleryService.count}');
      
      // (A-2) DetectedObject로 갤러리에 추가 (OCR 연동을 위해)
      _addOBBDetectedObjectsToGallery(croppedImages, highConfidenceOBBs);
      
      // (B) OCR 큐에 기존 JPEG 크롭 추가
      _addOBBToOcrQueue(croppedImages, highConfidenceOBBs);
    }
    
    return croppedImages;
  }

  /// OBB 데이터로부터 고신뢰도 탐지 결과 필터링 (25% 이상)
  List<dynamic> _filterHighConfidenceOBBs(List<dynamic>? obbDataRaw, {double threshold = 0.25}) {
    if (obbDataRaw == null) return [];
    
    return obbDataRaw.where((obb) => (obb['confidence'] as num) >= threshold).toList();
  }
  
  /// OBB 데이터를 polygon과 fallback rects로 분류 (정확한 크롭을 위해)
  (List<List<Map<String, double>>>, List<Rect>) _extractOBBDataForCrop(List<dynamic> obbData, Size finalImageSize) {
    final polygonsList = <List<Map<String, double>>>[];
    final fallbackRects = <Rect>[];
    
    for (int i = 0; i < obbData.length; i++) {
      final obb = obbData[i];
      final className = obb['className'] as String? ?? 'unknown';
      final confidence = (obb['confidence'] as num).toDouble();
      
      print('[CROP][$i] $className (${(confidence * 100).toStringAsFixed(1)}%)');
      
      // ✅ 1순위: polygon 데이터 사용 (정확한 OBB 크롭)
      final polygonPixels = obb['polygon'] as List<dynamic>?;
      if (polygonPixels != null && polygonPixels.length >= 4) {
        print('[CROP][$i] Found polygon data (precise OBB) - ${polygonPixels.length} points');
        
        final polygonPoints = <Map<String, double>>[];
        for (final point in polygonPixels) {
          final x = (point['x'] as num).toDouble();
          final y = (point['y'] as num).toDouble();
          polygonPoints.add({'x': x, 'y': y});
          print('[CROP][$i] Polygon point: ($x, $y)');
        }
        
        polygonsList.add(polygonPoints);
        print('[CROP][$i] ✅ Added to polygon cropping list');
        continue;
      }
      
      // 2순위: boundingBox를 fallback으로 사용
      final boundingBox = obb['boundingBox'] as Map?;
      if (boundingBox != null) {
        print('[CROP][$i] Using boundingBox as fallback');
        
        final left = (boundingBox['left'] as num).toDouble();
        final top = (boundingBox['top'] as num).toDouble();
        final right = (boundingBox['right'] as num).toDouble();
        final bottom = (boundingBox['bottom'] as num).toDouble();
        
        final cropRect = Rect.fromLTRB(left, top, right, bottom);
        print('[CROP][$i] BoundingBox rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
        
        if (cropRect.width > 10 && cropRect.height > 10) {
          fallbackRects.add(cropRect);
          print('[CROP][$i] ✅ Added to fallback rect cropping list');
        } else {
          print('[CROP][$i] Skipped boundingBox - too small: ${cropRect.width}x${cropRect.height}');
        }
        continue;
      }
      
      print('[CROP][$i] ❌ No usable polygon or boundingBox data');
    }
    
    print('[CROP] Summary: ${polygonsList.length} polygons, ${fallbackRects.length} fallback rects');
    return (polygonsList, fallbackRects);
  }

  /// OBB 탐지 결과로부터 크롭 영역들 추출 (polygon 우선, AABB 대안) - 기존 호환성 유지
  List<Rect> _extractOBBCropRegions(List<dynamic> obbData, Size finalImageSize) {
    final cropRects = <Rect>[];
    
    for (int i = 0; i < obbData.length; i++) {
      final obb = obbData[i];
      final className = obb['className'] as String? ?? 'unknown';
      final confidence = (obb['confidence'] as num).toDouble();
      
      print('[CROP][$i] $className (${(confidence * 100).toStringAsFixed(1)}%)');
      
      // ✅ 1순위: polygon 데이터 사용 (정확한 OBB 크롭을 위해)
      final polygonPixels = obb['polygon'] as List<dynamic>?;
      if (polygonPixels != null && polygonPixels.length >= 4) {
        print('[CROP][$i] Using polygon data (precise OBB)');
        
        // 4개 코너 포인트에서 최소 회전 바운딩 박스 계산
        double minX = double.infinity;
        double maxX = double.negativeInfinity;
        double minY = double.infinity;
        double maxY = double.negativeInfinity;
        
        for (final point in polygonPixels) {
          final x = (point['x'] as num).toDouble();
          final y = (point['y'] as num).toDouble();
          
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
          
          print('[CROP][$i] Polygon point: ($x, $y)');
        }
        
        final cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);
        print('[CROP][$i] Polygon->AABB rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
        
        if (cropRect.width > 10 && cropRect.height > 10) {
          cropRects.add(cropRect);
          print('[CROP][$i] ✅ Added polygon-based crop rect: ${cropRect.width.toInt()}x${cropRect.height.toInt()}');
        } else {
          print('[CROP][$i] Skipped polygon - too small: ${cropRect.width}x${cropRect.height}');
        }
        continue;
      }
      
      // 2순위: boundingBox 사용 (이미 픽셀 좌표로 계산됨)
      final boundingBox = obb['boundingBox'] as Map?;
      if (boundingBox != null) {
        print('[CROP][$i] Using boundingBox (fallback AABB)');
        
        final left = (boundingBox['left'] as num).toDouble();
        final top = (boundingBox['top'] as num).toDouble();
        final right = (boundingBox['right'] as num).toDouble();
        final bottom = (boundingBox['bottom'] as num).toDouble();
        
        final cropRect = Rect.fromLTRB(left, top, right, bottom);
        print('[CROP][$i] BoundingBox rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
        
        if (cropRect.width > 10 && cropRect.height > 10) {
          cropRects.add(cropRect);
          print('[CROP][$i] ✅ Added boundingBox crop rect: ${cropRect.width.toInt()}x${cropRect.height.toInt()}');
        } else {
          print('[CROP][$i] Skipped boundingBox - too small: ${cropRect.width}x${cropRect.height}');
        }
        continue;
      }
      
      // 3순위: OBB 내부 데이터에서 계산 (최후의 수단)
      final obbDataInner = obb['obb'] as Map?;
      if (obbDataInner == null) {
        print('[CROP][$i] ❌ No polygon, boundingBox, or OBB data found');
        continue;
      }
      
      final points = obbDataInner['points'] as List<dynamic>?;
      if (points == null || points.length < 4) {
        print('[CROP][$i] ❌ Invalid or missing OBB points data');
        continue;
      }
      
      print('[CROP][$i] Using OBB inner points (last resort)');
      
      // 정규화된 좌표를 픽셀 좌표로 변환
      double minX = double.infinity;
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;
      
      for (final point in points) {
        final x = (point['x'] as num).toDouble() * finalImageSize.width;
        final y = (point['y'] as num).toDouble() * finalImageSize.height;
        
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
      
      final cropRect = Rect.fromLTRB(minX, minY, maxX, maxY);
      print('[CROP][$i] OBB->AABB rect: $cropRect (w=${cropRect.width}, h=${cropRect.height})');
      
      if (cropRect.width > 10 && cropRect.height > 10) {
        cropRects.add(cropRect);
        print('[CROP][$i] ✅ Added OBB-based crop rect: ${cropRect.width.toInt()}x${cropRect.height.toInt()}');
      } else {
        print('[CROP][$i] Skipped OBB - too small: ${cropRect.width}x${cropRect.height}');
      }
    }
    
    return cropRects;
  }

  /// OBB DetectedObject로 갤러리에 추가 (OCR 연동을 위해)
  void _addOBBDetectedObjectsToGallery(List<Uint8List> croppedImages, List<dynamic> obbData) {
    print('[GALLERY] Adding ${croppedImages.length} OBB DetectedObjects to gallery');
    
    for (int i = 0; i < croppedImages.length && i < obbData.length; i++) {
      try {
        final jpegBytes = croppedImages[i];
        final obb = obbData[i];
        final className = obb['className'] as String? ?? 'ID_CARD';
        final confidence = (obb['confidence'] as num?)?.toDouble() ?? 0.0;
        
        final detectedObject = DetectedObject(
          id: 'obb_object_${DateTime.now().millisecondsSinceEpoch}_$i',
          imageBytes: jpegBytes,
          timestamp: DateTime.now(),
          className: className,
          confidence: confidence,
          // OCR 결과는 나중에 업데이트됨
        );
        
        _galleryService.addDetectedObject(detectedObject);
        print('[GALLERY] Added OBB DetectedObject: ${detectedObject.id}');
        
      } catch (e) {
        print('[GALLERY] Error adding OBB DetectedObject $i: $e');
      }
    }
  }

  /// OBB OCR 큐에 크롭 이미지들 추가
  void _addOBBToOcrQueue(List<Uint8List> croppedImages, List<dynamic> obbData) {
    print('[OCR_QUEUE] Adding ${croppedImages.length} OBB JPEG crops to OCR queue');
    
    for (int i = 0; i < croppedImages.length && i < obbData.length; i++) {
      try {
        final jpegBytes = croppedImages[i];
        final obb = obbData[i];
        final className = obb['className'] as String? ?? 'ID_CARD';
        final confidence = (obb['confidence'] as num?)?.toDouble() ?? 0.0;
        
        final crop = Crop(
          jpegBytes: jpegBytes,
          id: 'obb_object_${DateTime.now().millisecondsSinceEpoch}_$i', // DetectedObject와 동일한 ID
          timestamp: DateTime.now(),
          className: className,
          confidence: confidence,
        );
        
        // OCR 큐에 추가 (※ label 체크 불필요 - 항상 신분증으로 간주)
        final enqueued = _ocrQueueService.enqueue(crop);
        if (enqueued) {
          print('[OCR_QUEUE] Enqueued OBB: ${crop.debugInfo}');
        } else {
          print('[OCR_QUEUE] Failed to enqueue OBB: ${crop.debugInfo}');
        }
        
      } catch (e) {
        print('[OCR_QUEUE] Error adding OBB crop $i to OCR queue: $e');
      }
    }
  }
} 