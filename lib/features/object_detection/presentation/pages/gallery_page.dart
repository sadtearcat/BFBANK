import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../services/gallery_service.dart';
import '../../../../core/models/detected_object.dart';
import '../../../object_ocr/object_ocr.dart';

class GalleryPage extends StatefulWidget {
  final List<Uint8List> croppedImages;
  
  const GalleryPage({
    super.key,
    required this.croppedImages,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final GalleryService _galleryService = GalleryService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Objects with OCR Results',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_galleryService.detectedObjects.length} items',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ),
        ],
      ),
      body: _galleryService.detectedObjects.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.text_fields,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No objects with OCR yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Go to camera and point at objects\nOCR results will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _galleryService.detectedObjects.length,
              itemBuilder: (context, index) {
                final detectedObject = _galleryService.detectedObjects[index];
                return GestureDetector(
                  onTap: () => _showFullScreenObject(context, index),
                  child: Hero(
                    tag: 'detected_object_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: detectedObject.hasOcrText 
                            ? Colors.green.withOpacity(0.7)
                            : Colors.blue.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 이미지 부분
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                              child: OcrOverlayWidget(
                                ocrResult: detectedObject.ocrResult,
                                showBoxes: detectedObject.ocrResult != null,
                                showConfidence: true,
                                confidenceThreshold: 0.6,
                                child: Image.memory(
                                  detectedObject.imageBytes,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // OCR 결과 부분
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: detectedObject.hasOcrText 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              detectedObject.hasOcrText 
                                ? detectedObject.ocrText!
                                : 'Processing OCR...',
                              style: TextStyle(
                                color: detectedObject.hasOcrText ? Colors.white : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // OCR 신뢰도 표시 (있는 경우)
                          if (detectedObject.hasOcrConfidence)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Confidence: ${detectedObject.displayOcrConfidence}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFullScreenObject(BuildContext context, int index) {
    final detectedObject = _galleryService.detectedObjects[index];
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _FullScreenObjectPage(
          detectedObject: detectedObject,
          heroTag: 'detected_object_$index',
          objectIndex: index + 1,
          totalObjects: _galleryService.detectedObjects.length,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      ),
    );
  }
}

class _FullScreenObjectPage extends StatelessWidget {
  final DetectedObject detectedObject;
  final String heroTag;
  final int objectIndex;
  final int totalObjects;

  const _FullScreenObjectPage({
    required this.detectedObject,
    required this.heroTag,
    required this.objectIndex,
    required this.totalObjects,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Object $objectIndex of $totalObjects',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 이미지 부분
          Expanded(
            flex: 2,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: OcrOverlayWidget(
                    ocrResult: detectedObject.ocrResult,
                    showBoxes: detectedObject.ocrResult != null,
                    showConfidence: true,
                    confidenceThreshold: 0.6,
                    child: Image.memory(
                      detectedObject.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // OCR 결과 및 정보 부분
          Container(
            width: double.infinity,
            color: Colors.grey[900],
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // OCR 결과
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: detectedObject.hasOcrText ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OCR Result:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: detectedObject.hasOcrText 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: detectedObject.hasOcrText ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    detectedObject.hasOcrText 
                      ? detectedObject.ocrText!
                      : 'OCR processing...',
                    style: TextStyle(
                      color: detectedObject.hasOcrText ? Colors.white : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // OCR 신뢰도 (있는 경우)
                if (detectedObject.hasOcrConfidence) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OCR Confidence: ${detectedObject.displayOcrConfidence}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 추가 정보
                if (detectedObject.className != null) ...[
                  Text(
                    'Class: ${detectedObject.className}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
                if (detectedObject.confidence != null) ...[
                  Text(
                    'YOLO Confidence: ${(detectedObject.confidence! * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Time: ${detectedObject.timestamp.toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 