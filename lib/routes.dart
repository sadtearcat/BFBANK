import 'package:flutter/material.dart';
import 'features/navigation/presentation/pages/home_page.dart';
import 'features/object_detection/presentation/pages/camera_detection_page.dart';
import 'features/bfbank/presentation/pages/main_page.dart';

// 앱 라우팅 관리
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String bfbankMain = '/bfbank-main';
  static const String aiTest = '/ai-test';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (context) => const BFBankMainPage());
      case camera:
        return MaterialPageRoute(builder: (context) => const CameraDetectionPage());
      case bfbankMain:
        return MaterialPageRoute(builder: (context) => const BFBankMainPage());
      case aiTest:
        return MaterialPageRoute(builder: (context) => const HomePage());
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
        title: Text('BFBANK - Barrier Free Banking'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BFBANK에 오신 것을 환영합니다',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              '장애물 없는 금융 서비스를 경험해보세요.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.bfbankMain);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('BFBank 메인으로 이동', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.camera);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('실시간 카메라 감지 시작', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
} 