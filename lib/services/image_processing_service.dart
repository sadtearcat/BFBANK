import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 이미지 처리 (회전, 크롭) 서비스
class ImageProcessingService {
  /// Isolate에서 실행되는 크롭 함수 (기존 로직 유지)
  static Future<Uint8List> _cropInIsolate(Map<String, dynamic> params) async {
    final originalBytes = params['bytes'] as Uint8List;
    final rect = params['rect'] as Rect;
    final needsRotation = params['needsRotation'] as bool;
    
    var src = img.decodeImage(originalBytes)!;
    
    // Portrait 모드에서는 90도 회전하여 boundingBox와 좌표계 맞춤
    if (needsRotation) {
      src = img.copyRotate(src, angle: 90);
      print('[CROP] Image rotated 90° for Portrait mode: ${src.width}x${src.height}');
    }
    
    final cropped = img.copyCrop(
      src,
      x: rect.left.round(),
      y: rect.top.round(),
      width: rect.width.round(),
      height: rect.height.round(),
    );
    
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  }

  /// Isolate에서 실행되는 마스킹 크롭 함수 (OCR 최적화)
  static Future<Uint8List> _cropWithMaskInIsolate(Map<String, dynamic> params) async {
    final originalBytes = params['bytes'] as Uint8List;
    final rect = params['rect'] as Rect;
    final needsRotation = params['needsRotation'] as bool;
    final maskColor = params['maskColor'] as int? ?? 0xFF000000; // 기본 검은색
    
    var src = img.decodeImage(originalBytes)!;
    
    // Portrait 모드에서는 90도 회전하여 boundingBox와 좌표계 맞춤
    if (needsRotation) {
      src = img.copyRotate(src, angle: 90);
      print('[CROP] Image rotated 90° for Portrait mode: ${src.width}x${src.height}');
    }
    
    // 원본 이미지 크기 유지하면서 크롭 영역 외부를 마스킹
    final maskedImage = img.Image.from(src);
    
    // 크롭 영역 외부를 마스킹 처리
    final cropLeft = rect.left.round();
    final cropTop = rect.top.round();
    final cropRight = (rect.left + rect.width).round();
    final cropBottom = (rect.top + rect.height).round();
    
    for (int y = 0; y < maskedImage.height; y++) {
      for (int x = 0; x < maskedImage.width; x++) {
        // 크롭 영역 외부인 경우 마스킹
        if (x < cropLeft || x >= cropRight || y < cropTop || y >= cropBottom) {
          maskedImage.setPixel(x, y, img.ColorRgba8(
            (maskColor >> 16) & 0xFF, // R
            (maskColor >> 8) & 0xFF,  // G
            maskColor & 0xFF,         // B
            255,                      // A (완전 불투명)
          ));
        }
      }
    }
    
    return Uint8List.fromList(img.encodeJpg(maskedImage, quality: 90));
  }

  /// Isolate에서 실행되는 polygon 마스킹 크롭 함수 (정확한 OBB 크롭)
  static Future<Uint8List> _cropWithPolygonMaskInIsolate(Map<String, dynamic> params) async {
    final originalBytes = params['bytes'] as Uint8List;
    final polygonPoints = params['polygonPoints'] as List<Map<String, double>>;
    final needsRotation = params['needsRotation'] as bool;
    final maskColor = params['maskColor'] as int? ?? 0xFF000000; // 기본 검은색
    
    var src = img.decodeImage(originalBytes)!;
    
    // Portrait 모드에서는 90도 회전하여 boundingBox와 좌표계 맞춤
    if (needsRotation) {
      src = img.copyRotate(src, angle: 90);
      print('[CROP] Image rotated 90° for Portrait mode: ${src.width}x${src.height}');
    }
    
    // 원본 이미지 크기 유지하면서 polygon 영역 외부를 마스킹
    final maskedImage = img.Image.from(src);
    
    // Polygon 외부를 마스킹 처리 (점-다각형 내부 판정 알고리즘)
    for (int y = 0; y < maskedImage.height; y++) {
      for (int x = 0; x < maskedImage.width; x++) {
        // 현재 픽셀이 polygon 내부에 있는지 확인
        if (!_isPointInPolygon(x.toDouble(), y.toDouble(), polygonPoints)) {
          // Polygon 외부인 경우 마스킹
          maskedImage.setPixel(x, y, img.ColorRgba8(
            (maskColor >> 16) & 0xFF, // R
            (maskColor >> 8) & 0xFF,  // G
            maskColor & 0xFF,         // B
            255,                      // A (완전 불투명)
          ));
        }
      }
    }
    
    return Uint8List.fromList(img.encodeJpg(maskedImage, quality: 90));
  }

