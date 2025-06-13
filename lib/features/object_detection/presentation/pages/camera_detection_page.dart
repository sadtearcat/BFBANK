import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_streaming_config.dart';
import '../../../../services/gallery_service.dart';
import '../../../../services/object_crop_service.dart';

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
  late final ObjectCropService _cropService;
  
  // 로컬 갤러리 (최근 몇 개만 미리보기용)
  List<Uint8List> _recentCrops = [];
  
  // YOLO 컨트롤러
  final YOLOViewController _controller = YOLOViewController();

  @override
  void initState() {
    super.initState();
    
    // 크롭 서비스 초기화
    _cropService = ObjectCropService(_galleryService);
    
    print('[INIT] CameraDetectionPage initState called');
    
    // 위젯 빌드 완료 후 스트리밍 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[INIT] PostFrameCallback: Setting streaming config');
      print('[INIT] Controller initialized: ${_controller.isInitialized}');
      print('[INIT] Widget mounted: $mounted');
      
      if (_controller.isInitialized && mounted) {
        print('[INIT] Applying streaming config with originalImage=true');
        _controller.setStreamingConfig(
          const YOLOStreamingConfig(
            includeOriginalImage: true,
            includeDetections: true,
            includeFps: true,
            includeProcessingTimeMs: true,
            maxFPS: 10,
          ),
        );
        print('[INIT] Streaming config applied');
      } else {
        print('[INIT] Skipping config - controller not ready or widget not mounted');
      }
    });
  }
  
  @override
  void dispose() {
    _controller.stop();
    super.dispose();
  }

  // 스트리밍 데이터 처리 - 클린한 버전
  void _onStreamingData(Map<String, dynamic> data) async {
    if (!mounted) return;
    
    print('[YOLO] ═══════════════════════════════════════════════════');
    print('[YOLO] onStreamingData called with keys: ${data.keys.toList()}');
    
    final fps = (data['fps'] as num?)?.toDouble() ?? 0.0;
    final detectionsRaw = data['detections'] as List<dynamic>?;
    
    // UI 상태 업데이트
    setState(() {
      _currentFPS = fps;
      _currentDetections = detectionsRaw?.length ?? 0;
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
              modelPath: 'ddd',
              task: YOLOTask.detect,
              onStreamingData: _onStreamingData,
              streamingConfig: const YOLOStreamingConfig(
                includeOriginalImage: true,
                includeDetections: true,
                includeFps: true,
                includeProcessingTimeMs: true,
                maxFPS: 10,
              ),
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