import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';

class BFBankMainPage extends StatefulWidget {
  const BFBankMainPage({Key? key}) : super(key: key);

  @override
  State<BFBankMainPage> createState() => _BFBankMainPageState();
}

class _BFBankMainPageState extends State<BFBankMainPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  late String userName;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
    // 페이지 진입 시 자동으로 TTS 안내와 환영 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeUser();
    });
  }

  void _loadUserData() {
    final user = IntegratedDummyDataService.getCurrentUser();
    userName = user.username;
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
    // 메인 화면 음성 안내
    const guide = '''메인 화면입니다.
결제를 원하시면 왼쪽 위,
설정을 원하시면 오른쪽 위,
계좌 조회를 원하시면 왼쪽 아래,
송금을 원하시면 오른쪽 아래를 눌러주세요.''';
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
            'assets/icons/QR.svg',
            '결제',
          ),
          upperRightWidget: _buildButtonContent(
            'assets/icons/Settings2.svg',
            '설정',
          ),
          lowerLeftWidget: _buildButtonContent(
            'assets/icons/History2.svg',
            '조회',
          ),
          lowerRightWidget: _buildButtonContent(
            'assets/icons/Send2.svg',
            '송금',
          ),
          mainWidget: _buildMainContent(),
          onUpperLeftPress: () => _handleNavigation(context, '결제'),
          onUpperRightPress: () => _handleNavigation(context, '설정'),
          onLowerLeftPress: () => _handleNavigation(context, '조회'),
          onLowerRightPress: () => _handleNavigation(context, '송금'),
          // 더블탭 TTS 메시지들
          upperLeftTTS: '결제',
          upperRightTTS: '설정',
          lowerLeftTTS: '조회',
          lowerRightTTS: '송금',
        ),
      ),
    );
  }

  Widget _buildButtonContent(String asset, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          width: 48, // 아이콘 크기 줄임
          height: 48,
          color: Colors.white,
        ),
        const SizedBox(height: 6), // 간격 줄임
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24, // 폰트 크기 줄임
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

      ],
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
    
    // 실제 페이지 이동 또는 임시 다이얼로그
    switch (feature) {
      case '결제':
        Navigator.pushNamed(context, '/payment');
        break;
      case '송금':
        Navigator.pushNamed(context, '/send-main');
        break;
      case '조회':
        Navigator.pushNamed(context, '/check-history');
        break;
      case '설정':
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        // 다른 기능들은 임시로 다이얼로그 표시
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
        break;
    }
  }
} 