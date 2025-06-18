import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';

class SendMainPage extends StatefulWidget {
  const SendMainPage({Key? key}) : super(key: key);

  @override
  State<SendMainPage> createState() => _SendMainPageState();
}

class _SendMainPageState extends State<SendMainPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // 페이지 진입 시 TTS 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
  }

  void _speakPageGuide() {
    _hapticService.vibrateCustomSequence('notification');
    // React Native와 정확히 동일한 메시지
    const guide = '''송금 화면입니다.
계좌 번호를 직접 입력하려면 왼쪽 아래,
최근 계좌를 선택하시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _hapticService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent(
            'assets/icons/ArrowLeft.svg',
            '이전',
          ),
          upperRightWidget: _buildButtonContent(
            'assets/icons/Home.svg',
            '메인',
          ),
          lowerLeftWidget: _buildButtonContent(
            'assets/icons/Draw.svg',
            '입력',
          ),
          lowerRightWidget: _buildButtonContent(
            'assets/icons/Recent.svg',
            '최근',
          ),
          mainWidget: _buildMainContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: () => _handleDirectInput(context),
          onLowerRightPress: () => _handleRecentAccount(context),
          // React Native와 동일한 더블탭 TTS 메시지
          upperLeftTTS: '이전',
          upperRightTTS: '홈',
          lowerLeftTTS: '직접 입력',
          lowerRightTTS: '최근 보낸 계좌',
        ),
      ),
    );
  }

  Widget _buildButtonContent(String asset, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          asset,
          width: 60,
          height: 60,
          color: Colors.white,
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 음성 안내 버튼
        GestureDetector(
          onTap: () {
            _hapticService.vibrateCustomSequence('tick');
            _speakPageGuide();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/Volume.svg', width: 25, height: 25, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  '송금 하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 안내 메시지
        const Text(
          '송금할 계좌를\n입력해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('이전 페이지로 돌아갑니다.');
    Navigator.of(context).pop();
  }

  void _handleHome(BuildContext context) {
    _hapticService.vibrateCustomSequence('double_tick');
    _ttsService.speak('메인 화면으로 이동합니다.');
    // 메인 페이지로 이동 (스택을 모두 제거하고)
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/bfbank-main', 
      (route) => false,
    );
  }

  void _handleDirectInput(BuildContext context) {
    _hapticService.vibrateCustomSequence('warning');
    _ttsService.speak('계좌 번호 직접 입력을 선택하셨습니다.');
    
    // 임시 구현 - 실제로는 SendInputPage로 이동
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('계좌 번호 직접 입력'),
          content: const Text('계좌 번호를 직접 입력하는 페이지로 이동합니다.\n(백엔드 연결 전 임시 화면)'),
          actions: [
            TextButton(
              onPressed: () {
                _hapticService.vibrateCustomSequence('tick');
                Navigator.of(context).pop();
                _ttsService.speak('이전 화면으로 돌아갑니다.');
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _handleRecentAccount(BuildContext context) {
    _hapticService.vibrateCustomSequence('success');
    _ttsService.speak('최근 보낸 계좌를 선택하셨습니다.');
    
    // 임시 구현 - 실제로는 SendRecentAccount로 이동
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('최근 보낸 계좌'),
          content: const Text('최근 송금한 계좌 목록을 보여주는 페이지로 이동합니다.\n(백엔드 연결 전 임시 화면)'),
          actions: [
            TextButton(
              onPressed: () {
                _hapticService.vibrateCustomSequence('tick');
                Navigator.of(context).pop();
                _ttsService.speak('이전 화면으로 돌아갑니다.');
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
} 