  /// 점이 다각형 내부에 있는지 확인 (Ray Casting Algorithm)
  static bool _isPointInPolygon(double x, double y, List<Map<String, double>> polygon) {
    int intersections = 0;
    int n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final xi = polygon[i]['x']!;
      final yi = polygon[i]['y']!;
      final xj = polygon[j]['x']!;
      final yj = polygon[j]['y']!;
      
      if (((yi > y) != (yj > y)) && 
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        intersections++;
      }
    }
    
    return (intersections % 2) == 1;
  }

  /// 단일 객체 크롭 처리
  static Future<Uint8List?> cropSingleObject({
    required Uint8List imageBytes,
    required Rect cropRect,
    required bool needsRotation,
  }) async {
    if (cropRect.width <= 10 || cropRect.height <= 10) {
      print('[CROP] Skipped - too small: ${cropRect.width}x${cropRect.height}');
      return null;
    }
    
    return await compute(_cropInIsolate, {
      'bytes': imageBytes,
      'rect': cropRect,
      'needsRotation': needsRotation,
    });
  }
  
  /// 여러 객체 동시 크롭 처리 (기존 로직 그대로 유지)
  static Future<List<Uint8List>> cropMultipleObjects({
    required Uint8List imageBytes,
    required List<Rect> cropRects,
    required bool needsRotation,
  }) async {
    final futures = cropRects
        .where((rect) => rect.width > 10 && rect.height > 10)
        .map((rect) => compute(_cropInIsolate, {
              'bytes': imageBytes,
              'rect': rect,
              'needsRotation': needsRotation,
            }))
        .toList();
    
    if (futures.isEmpty) return [];
    
    return await Future.wait(futures);
  }

  /// 단일 객체 마스킹 크롭 처리 (OCR 최적화)
  static Future<Uint8List?> cropSingleObjectWithMask({
    required Uint8List imageBytes,
    required Rect cropRect,
    required bool needsRotation,
    int maskColor = 0xFF000000, // 기본 검은색
  }) async {
    if (cropRect.width <= 10 || cropRect.height <= 10) {
      print('[CROP] Skipped - too small: ${cropRect.width}x${cropRect.height}');
      return null;
    }
    
    return await compute(_cropWithMaskInIsolate, {
      'bytes': imageBytes,
      'rect': cropRect,
      'needsRotation': needsRotation,
      'maskColor': maskColor,
    });
  }

  /// 여러 객체 동시 마스킹 크롭 처리 (OCR 최적화)
  static Future<List<Uint8List>> cropMultipleObjectsWithMask({
    required Uint8List imageBytes,
    required List<Rect> cropRects,
    required bool needsRotation,
    int maskColor = 0xFF000000, // 기본 검은색
  }) async {
    final futures = cropRects
        .where((rect) => rect.width > 10 && rect.height > 10)
        .map((rect) => compute(_cropWithMaskInIsolate, {
              'bytes': imageBytes,
              'rect': rect,
              'needsRotation': needsRotation,
              'maskColor': maskColor,
            }))
        .toList();
    
    if (futures.isEmpty) return [];
    
    return await Future.wait(futures);
  }

  /// 단일 OBB polygon 마스킹 크롭 처리 (정확한 OBB 크롭)
  static Future<Uint8List?> cropSingleOBBWithPolygonMask({
    required Uint8List imageBytes,
    required List<Map<String, double>> polygonPoints,
    required bool needsRotation,
    int maskColor = 0xFF000000, // 기본 검은색
  }) async {
    if (polygonPoints.length < 3) {
      print('[CROP] Skipped - invalid polygon: ${polygonPoints.length} points');
      return null;
    }
    
    return await compute(_cropWithPolygonMaskInIsolate, {
      'bytes': imageBytes,
      'polygonPoints': polygonPoints,
      'needsRotation': needsRotation,
      'maskColor': maskColor,
    });
  }

  /// 여러 OBB polygon 동시 마스킹 크롭 처리 (정확한 OBB 크롭)
  static Future<List<Uint8List>> cropMultipleOBBsWithPolygonMask({
    required Uint8List imageBytes,
    required List<List<Map<String, double>>> polygonsList,
    required bool needsRotation,
    int maskColor = 0xFF000000, // 기본 검은색
  }) async {
    final futures = polygonsList
        .where((polygon) => polygon.length >= 3)
        .map((polygon) => compute(_cropWithPolygonMaskInIsolate, {
              'bytes': imageBytes,
              'polygonPoints': polygon,
              'needsRotation': needsRotation,
              'maskColor': maskColor,
            }))
        .toList();
    
    if (futures.isEmpty) return [];
    
    return await Future.wait(futures);
  }

  /// 이미지 크기 정보 추출
  static Future<Size> getImageSize(Uint8List imageBytes) async {
    final codec = await instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();
    codec.dispose();
    return size;
  }
} 