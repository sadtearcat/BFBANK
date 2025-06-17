import 'package:flutter/material.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _playWelcomeTTS();
  }

  Future<void> _initializeServices() async {
    // SettingsStorageService는 자동으로 초기화됨
    setState(() {
      _isInitialized = true;
    });
  }

  void _playWelcomeTTS() {
    Future.delayed(const Duration(milliseconds: 500), () {
      TtsService().speak(
        '안녕하세요. Barrier Free 뱅킹입니다. '
        '한 번 탭하면 화면의 내용을 읽어드리고, '
        '두 번 연속 탭하면 선택이 됩니다. '
        '시작하려면 화면을 두 번 터치해주세요.'
      );
    });
  }

  void _goToMain() {
    if (_isInitialized) {
      Navigator.of(context).pushReplacementNamed('/bfbank-main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: HapticDoubleTapButton(
        onSingleTap: () {
          TtsService().speak('화면을 두 번 터치해서 시작하세요');
        },
        onDoubleTap: _goToMain,
        singleTapHapticType: 'tick',
        doubleTapHapticType: 'double_tick',
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BF Logo
              Container(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/BFLogo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 메인 제목
              const Text(
                '시작하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // 부제목
              const Text(
                '화면을 두 번 터치하세요!',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 35,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 100),
              
              // 음성 안내 버튼
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 20),
                    Text(
                      '음성 안내 듣기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 