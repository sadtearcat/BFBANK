import 'package:flutter/material.dart';
import 'features/navigation/presentation/pages/home_page.dart';
import 'features/object_detection/presentation/pages/camera_detection_page.dart';
import 'features/bfbank/presentation/pages/splash_page.dart';
import 'features/bfbank/presentation/pages/main_page.dart';
import 'features/bfbank/presentation/pages/send_main_page.dart';
import 'features/bfbank/presentation/pages/check_history_page.dart';
import 'features/bfbank/presentation/pages/check_history_detail_page.dart';
import 'features/bfbank/presentation/pages/payment_page.dart';
import 'features/bfbank/presentation/pages/settings_page.dart';
import 'features/handwriting_recognition/widgets/benchmark_test_page.dart';
import 'features/handwriting_recognition/widgets/handwriting_test_page.dart';
import 'features/bfbank/presentation/pages/developer_options_page.dart';

// 앱 라우팅 관리
class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String bfbankMain = '/bfbank-main';
  static const String sendMain = '/send-main';
  static const String checkHistory = '/check-history';
  static const String checkHistoryDetail = '/check-history-detail';
  static const String payment = '/payment';
  static const String settings = '/settings';
  static const String aiTest = '/ai-test';
  static const String benchmarkTest = '/benchmark-test';
  static const String handwritingTest = '/handwriting-test';
  static const String developerOptions = '/developer-options';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 애니메이션 없는 페이지 전환을 위한 공통 함수
    PageRouteBuilder<T> _buildPageWithoutAnimation<T extends Object?>(Widget page) {
      return PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      );
    }

    switch (settings.name) {
      case home:
        return _buildPageWithoutAnimation(const SplashPage());
      case camera:
        return _buildPageWithoutAnimation(const CameraDetectionPage());
      case bfbankMain:
        return _buildPageWithoutAnimation(const BFBankMainPage());
      case sendMain:
        return _buildPageWithoutAnimation(const SendMainPage());
      case checkHistory:
        return _buildPageWithoutAnimation(const CheckHistoryPage());
      case checkHistoryDetail:
        // CheckHistoryDetail은 arguments를 통해 transaction을 받아야 함
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['transaction'] != null) {
          return _buildPageWithoutAnimation(
            CheckHistoryDetailPage(
              transaction: args['transaction'],
            ),
          );
        }
        return _buildPageWithoutAnimation(
          Scaffold(
            body: Center(
              child: Text('거래 내역 정보가 없습니다.'),
            ),
          ),
        );
      case payment:
        return _buildPageWithoutAnimation(const PaymentPage());
      case AppRoutes.settings:
        return _buildPageWithoutAnimation(const SettingsPage());
      case aiTest:
        return _buildPageWithoutAnimation(const HomePage());
      case benchmarkTest:
        return _buildPageWithoutAnimation(const BenchmarkTestPage());
      case handwritingTest:
        return _buildPageWithoutAnimation(const HandwritingTestPage());
      case developerOptions:
        return _buildPageWithoutAnimation(const DeveloperOptionsPage());
      default:
        return _buildPageWithoutAnimation(
          Scaffold(
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