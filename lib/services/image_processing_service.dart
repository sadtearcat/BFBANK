import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 이미지 처리 (회전, 크롭) 서비스
class ImageProcessingService {
  /// Isolate에서 실행되는 크롭 함수
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
  
  /// 여러 객체 동시 크롭 처리
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