import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class GalleryService extends ChangeNotifier {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  final List<Uint8List> _croppedImages = [];
  
  List<Uint8List> get croppedImages => List.unmodifiable(_croppedImages);
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

  void clearAll() {
    _croppedImages.clear();
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _croppedImages.length) {
      _croppedImages.removeAt(index);
      notifyListeners();
    }
  }
} 