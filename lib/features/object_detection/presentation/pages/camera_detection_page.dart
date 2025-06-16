import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';
import '../../../../services/gallery_service.dart';
import '../../../../services/object_crop_service.dart';
import '../../../../services/ocr_queue_service.dart';
import '../../../../core/models/crop.dart';

class CameraDetectionPage extends StatefulWidget {
  const CameraDetectionPage({super.key});

  @override
  State<CameraDetectionPage> createState() => _CameraDetectionPageState();
}

class _CameraDetectionPageState extends State<CameraDetectionPage> {
  // UI 상태 관리
  double _currentFPS = 0.0;
  int _currentDetections = 0;
  
  // 서비스들
  final GalleryService _galleryService = GalleryService();
  final OcrQueueService _ocrQueueService = OcrQueueService();
  late final ObjectCropService _cropService;
  
  // 로컬 갤러리 (최근 몇 개만 미리보기용)
  List<Uint8List> _recentCrops = [];
  
  // OCR 결과
  List<String> _recentOcrResults = [];
  
  // YOLO 컨트롤러
  final YOLOViewController _controller = YOLOViewController();

  @override
  void initState() {
    super.initState();
    
    // 크롭 서비스 초기화
    _cropService = ObjectCropService(_galleryService);
    
    // OCR 큐 시작 (Application 초기화 시 호출)
    _ocrQueueService.start(onOcrReady: _onOcrReady);
    
    print('[INIT] CameraDetectionPage initState called');
    print('[INIT] OCR queue started');
    
    // 위젯 빌드 완료 후 스트리밍 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[INIT] PostFrameCallback: Setting streaming config');
      print('[INIT] Controller initialized: ${_controller.isInitialized}');
      print('[INIT] Widget mounted: $mounted');
      
      if (_controller.isInitialized && mounted) {
        print('[INIT] Applying streaming config for OBB model');
        _controller.setStreamingConfig(
          const YOLOStreamingConfig(
            includeOriginalImage: true,
            includeDetections: true,  // OBB 데이터를 받으려면 true여야 함
            includeOBB: true,
            includeFps: true,
            includeProcessingTimeMs: true,
            maxFPS: 15,  // 15fps로 조절
          ),
        );
        print('[INIT] OBB streaming config applied');
      } else {
        print('[INIT] Skipping config - controller not ready or widget not mounted');
      }
    });
  }
  
  @override
  void dispose() {
    _controller.stop();
    _ocrQueueService.stop();
    super.dispose();
  }
  
  /// OCR 결과 처리 콜백
  void _onOcrReady(Crop crop, String text) {
    if (!mounted) return;
    
    print('[OCR_RESULT] ${crop.debugInfo} -> "$text"');
    
    // 갤러리의 해당 DetectedObject에 OCR 결과 업데이트
    _galleryService.updateOcrResult(crop.id, text);
    
    setState(() {
      _recentOcrResults.add(text);
      
      // 최대 20개까지만 유지
      if (_recentOcrResults.length > 20) {
        _recentOcrResults = _recentOcrResults.sublist(_recentOcrResults.length - 20);
      }
    });
  }

  // 스트리밍 데이터 처리 - OBB 모델 전용
  void _onStreamingData(Map<String, dynamic> data) async {
    if (!mounted) return;
    
    print('[YOLO] ═══════════════════════════════════════════════════');
    print('[YOLO] onStreamingData called with keys: ${data.keys.toList()}');
    
    final fps = (data['fps'] as num?)?.toDouble() ?? 0.0;
    final obbDataRaw = data['detections'] as List<dynamic>?;  // Native 수정 후 OBB 데이터가 detections 키로 전달됨
    
    // UI 상태 업데이트
    setState(() {
      _currentFPS = fps;
      _currentDetections = obbDataRaw?.length ?? 0;
    });
    
    // 크롭 서비스에 위임
    try {
      final croppedImages = await _cropService.processStreamingData(data);
      
      if (croppedImages.isNotEmpty && mounted) {
        setState(() {
          _recentCrops.addAll(croppedImages);
          
          // 로컬 미리보기는 최대 20개까지만 유지
          if (_recentCrops.length > 20) {
            _recentCrops = _recentCrops.sublist(_recentCrops.length - 20);
          }
        });
      }
    } catch (e) {
      print('[CROP] Error processing streaming data: $e');
    }
  }

  // 갤러리 클리어
  void _clearGallery() {
    setState(() {
      _recentCrops.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Object Detection',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          // OCR 큐 상태
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'OCR: ${_ocrQueueService.queueLength}',
              style: TextStyle(
                color: _ocrQueueService.isProcessing ? Colors.red : Colors.purple, 
                fontSize: 12
              ),
            ),
          ),
          // 갤러리 개수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Gallery: ${_galleryService.count}',
              style: const TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
          // 현재 감지 수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Objects: $_currentDetections',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
          // FPS 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'FPS: ${_currentFPS.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 메인 카메라 뷰
          Expanded(
            flex: 3,
            child: YOLOView(
              controller: _controller,
              modelPath: 'yolo8n-obb',
              task: YOLOTask.obb,
              onStreamingData: _onStreamingData,
              streamingConfig: const YOLOStreamingConfig(
                includeOriginalImage: true,
                includeDetections: true,  // OBB 데이터를 받으려면 true여야 함
                includeOBB: true,
                includeFps: true,
                includeProcessingTimeMs: true,
                maxFPS: 15,  // 15fps로 조절
              ),
            ),
          ),
          
          // OCR 결과 섹션
          Container(
            height: 80,
            color: Colors.grey[800],
            child: Column(
              children: [
                // OCR 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.text_fields, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'OCR Results (${_recentOcrResults.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        'Queue: ${_ocrQueueService.queueLength}/${_ocrQueueService.totalProcessed}',
                        style: const TextStyle(color: Colors.purple, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                
                // OCR 결과 리스트
                Expanded(
                  child: _recentOcrResults.isEmpty
                      ? const Center(
                          child: Text(
                            'No OCR results yet',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentOcrResults.length,
                          itemBuilder: (context, index) {
                            return Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.purple.withOpacity(0.5)),
                              ),
                              child: Text(
                                _recentOcrResults[index],
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // 크롭된 이미지 갤러리
          Container(
            height: 120,
            color: Colors.grey[900],
            child: Column(
              children: [
                // 갤러리 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Cropped Objects (${_galleryService.count})',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      if (_recentCrops.isNotEmpty)
                        TextButton.icon(
                          onPressed: _clearGallery,
                          icon: const Icon(Icons.clear_all, color: Colors.red, size: 16),
                          label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                
                // 갤러리 그리드
                Expanded(
                  child: _recentCrops.isEmpty
                      ? const Center(
                          child: Text(
                            'No cropped objects yet\nPoint camera at objects (>70% confidence)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          scrollDirection: Axis.horizontal,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _recentCrops.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                _recentCrops[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 