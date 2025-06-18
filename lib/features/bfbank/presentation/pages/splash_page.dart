import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/settings_storage_service.dart';
import '../widgets/haptic_button.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // 앱 초기화 작업들
    await Future.delayed(const Duration(milliseconds: 1500)); // 로딩 시간
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/bfbank-main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BF Logo - SVG 사용
            Builder(
              builder: (context) {
                try {
                  return SvgPicture.asset(
                    'assets/icons/BarrierFree.svg',
                    width: 200,
                    height: 200,
                    // Flutter 3.10 이상에서는 colorFilter 사용
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (BuildContext context) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                } catch (e) {
                  // SVG 로딩 실패 시 대체 UI 표시
                  print('SVG 로딩 실패: $e');
                  return Container(
              width: 200,
              height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'BF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 40),
            
            // 앱 이름
            const Text(
              'BFBANK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 부제목
            const Text(
              'Barrier Free Banking',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 20,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 60),
            
            // 로딩 인디케이터
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '앱을 시작하는 중...',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 