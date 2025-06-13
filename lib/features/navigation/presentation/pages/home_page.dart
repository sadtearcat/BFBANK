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
        title: const Text('YOLO 객체 감지 데모'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더 섹션
            _buildHeaderSection(),
            const SizedBox(height: 32),
            
            // 기능 카드들
            _buildFeatureCards(context),
            const SizedBox(height: 32),
            
            // 정보 섹션
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 16),
            Text(
              'YOLO 실시간 객체 감지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Clean Architecture로 구현된\n실시간 카메라 객체 감지 및 크로핑 앱',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        // 메인 기능 카드
        _FeatureCard(
          icon: Icons.video_camera_front,
          title: '실시간 객체 감지',
          description: '카메라로 실시간 객체를 감지하고\n개별 객체를 크로핑하여 저장합니다',
          color: Colors.green,
          onTap: () => _navigateToCamera(context),
        ),
        const SizedBox(height: 16),
        
        // 추가 기능 카드들 (추후 확장용)
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.photo_library,
                title: '갤러리',
                description: '감지된 객체들을\n갤러리에서 확인',
                color: Colors.blue,
                onTap: () => _navigateToGallery(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: Icons.settings,
                title: '설정',
                description: '모델 설정 및\n환경 설정',
                color: Colors.orange,
                onTap: () => _showComingSoon(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기능 특징',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ..._buildFeatureList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      '✨ Clean Architecture 기반 설계',
      '🎯 실시간 YOLO 객체 감지',
      '✂️ 개별 객체 자동 크로핑',
      '📱 직관적인 갤러리 UI',
      '⚡ 최적화된 성능',
      '🔄 Provider 상태 관리',
    ];

    return features.map((feature) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    )).toList();
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
          croppedImages: galleryService.croppedImages,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('곧 출시 예정입니다!'),
        duration: Duration(seconds: 2),
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