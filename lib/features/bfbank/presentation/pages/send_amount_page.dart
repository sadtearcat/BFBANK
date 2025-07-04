import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../../handwriting_recognition/widgets/handwriting_overlay_canvas.dart';
import 'send_password_page.dart';

/// 송금 금액 입력 페이지
class SendAmountPage extends StatefulWidget {
  final Map<String, dynamic> selectedAccount;
  
  const SendAmountPage({
    super.key,
    required this.selectedAccount,
  });

  @override
  State<SendAmountPage> createState() => _SendAmountPageState();
}

class _SendAmountPageState extends State<SendAmountPage> {
  final TtsService _ttsService = TtsService();
  String amount = '';
  bool showModal = true;

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
    final receiverName = widget.selectedAccount['receiverName'] ?? '수신자';
    final guide = '''${receiverName}님에게 송금할 금액을 입력하는 화면입니다.
숫자를 손으로 그려서 입력할 수 있습니다.
입력한 숫자를 지우려면 X자를 그려주세요.
입력이 끝났다면 V자를 그려서 마무리해주세요.
다음 단계로 넘어가시려면 오른쪽 아래를 눌러주세요.
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
      if (amount.isNotEmpty) {
        _playTTS('${_formatAmount(amount)}원');
      }
    } else {
      setState(() {
        amount += digit;
      });
      _playTTS(digit);
    }
  }

  void _deleteLastDigit() {
    if (amount.isNotEmpty) {
      setState(() {
        amount = amount.substring(0, amount.length - 1);
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
    if (value.isEmpty) return '0';
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
                  Icon(Icons.check, color: Colors.white, size: 60),
                  SizedBox(height: 8),
                  Text('확인', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                        '송금 금액 입력',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Receiver info
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$receiverName 님에게',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              receiverAccount,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Amount display
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(minWidth: 300),
                        child: Column(
                          children: [
                            Text(
                              amount.isEmpty ? '금액을 입력하세요' : '${_formatAmount(amount)}원',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: amount.isEmpty ? Colors.white60 : Colors.white,
                                fontSize: amount.isEmpty ? 24 : 32,
                                fontWeight: amount.isEmpty ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            if (amount.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _getAmountInKorean(amount),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text(
                        '"X" 그려서 지우기\n"V" 그려서 완료',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              upperLeftTTS: '이전',
              upperRightTTS: '메인',
              lowerLeftTTS: '입력',
              lowerRightTTS: '확인',
              onUpperLeftPress: () => Navigator.pop(context),
              onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
              onLowerLeftPress: () => Navigator.pop(context),
              onLowerRightPress: () => _handleConfirm(context),
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

  String _getAmountInKorean(String value) {
    if (value.isEmpty) return '';
    final intValue = int.tryParse(value) ?? 0;
    
    if (intValue < 10000) {
      return '';
    } else if (intValue < 100000000) {
      final man = intValue ~/ 10000;
      return '${man}만원';
    } else {
      final eok = intValue ~/ 100000000;
      final man = (intValue % 100000000) ~/ 10000;
      if (man > 0) {
        return '${eok}억 ${man}만원';
      } else {
        return '${eok}억원';
      }
    }
  }

  Future<void> _handleConfirm(BuildContext context) async {
    if (amount.isNotEmpty && int.tryParse(amount) != null && int.parse(amount) > 0) {
      final intAmount = int.parse(amount);
      
      try {
        // 계좌 정보 조회하여 잔액과 한도 확인
        final accountInfo = await IntegratedDummyDataService.fetchAccountInfo();
        
        if (intAmount > accountInfo.accountBalance) {
          _ttsService.speak('잔액이 부족합니다. 현재 잔액은 ${_formatAmount(accountInfo.accountBalance.toString())}원입니다.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('잔액이 부족합니다. (잔액: ${_formatAmount(accountInfo.accountBalance.toString())}원)')),
          );
          return;
        }
        
        if (intAmount > accountInfo.oneTimeTransferLimit) {
          _ttsService.speak('1회 이체 한도를 초과했습니다. 한도는 ${_formatAmount(accountInfo.oneTimeTransferLimit.toString())}원입니다.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('1회 이체 한도 초과 (한도: ${_formatAmount(accountInfo.oneTimeTransferLimit.toString())}원)')),
          );
          return;
        }
        
        // 검증 통과 시 비밀번호 입력 페이지로 이동
        _ttsService.speak('금액이 확인되었습니다. 비밀번호를 입력해주세요.');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SendPasswordPage(
              selectedAccount: widget.selectedAccount,
              amount: amount,
            ),
            transitionDuration: Duration.zero, // 애니메이션 시간 0
            reverseTransitionDuration: Duration.zero, // 뒤로가기 애니메이션 시간도 0
          ),
        );
      } catch (e) {
        _ttsService.speak('계좌 정보 조회 중 오류가 발생했습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계좌 정보 조회 중 오류가 발생했습니다')),
        );
      }
    } else {
      _ttsService.speak('올바른 금액을 입력해주세요.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요')),
      );
    }
  }
} 