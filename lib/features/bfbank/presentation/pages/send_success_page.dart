import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';

/// 송금 완료 페이지
class SendSuccessPage extends StatefulWidget {
  final Map<String, dynamic> selectedAccount;
  final String amount;
  
  const SendSuccessPage({
    super.key,
    required this.selectedAccount,
    required this.amount,
  });

  @override
  State<SendSuccessPage> createState() => _SendSuccessPageState();
}

class _SendSuccessPageState extends State<SendSuccessPage> 
    with TickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  
  String _myAccountNo = '';
  int _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _setupAnimations();
    _loadAccountInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _loadAccountInfo() async {
    try {
      final accountInfo = await IntegratedDummyDataService.fetchAccountInfo();
      setState(() {
        _myAccountNo = accountInfo.accountNo;
        _currentBalance = accountInfo.accountBalance;
      });
    } catch (e) {
      print('Error loading account info: $e');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));

    // 애니메이션 시작
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _checkController.forward();
    });
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _speakPageGuide() {
    final receiverName = widget.selectedAccount['receiverName'] ?? '수신자';
    final formattedAmount = _formatAmount(widget.amount);
    
    final guide = '''송금이 완료되었습니다.
${receiverName}님에게 ${formattedAmount}원을 성공적으로 송금했습니다.
다시 송금하시려면 왼쪽 아래를,
메인 화면으로 돌아가시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    
    // 애니메이션이 끝나고 TTS 실행
    Future.delayed(const Duration(milliseconds: 1500), () {
      _ttsService.speak(guide);
    });
  }

  String _formatAmount(String value) {
    final intValue = int.tryParse(value) ?? 0;
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.year}년 ${now.month}월 ${now.day}일 ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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
              Icon(Icons.send, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('다시 송금', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          lowerRightWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_outlined, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('메인으로', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                  // Success animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _checkAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CheckmarkPainter(_checkAnimation.value),
                            size: const Size(120, 120),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Success message
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Text(
                      '송금 완료!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Transaction details
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: Column(
                        children: [
                          // Amount
                          Text(
                            '${_formatAmount(widget.amount)}원',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            '성공적으로 송금되었습니다',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Divider
                          Container(
                            height: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          
                          // Transaction info
                          _buildInfoRow('보내는 분', '홍길동'),
                          const SizedBox(height: 8),
                          _buildInfoRow('내 계좌', _myAccountNo.isNotEmpty ? _myAccountNo : '로딩 중...'),
                          const SizedBox(height: 8),
                          _buildInfoRow('현재 잔액', _currentBalance > 0 ? '${_formatAmount(_currentBalance.toString())}원' : '로딩 중...'),
                          const SizedBox(height: 16),
                          
                          Container(
                            height: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          
                          _buildInfoRow('받는 분', receiverName),
                          const SizedBox(height: 8),
                          _buildInfoRow('받는 계좌', receiverAccount),
                          const SizedBox(height: 8),
                          _buildInfoRow('은행', bankName),
                          const SizedBox(height: 8),
                          _buildInfoRow('송금 시간', _getCurrentTime()),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Voice button
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
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
                            '송금 완료',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '다시 송금',
          lowerRightTTS: '메인으로',
          onUpperLeftPress: () => Navigator.pop(context),
          onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
          onLowerLeftPress: () => _handleSendAgain(context),
          onLowerRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSendAgain(BuildContext context) {
    // 송금 메인 페이지로 돌아가기
    Navigator.popUntil(context, (route) => route.settings.name == '/send_main');
  }
}

/// 체크마크 애니메이션을 그리는 CustomPainter
class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 체크마크 패스 정의
    final path = Path();
    
    // 체크마크의 첫 번째 선 (왼쪽 위에서 중앙 하단으로)
    final firstLineStart = Offset(centerX - 20, centerY - 5);
    final firstLineEnd = Offset(centerX - 5, centerY + 10);
    
    // 체크마크의 두 번째 선 (중앙에서 오른쪽 위로)
    final secondLineStart = firstLineEnd;
    final secondLineEnd = Offset(centerX + 20, centerY - 15);

    if (progress > 0) {
      // 첫 번째 선 그리기
      if (progress <= 0.5) {
        final currentProgress = progress * 2;
        final currentEnd = Offset.lerp(firstLineStart, firstLineEnd, currentProgress)!;
        path.moveTo(firstLineStart.dx, firstLineStart.dy);
        path.lineTo(currentEnd.dx, currentEnd.dy);
      } else {
        // 첫 번째 선 완료
        path.moveTo(firstLineStart.dx, firstLineStart.dy);
        path.lineTo(firstLineEnd.dx, firstLineEnd.dy);
        
        // 두 번째 선 그리기
        final secondProgress = (progress - 0.5) * 2;
        final currentEnd = Offset.lerp(secondLineStart, secondLineEnd, secondProgress)!;
        path.moveTo(secondLineStart.dx, secondLineStart.dy);
        path.lineTo(currentEnd.dx, currentEnd.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 