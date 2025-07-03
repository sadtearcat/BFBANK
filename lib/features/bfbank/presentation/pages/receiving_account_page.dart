import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import 'send_amount_page.dart';

/// 수신 계좌 확인 페이지
class ReceivingAccountPage extends StatefulWidget {
  final Map<String, dynamic> selectedAccount;
  
  const ReceivingAccountPage({
    super.key,
    required this.selectedAccount,
  });

  @override
  State<ReceivingAccountPage> createState() => _ReceivingAccountPageState();
}

class _ReceivingAccountPageState extends State<ReceivingAccountPage> {
  final TtsService _ttsService = TtsService();

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
    final receiverAccount = widget.selectedAccount['receiverAccount'] ?? '';
    final accountSpaced = receiverAccount.split('').join(' ');
    
    final guide = '''${receiverName}님에게 송금할 계좌입니다.
계좌번호는 ${accountSpaced}입니다.
취소하시려면 왼쪽 아래를, 송금하시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  @override
  Widget build(BuildContext context) {
    final receiverName = widget.selectedAccount['receiverName'] ?? '수신자';
    final receiverAccount = widget.selectedAccount['receiverAccount'] ?? '';
    final bankName = widget.selectedAccount['bankName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
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
              Icon(Icons.cancel, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('취소', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                    margin: const EdgeInsets.only(bottom: 30),
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
                  
                  // Main title
                  const Text(
                    '받는 사람 정보를 확인하세요.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Account details box
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Column(
                      children: [
                        // Receiver name
                        Row(
                          children: [
                            const Text(
                              '받는 사람',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              receiverName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Account number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '계좌번호',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              flex: 2,
                              child: Text(
                                receiverAccount,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Bank name
                        Row(
                          children: [
                            const Text(
                              '은행',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              bankName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Info text
                  const Text(
                    '정보가 정확하면 확인을 눌러주세요',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '이전',
          lowerRightTTS: '송금하기',
          onUpperLeftPress: () => Navigator.pop(context),
          onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
          onLowerLeftPress: () => Navigator.pop(context),
          onLowerRightPress: () => _handleConfirm(context),
        ),
      ),
    );
  }

  void _handleConfirm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendAmountPage(
          selectedAccount: widget.selectedAccount,
        ),
      ),
    );
  }
} 