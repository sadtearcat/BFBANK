import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../../handwriting_recognition/widgets/handwriting_overlay_canvas.dart';
import 'send_success_page.dart';

/// 송금 비밀번호 입력 페이지
class SendPasswordPage extends StatefulWidget {
  final Map<String, dynamic> selectedAccount;
  final String amount;
  
  const SendPasswordPage({
    super.key,
    required this.selectedAccount,
    required this.amount,
  });

  @override
  State<SendPasswordPage> createState() => _SendPasswordPageState();
}

class _SendPasswordPageState extends State<SendPasswordPage> {
  final TtsService _ttsService = TtsService();
  String password = '';
  bool showModal = true;
  final int maxPasswordLength = 6; // 6자리 비밀번호

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _speakPageGuide() {
    final guide = '''송금 비밀번호를 입력하는 화면입니다.
6자리 숫자를 손으로 그려서 입력할 수 있습니다.
입력한 숫자를 지우려면 X자를 그려주세요.
입력이 끝났다면 V자를 그려서 마무리해주세요.
송금을 완료하려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  void _handlePrediction(String digit) {
    print('🔍 Received digit: $digit');
    
    if (digit == '11') { // delete gesture
      _deleteLastDigit();
      _playTTS('지우기');
    } else if (digit == '10') { // complete gesture
      _closeModal();
      _playTTS('입력 완료');
    } else {
      if (password.length < maxPasswordLength) {
        setState(() {
          password += digit;
        });
        _playTTS('별');
        
        // 6자리 완성되면 자동으로 모달 닫기
        if (password.length == maxPasswordLength) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _closeModal();
            _playTTS('비밀번호 입력 완료');
          });
        }
      }
    }
  }

  void _deleteLastDigit() {
    if (password.isNotEmpty) {
      setState(() {
        password = password.substring(0, password.length - 1);
      });
    }
  }

  void _closeModal() {
    setState(() {
      showModal = false;
    });
  }

  void _playTTS(String text) {
    print('TTS: $text');
    _ttsService.speak(text);
  }

  String _formatAmount(String value) {
    final intValue = int.tryParse(value) ?? 0;
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiverName = widget.selectedAccount['receiverName'] ?? '수신자';
    final receiverAccount = widget.selectedAccount['receiverAccount'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
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
                  Icon(Icons.send, color: Colors.white, size: 60),
                  SizedBox(height: 8),
                  Text('송금', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              mainWidget: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Voice button
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
                      
                      // Page title
                      const Text(
                        '송금 비밀번호 입력',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Transaction summary
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '받는 분',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  receiverName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '계좌번호',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 20,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    receiverAccount,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '송금 금액',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  '${_formatAmount(widget.amount)}원',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Password display
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '비밀번호 (6자리)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(maxPasswordLength, (index) {
                                return Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < password.length 
                                        ? Colors.white 
                                        : Colors.white30,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text(
                        '"X" 그려서 지우기\n"V" 그려서 완료',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              upperLeftTTS: '이전',
              upperRightTTS: '메인',
              lowerLeftTTS: '입력',
              lowerRightTTS: '송금',
              onUpperLeftPress: () => Navigator.pop(context),
              onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
              onLowerLeftPress: () => Navigator.pop(context),
              onLowerRightPress: () => _handleSend(context),
            ),
            
            // Handwriting overlay
            if (showModal)
              HandwritingOverlayCanvas(
                isVisible: showModal,
                onDigitRecognized: (digit) {
                  if (digit == 'delete') {
                    _handlePrediction('11');
                  } else if (digit == 'complete') {
                    _handlePrediction('10');
                  } else {
                    _handlePrediction(digit);
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
    if (password.length == maxPasswordLength) {
      // 실제 앱에서는 여기서 비밀번호 검증과 송금 API 호출
      _performTransfer(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6자리 비밀번호를 모두 입력해주세요')),
      );
    }
  }

  Future<void> _performTransfer(BuildContext context) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.black87,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              '송금 처리 중...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );

    try {
      // 실제 송금 처리 (더미데이터 서비스 사용)
      final success = await IntegratedDummyDataService.processTransfer(
        toAccount: widget.selectedAccount['receiverAccount'],
        amount: int.tryParse(widget.amount) ?? 0,
        memo: '송금',
      );

      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (success) {
        // 송금 성공 페이지로 이동
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SendSuccessPage(
              selectedAccount: widget.selectedAccount,
              amount: widget.amount,
            ),
            transitionDuration: Duration.zero, // 애니메이션 시간 0
            reverseTransitionDuration: Duration.zero, // 뒤로가기 애니메이션 시간도 0
          ),
        );
      } else {
        // 송금 실패 처리
        _ttsService.speak('송금이 실패했습니다. 잔액이나 한도를 확인해주세요.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('송금이 실패했습니다. 잔액이나 한도를 확인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      _ttsService.speak('송금 처리 중 오류가 발생했습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('송금 처리 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 