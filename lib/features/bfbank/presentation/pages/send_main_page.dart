import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../../handwriting_recognition/widgets/handwriting_input_modal.dart';
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
    print('TTS: $guide'); // TODO: 실제 TTS 구현
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // React Native 원본과 동일
      body: DefaultPageLayout(
        upperLeftIcon: Icons.arrow_back_ios,
        upperLeftText: '이전',
        upperRightIcon: Icons.home,
        upperRightText: '메인',
        lowerLeftIcon: Icons.edit,
        lowerLeftText: '입력',
        lowerRightIcon: Icons.history,
        lowerRightText: '최근 계좌',
        mainContent: Column(
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
        onUpperLeftPress: () => _handlePressBack(context),
        onUpperRightPress: () => _handlePressHome(context),
          onLowerLeftPress: () => _handleDirectInput(context),
          onLowerRightPress: () => _handleRecentAccount(context),
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

  @override
  void initState() {
    super.initState();
    // React Native useTTSOnFocus와 동일한 메시지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  void _speakPageGuide() {
    const guide = '''송금할 계좌를 입력하는 화면입니다.
숫자를 손으로 그려서 입력할 수 있습니다.
입력한 숫자를 지우려면 X자를 그려주세요.
입력이 끝났다면 V자를 그려서 마무리해주세요.
다음 단계로 넘어가시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼, 오른쪽 위에는 홈 버튼이 있습니다.''';
    print('TTS: $guide'); // TODO: 실제 TTS 구현
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
    print('TTS: $text'); // TODO: 실제 TTS 구현
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main DefaultPage layout
          DefaultPageLayout(
            upperLeftIcon: Icons.arrow_back_ios,
            upperLeftText: '이전',
            upperRightIcon: Icons.home,
            upperRightText: '메인',
            lowerLeftIcon: Icons.edit,
            lowerLeftText: '입력',
            lowerRightIcon: Icons.check,
            lowerRightText: '확인',
            mainContent: Column(
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
            onUpperLeftPress: () => Navigator.pop(context),
            onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
            onLowerLeftPress: () => Navigator.pop(context),
            onLowerRightPress: () => _handleSend(context),
          ),
          
          // React Native DrawingModal과 정확히 동일한 구조
          if (showModal)
            DrawingModalWidget(
              visible: showModal,
              onPredict: _handlePrediction,
          ),
        ],
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

/// React Native DefaultPage를 Flutter로 정확히 마이그레이션
class DefaultPageLayout extends StatelessWidget {
  final IconData upperLeftIcon;
  final String upperLeftText;
  final IconData upperRightIcon;
  final String upperRightText;
  final IconData lowerLeftIcon;
  final String lowerLeftText;
  final IconData lowerRightIcon;
  final String lowerRightText;
  final Widget mainContent;
  final VoidCallback onUpperLeftPress;
  final VoidCallback onUpperRightPress;
  final VoidCallback onLowerLeftPress;
  final VoidCallback onLowerRightPress;

  const DefaultPageLayout({
    super.key,
    required this.upperLeftIcon,
    required this.upperLeftText,
    required this.upperRightIcon,
    required this.upperRightText,
    required this.lowerLeftIcon,
    required this.lowerLeftText,
    required this.lowerRightIcon,
    required this.lowerRightText,
    required this.mainContent,
    required this.onUpperLeftPress,
    required this.onUpperRightPress,
    required this.onLowerLeftPress,
    required this.onLowerRightPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Stack(
          children: [
            // Main content in center
            Center(child: mainContent),
            
            // Corner buttons (React Native 스타일과 정확히 동일)
            Positioned(
              top: 20,
              left: 20,
              child: _CornerButton(
                icon: upperLeftIcon,
                text: upperLeftText,
                onPressed: onUpperLeftPress,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: _CornerButton(
                icon: upperRightIcon,
                text: upperRightText,
                onPressed: onUpperRightPress,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: _CornerButton(
                icon: lowerLeftIcon,
                text: lowerLeftText,
                onPressed: onLowerLeftPress,
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: _CornerButton(
                icon: lowerRightIcon,
                text: lowerRightText,
                onPressed: onLowerRightPress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// React Native 버튼 스타일과 정확히 동일
class _CornerButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _CornerButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 100, // React Native와 동일한 크기
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40, // React Native와 동일한 크기
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// React Native DrawingModal을 Flutter로 정확히 마이그레이션
class DrawingModalWidget extends StatelessWidget {
  final bool visible;
  final Function(String) onPredict;

  const DrawingModalWidget({
    super.key,
    required this.visible,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // React Native: 전체 화면을 덮는 투명 오버레이
    return Container(
      color: Colors.transparent,
      child: HandwritingOverlay(
        onResult: (result) {
          // React Native와 동일한 형식으로 변환
          if (result == 'delete') {
            onPredict('11'); // React Native: digit === '11' (delete)
          } else if (result == 'complete') {
            onPredict('10'); // React Native: digit === '10' (complete)
          } else {
            onPredict(result); // 숫자 0-9
          }
        },
        onComplete: () {
          // V 제스처 완료 - 이미 onResult에서 처리됨
        },
        onClose: () {
          // 모달 닫기 (React Native에서는 visible=false로 제어)
        },
        enableDebugLogs: true, // 디버깅을 위해 활성화
      ),
    );
  }
} 