import 'package:flutter/material.dart';
import '../../../object_detection/presentation/pages/camera_detection_page.dart';
import '../../../object_detection/presentation/pages/gallery_page.dart';
import '../../../../services/gallery_service.dart';

// 홈 페이지
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('BFBANK'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 기능 카드들 (중앙 정렬)
              _buildFeatureCards(context),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 메인 기능 카드
        _FeatureCard(
          icon: Icons.video_camera_front,
          title: '실시간 객체 감지',
          description: '카메라로 실시간 객체를 감지하고\n개별 객체를 크로핑하여 저장합니다',
          color: Colors.green,
          onTap: () => _navigateToCamera(context),
        ),
        const SizedBox(height: 24),
        
        // 갤러리 카드
        _FeatureCard(
          icon: Icons.photo_library,
          title: '갤러리',
          description: '감지된 객체들과 OCR 결과를\n갤러리에서 확인',
          color: Colors.blue,
          onTap: () => _navigateToGallery(context),
        ),
      ],
    );
  }



  void _navigateToCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraDetectionPage(),
      ),
    );
  }

  void _navigateToGallery(BuildContext context) {
    final galleryService = GalleryService();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPage(
          croppedImages: galleryService.croppedImages, // 기존 호환성 유지
        ),
      ),
    );
  }


}

// 기능 카드 위젯
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 