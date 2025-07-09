import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/user_state_service.dart';

class BFBankMainPage extends StatefulWidget {
  const BFBankMainPage({Key? key}) : super(key: key);

  @override
  State<BFBankMainPage> createState() => _BFBankMainPageState();
}

class _BFBankMainPageState extends State<BFBankMainPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final UserStateService _userStateService = UserStateService();
  
  String? userName;
  bool hasAccount = false;
  bool isLoading = true;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지로 돌아올 때마다 사용자 상태 새로고침
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _userStateService.initialize();
      final user = await IntegratedDummyDataService.getCurrentUser();
      final accountStatus = await _userStateService.hasAccount();
      
      setState(() {
        userName = user?.username;
        hasAccount = accountStatus;
        isLoading = false;
      });
    } catch (e) {
      print('Failed to load user data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
    String guide;
    
    if (hasAccount) {
      guide = '''메인 화면입니다.
결제를 원하시면 왼쪽 위,
설정을 원하시면 오른쪽 위,
계좌 조회를 원하시면 왼쪽 아래,
송금을 원하시면 오른쪽 아래를 눌러주세요.''';
    } else {
      guide = '''BF Bank 환영 화면입니다.
설정을 원하시면 왼쪽 위,
신분증 인식 디버깅을 원하시면 오른쪽 위,
더미데이터 모드로 전환하시려면 왼쪽 아래,
계좌를 개설하시려면 오른쪽 아래를 눌러주세요.''';
    }
    
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                '사용자 정보를 불러오는 중...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: hasAccount ? _buildBankingUI() : _buildAccountCreationUI(),
      ),
    );
  }

  // 계좌가 있는 사용자용 UI (기존 뱅킹 메뉴)
  Widget _buildBankingUI() {
    return DefaultPage(
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
    );
  }

  // 계좌가 없는 사용자용 UI (계좌 개설 중심)
  Widget _buildAccountCreationUI() {
    return DefaultPage(
      upperLeftWidget: _buildButtonContent(
        'assets/icons/Settings2.svg',
        '설정',
      ),
      upperRightWidget: _buildButtonContent(
        'assets/icons/Check2.svg',
        '신분증\n디버깅',
      ),
      lowerLeftWidget: _buildButtonContent(
        'assets/icons/Volume.svg',
        '더미데이터\n모드',
      ),
      lowerRightWidget: _buildButtonContent(
        'assets/icons/Check.svg',
        '계좌\n개설하기',
      ),
      mainWidget: _buildWelcomeCard(),
      onUpperLeftPress: () => _handleAccountCreationNavigation(context, '설정'),
      onUpperRightPress: () => _handleAccountCreationNavigation(context, '신분증 디버깅'),
      onLowerLeftPress: () => _handleAccountCreationNavigation(context, '더미데이터 모드'),
      onLowerRightPress: () => _handleAccountCreationNavigation(context, '계좌 개설하기'),
      // 더블탭 TTS 메시지들
      upperLeftTTS: '설정',
      upperRightTTS: '신분증 인식 디버깅',
      lowerLeftTTS: '더미데이터 모드',
      lowerRightTTS: '계좌 개설하기',
    );
  }

  // 환영 카드 위젯
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // BF Bank 로고
          const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 24),
          
          // 환영 메시지
          const Text(
            'BF Bank에 오신 것을\n환영합니다!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // 서브 메시지
          const Text(
            '배리어 프리 금융 서비스로\n모든 고객에게 편리한 뱅킹을 제공합니다',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // 음성 안내 버튼
          GestureDetector(
            onTap: () {
              _hapticService.vibrateCustomSequence('tick');
              _speakMainScreenGuide();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '음성 안내 듣기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 계좌 개설 화면용 네비게이션 핸들러
  void _handleAccountCreationNavigation(BuildContext context, String feature) {
    String hapticPattern;
    switch (feature) {
      case '설정':
        hapticPattern = 'tick';
        break;
      case '신분증 디버깅':
        hapticPattern = 'double_tick';
        break;
      case '더미데이터 모드':
        hapticPattern = 'notification';
        break;
      case '계좌 개설하기':
        hapticPattern = 'cheerful_success';
        break;
      default:
        hapticPattern = 'tick';
    }
    
    _hapticService.vibrateCustomSequence(hapticPattern);
    _ttsService.speak('$feature을 선택하셨습니다.');
    
    switch (feature) {
      case '설정':
        Navigator.pushNamed(context, '/settings');
        break;
      case '신분증 디버깅':
        Navigator.pushNamed(context, '/developer-options');
        break;
      case '더미데이터 모드':
        _enableDummyDataMode();
        break;
      case '계좌 개설하기':
        Navigator.pushNamed(context, '/create-account');
        break;
    }
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 25,
                ),
                SizedBox(width: 12),
                Text(
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
          '${userName ?? "고객"} 님,\n환영합니다.',
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

  // 더미 데이터 모드로 전환
  Future<void> _enableDummyDataMode() async {
    try {
      _hapticService.vibrateCustomSequence('notification');
      _ttsService.speak('더미 데이터 모드로 전환합니다.');
      
      await _userStateService.enableDummyDataMode();
      
      // 상태 새로고침
      await _loadUserData();
      
      _ttsService.speak('더미 데이터 모드로 전환되었습니다. 모든 뱅킹 서비스를 이용할 수 있습니다.');
    } catch (e) {
      print('Failed to enable dummy data mode: $e');
      _ttsService.speak('더미 데이터 모드 전환에 실패했습니다.');
    }
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