import 'package:flutter/material.dart';
import 'features/navigation/presentation/pages/home_page.dart';
import 'features/object_detection/presentation/pages/camera_detection_page.dart';

// 앱 라우팅 관리
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (context) => const HomePage());
      case camera:
        return MaterialPageRoute(builder: (context) => const CameraDetectionPage());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('페이지를 찾을 수 없습니다: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YOLO 객체 감지 데모'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '실시간 카메라에서 객체를 감지하고 크로핑하는 YOLO 데모입니다.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.camera);
              },
              child: Text('실시간 카메라 감지 시작'),
            ),
          ],
        ),
      ),
    );
  }
} 