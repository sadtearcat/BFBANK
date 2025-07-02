import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../../handwriting_recognition/widgets/handwriting_input_modal.dart';
import '../../../handwriting_recognition/widgets/handwriting_overlay_canvas.dart'; // 🔧 ADD: 새로운 오버레이 캔버스
import 'package:gaimon/gaimon.dart';
import 'package:flutter/services.dart';

/// React Native SendMain.tsx를 Flutter로 정확히 마이그레이션
class SendMainPage extends StatefulWidget {
  const SendMainPage({super.key});

  @override
  State<SendMainPage> createState() => _SendMainPageState();
}

class _SendMainPageState extends State<SendMainPage> {
  @override
  void initState() {
    super.initState();
    // React Native와 동일한 TTS 메시지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  void _speakPageGuide() {
    // React Native useTTSOnFocus와 동일한 메시지
    const guide = '''송금 화면입니다.
계좌 번호를 직접 입력하려면 왼쪽 아래,
최근 계좌를 선택하시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    TtsService().speak(guide); // 🔧 실제 TTS 서비스 사용
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // DefaultPage 배경색과 일치
      body: SafeArea(
        child: DefaultPage(
          // 🔧 더블탭 로직이 포함된 DefaultPage 사용
        upperLeftWidget: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_ios, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text('이전', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        upperRightWidget: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text('메인', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        lowerLeftWidget: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text('입력', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        lowerRightWidget: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white, size: 60),
            SizedBox(height: 8),
            Text('최근 계좌', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        mainWidget: Container(
          decoration: const BoxDecoration(
            // React Native 원본과 동일한 그라데이션 배경
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3A8A), // 진한 파란색
                Color(0xFF3B82F6), // 밝은 파란색
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Voice button (React Native 원본과 동일)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, color: Colors.white, size: 30),
                      SizedBox(width: 20),
                      Text(
                        '송금 하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main welcome text (React Native 원본과 동일)
                const Text(
                  '송금할 계좌를\n입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 🔧 더블탭 TTS 메시지 추가 (React Native와 동일)
        upperLeftTTS: '이전',
        upperRightTTS: '메인',
        lowerLeftTTS: '직접 입력',
        lowerRightTTS: '최근 보낸 계좌',
        // 🔧 더블탭 액션 추가
        onUpperLeftPress: () => _handlePressBack(context),
        onUpperRightPress: () => _handlePressHome(context),
        onLowerLeftPress: () => _handleDirectInput(context),
        onLowerRightPress: () => _handleRecentAccount(context),
        ),
      ),
    );
  }

  void _handlePressBack(BuildContext context) {
    Navigator.pop(context);
  }

  void _handlePressHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleDirectInput(BuildContext context) {
    // React Native: navigation.navigate('SendInputPage', {type: 'directOtherAccount'});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SendInputPage(type: 'directOtherAccount'),
      ),
    );
  }

  void _handleRecentAccount(BuildContext context) {
    // TODO: React Native: navigation.navigate('SendRecentAccount');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('최근 계좌 기능 구현 예정')),
    );
  }
}

/// React Native InputAccount.tsx를 Flutter로 정확히 마이그레이션
class SendInputPage extends StatefulWidget {
  final String type;
  
  const SendInputPage({
    super.key,
    required this.type,
  });

  @override
  State<SendInputPage> createState() => _SendInputPageState();
}

class _SendInputPageState extends State<SendInputPage> {
  String accountNumber = '';
  bool showModal = true; // React Native와 동일하게 기본값 true
  final TtsService _ttsService = TtsService(); // 🔧 ADD: TTS 서비스

  @override
  void initState() {
    super.initState();
    _initializeTTS(); // 🔧 TTS 초기화
    // React Native useTTSOnFocus와 동일한 메시지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize(); // 🔧 TTS 서비스 초기화
  }

  @override
  void dispose() {
    _ttsService.dispose(); // 🔧 TTS 서비스 정리
    super.dispose();
  }

  void _speakPageGuide() {
    const guide = '''송금할 계좌를 입력하는 화면입니다.
숫자를 손으로 그려서 입력할 수 있습니다.
입력한 숫자를 지우려면 X자를 그려주세요.
입력이 끝났다면 V자를 그려서 마무리해주세요.
다음 단계로 넘어가시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide); // 🔧 실제 TTS 서비스 사용
  }

  // React Native handlePrediction 함수와 정확히 동일
  void _handlePrediction(String digit) {
    print('🔍 Received digit: $digit'); // 디버깅용
    
    if (digit == '11') { // React Native: if (digit === '11') - delete gesture
      _deleteLastDigit();
      _playTTS('지우기');
    } else if (digit == '10') { // React Native: if (digit === '10') - complete gesture
      _closeModal();
      _playTTS('입력 완료');
      _playTTS(accountNumber);
    } else {
      setState(() {
        accountNumber += digit;
      });
      _playTTS(digit);
    }
  }

  void _deleteLastDigit() {
    if (accountNumber.isNotEmpty) {
      setState(() {
        accountNumber = accountNumber.substring(0, accountNumber.length - 1);
      });
    }
  }

  void _closeModal() {
    setState(() {
      showModal = false;
    });
  }

  void _playTTS(String text) {
    print('TTS: $text'); // 디버깅용 로그 유지
    _ttsService.speak(text); // 🔧 실제 TTS 서비스 사용
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // DefaultPage 배경색과 일치
      body: SafeArea(
        child: Stack(
          children: [
            // 🔧 더블탭 로직이 포함된 DefaultPage 사용
            DefaultPage(
            upperLeftWidget: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text('이전', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            upperRightWidget: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text('메인', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            lowerLeftWidget: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text('입력', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            lowerRightWidget: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text('확인', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            mainWidget: Container(
              decoration: const BoxDecoration(
                // React Native 원본과 동일한 그라데이션 배경
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3A8A), // 진한 파란색
                    Color(0xFF3B82F6), // 밝은 파란색
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계좌번호 입력',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 280),
                      child: Text(
                        accountNumber.isEmpty ? '계좌번호를 입력' : accountNumber,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '"X" 그려서 지우기\n"V" 그려서 완료',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 🔧 더블탭 TTS 메시지 추가
            upperLeftTTS: '이전',
            upperRightTTS: '메인',
            lowerLeftTTS: '입력',
            lowerRightTTS: '확인',
            // 🔧 더블탭 액션 추가
            onUpperLeftPress: () => Navigator.pop(context),
            onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
            onLowerLeftPress: () => Navigator.pop(context),
            onLowerRightPress: () => _handleSend(context),
          ),
          
          // 🔧 NEW: 오버레이 캔버스 (기존 UI 위에 투명 캔버스)
          if (showModal)
            HandwritingOverlayCanvas(
              isVisible: showModal,
              onDigitRecognized: (digit) {
                // React Native와 동일한 형식으로 변환
                if (digit == 'delete') {
                  _handlePrediction('11'); // React Native: digit === '11' (delete)
                } else if (digit == 'complete') {
                  _handlePrediction('10'); // React Native: digit === '10' (complete)
                } else {
                  _handlePrediction(digit); // 숫자 0-9
                }
              },
              onClose: () {
                setState(() {
                  showModal = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend(BuildContext context) {
    if (accountNumber.isNotEmpty) {
      // TODO: React Native: navigation.navigate('ReceivingAccountScreen', {selectedAccount});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계좌번호: $accountNumber 입력 완료')),
      );
    }
  }
}

 