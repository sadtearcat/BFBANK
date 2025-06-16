import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';

class BFBankMainPage extends StatefulWidget {
  const BFBankMainPage({Key? key}) : super(key: key);

  @override
  State<BFBankMainPage> createState() => _BFBankMainPageState();
}

class _BFBankMainPageState extends State<BFBankMainPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final String userName = "사용자"; // 실제로는 사용자 상태에서 가져와야 함

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // 페이지 진입 시 자동으로 TTS 안내와 환영 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeUser();
    });
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
    // 햅틱 지원 여부 확인
    final supportsHaptic = await _hapticService.canSupportsHaptic();
    print('Haptic support: $supportsHaptic');
  }

  void _welcomeUser() {
    // 환영 햅틱과 TTS
    _hapticService.vibrateCustomSequence('cheerful_success');
    _speakMainScreenGuide();
  }

  void _speakMainScreenGuide() {
    const guide = '''
    메인 화면입니다.
    결제를 원하시면 왼쪽 위,
    설정을 원하시면 오른쪽 위,
    계좌 조회를 원하시면 왼쪽 아래,
    송금을 원하시면 오른쪽 아래를 눌러주세요.
    ''';
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
            Icons.qr_code,
            '결제',
          ),
          upperRightWidget: _buildButtonContent(
            Icons.settings,
            '설정',
          ),
          lowerLeftWidget: _buildButtonContent(
            Icons.history,
            '조회',
          ),
          lowerRightWidget: _buildButtonContent(
            Icons.send,
            '송금',
          ),
          mainWidget: _buildMainContent(),
          onUpperLeftPress: () => _handleNavigation(context, '결제'),
          onUpperRightPress: () => _handleNavigation(context, '설정'),
          onLowerLeftPress: () => _handleNavigation(context, '조회'),
          onLowerRightPress: () => _handleNavigation(context, '송금'),
        ),
      ),
    );
  }

  Widget _buildButtonContent(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 60,
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
        // 음성 안내 버튼 (TTS + Haptic 적용)
        GestureDetector(
          onTap: () {
            // 버튼 클릭 햅틱과 음성 안내
            _hapticService.vibrateCustomSequence('tick');
            _speakMainScreenGuide();
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
                const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 25,
                ),
                const SizedBox(width: 12),
                const Text(
                  '음성 안내 듣기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 환영 메시지
        Text(
          '$userName 님,\n환영합니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 45,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Barrier Free 금융을\n시작합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 28,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 30),
        // 디버그용: 햅틱 테스트 버튼들
        if (const bool.fromEnvironment('dart.vm.product') == false) ...[
          const Text(
            '햅틱 테스트:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              _buildHapticTestButton('성공', 'success'),
              _buildHapticTestButton('에러', 'error'),
              _buildHapticTestButton('경고', 'warning'),
              _buildHapticTestButton('심장박동', 'heartbeat_start'),
              _buildHapticTestButton('중지', 'heartbeat_stop'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHapticTestButton(String label, String hapticType) {
    return ElevatedButton(
      onPressed: () {
        _hapticService.vibrateCustomSequence(hapticType);
        _ttsService.speak('$label 햅틱');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _handleNavigation(BuildContext context, String feature) {
    // 각 기능별 특화된 햅틱 패턴
    String hapticPattern;
    switch (feature) {
      case '결제':
        hapticPattern = 'notification';
        break;
      case '설정':
        hapticPattern = 'tick';
        break;
      case '조회':
        hapticPattern = 'double_tick';
        break;
      case '송금':
        hapticPattern = 'warning';
        break;
      default:
        hapticPattern = 'tick';
    }
    
    // TTS와 햅틱 동시 실행
    _hapticService.vibrateCustomSequence(hapticPattern);
    _ttsService.speak('$feature 기능을 선택하셨습니다.');
    
    // 임시로 다이얼로그 표시 (백엔드 연결 전 확인용)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$feature 기능'),
          content: Text('$feature 기능이 선택되었습니다.\n(백엔드 연결 전 임시 화면)'),
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