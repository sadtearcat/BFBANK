import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/models/detected_object.dart';
import '../features/object_ocr/models/ocr_result.dart';

class GalleryService extends ChangeNotifier {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  final List<Uint8List> _croppedImages = []; // 기존 호환성 유지
  final List<DetectedObject> _detectedObjects = []; // OCR 포함 객체들
  
  List<Uint8List> get croppedImages => List.unmodifiable(_croppedImages);
  List<DetectedObject> get detectedObjects => List.unmodifiable(_detectedObjects);
  int get count => _croppedImages.length;
  bool get isEmpty => _croppedImages.isEmpty;
  bool get isNotEmpty => _croppedImages.isNotEmpty;

  void addCroppedImages(List<Uint8List> images) {
    _croppedImages.addAll(images);
    
    // 메모리 관리: 최대 100개까지만 유지
    if (_croppedImages.length > 100) {
      _croppedImages.removeRange(0, _croppedImages.length - 100);
    }
    
    notifyListeners();
  }

  void addCroppedImage(Uint8List image) {
    _croppedImages.add(image);
    
    // 메모리 관리: 최대 100개까지만 유지
    if (_croppedImages.length > 100) {
      _croppedImages.removeAt(0);
    }
    
    notifyListeners();
  }

  /// DetectedObject 추가 (OCR 결과 포함)
  void addDetectedObject(DetectedObject object) {
    _detectedObjects.add(object);
    
    // 메모리 관리: 최대 100개까지만 유지
    if (_detectedObjects.length > 100) {
      _detectedObjects.removeAt(0);
    }
    
    notifyListeners();
  }

  /// 여러 DetectedObject 추가
  void addDetectedObjects(List<DetectedObject> objects) {
    _detectedObjects.addAll(objects);
    
    // 메모리 관리: 최대 100개까지만 유지
    if (_detectedObjects.length > 100) {
      _detectedObjects.removeRange(0, _detectedObjects.length - 100);
    }
    
    notifyListeners();
  }

  /// ID로 DetectedObject 찾기
  DetectedObject? findDetectedObjectById(String id) {
    try {
      return _detectedObjects.firstWhere((obj) => obj.id == id);
    } catch (e) {
      return null;
    }
  }

  /// OCR 결과 업데이트
  void updateOcrResult(String objectId, String ocrText) {
    for (int i = 0; i < _detectedObjects.length; i++) {
      if (_detectedObjects[i].id == objectId) {
        _detectedObjects[i] = _detectedObjects[i].withOcrText(ocrText);
        notifyListeners();
        break;
      }
    }
  }

  /// OCR 결과와 신뢰도 업데이트 (새로운 메서드)
  void updateOcrResultWithConfidence(String objectId, String ocrText, double confidence) {
    for (int i = 0; i < _detectedObjects.length; i++) {
      if (_detectedObjects[i].id == objectId) {
        _detectedObjects[i] = _detectedObjects[i].withOcrResult(ocrText, confidence);
        notifyListeners();
        break;
      }
    }
  }

  /// 상세한 OCR 결과 업데이트 (박스 정보 포함)
  void updateDetailedOcrResult(String objectId, OcrResult ocrResult) {
    for (int i = 0; i < _detectedObjects.length; i++) {
      if (_detectedObjects[i].id == objectId) {
        _detectedObjects[i] = _detectedObjects[i].withDetailedOcrResult(ocrResult);
        notifyListeners();
        break;
      }
    }
  }

  void clearAll() {
    _croppedImages.clear();
    _detectedObjects.clear();
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _croppedImages.length) {
      _croppedImages.removeAt(index);
      notifyListeners();
    }
  }
} 