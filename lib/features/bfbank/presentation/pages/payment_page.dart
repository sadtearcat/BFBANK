import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  
  // QR 유효 시간 (10분)
  static const int qrValidDurationMs = 10 * 60 * 1000;
  
  late DateTime _expiresAt;
  String _remainingTime = '10:00';
  String _qrValue = '';
  bool _isGenerating = false;
  Timer? _updateTimer;
  Timer? _regenQRTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _createNewQR();
    
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
    const guide = '''
    결제 화면입니다.
    QR 코드가 생성되었습니다.
    상대방이 QR 코드를 스캔하여 결제할 수 있습니다.
    QR 코드는 10분간 유효하며, 자동으로 새로 갱신됩니다.
    왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.
    왼쪽 아래에는 QR 새로고침 버튼이, 오른쪽 아래에는 음성 안내 버튼이 있습니다.
    ''';
    _ttsService.speak(guide);
  }

  void _createNewQR() async {
    setState(() => _isGenerating = true);
    
    try {
      final user = IntegratedDummyDataService.getCurrentUser();
      final account = IntegratedDummyDataService.getCurrentUserAccount();
      
      _expiresAt = DateTime.now().add(const Duration(milliseconds: qrValidDurationMs));
      _remainingTime = _formatRemainingTime(qrValidDurationMs);
      
      // QR 데이터 생성 (실제로는 백엔드 API 호출)
      _qrValue = 'BFBank_Payment?expiresAt=${_expiresAt.toIso8601String()}&userName=${user.username}&userId=${user.id}&accountNo=${account.accountNo}';
      
      _hapticService.vibrateCustomSequence('success');
      _ttsService.speak('새로운 QR 코드가 생성되었습니다.');
      
      // 타이머 시작
      _startTimer();
      
      // QR 만료 시점에 QR 다시 생성
      _regenQRTimer?.cancel();
      _regenQRTimer = Timer(const Duration(milliseconds: qrValidDurationMs), () {
        _createNewQR();
      });
      
    } catch (error) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('QR 코드 생성에 실패했습니다.');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _startTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remainingMs = _expiresAt.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
      if (remainingMs <= 0) {
        setState(() => _remainingTime = '00:00');
      } else {
        setState(() => _remainingTime = _formatRemainingTime(remainingMs));
      }
    });
  }

  String _formatRemainingTime(int ms) {
    final totalSeconds = (ms / 1000).floor().clamp(0, double.infinity).toInt();
    final minutes = (totalSeconds / 60).floor();
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _regenQRTimer?.cancel();
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
          upperLeftWidget: _buildButtonContent(Icons.arrow_back, '이전'),
          upperRightWidget: _buildButtonContent(Icons.home, '메인'),
          lowerLeftWidget: _buildButtonContent(Icons.refresh, '새로고침'),
          lowerRightWidget: _buildButtonContent(Icons.volume_up, '음성안내'),
          mainWidget: _buildPaymentContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: _handleRefreshQR,
          onLowerRightPress: _handleVoiceGuide,
          // React Native와 동일한 더블탭 TTS 메시지
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '새로고침',
          lowerRightTTS: '음성안내',
        ),
      ),
    );
  }

  Widget _buildButtonContent(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    final user = IntegratedDummyDataService.getCurrentUser();
    final account = IntegratedDummyDataService.getCurrentUserAccount();
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '${user.username} 님',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.formattedAccountNo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.formattedBalance,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '남은 시간: $_remainingTime',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  _isGenerating
                      ? const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('QR 생성 중...', style: TextStyle(color: Colors.black)),
                          ],
                        )
                      : Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 80, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'QR 코드',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                  
                  const SizedBox(height: 15),
                  const Text(
                    '상대방이 QR 코드를 스캔하여\n결제할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            const Text(
              'QR 코드는 10분간 유효합니다.\n자동으로 새로 갱신됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('이전 화면으로 돌아갑니다.');
    Navigator.of(context).pop();
  }

  void _handleHome(BuildContext context) {
    _hapticService.vibrateCustomSequence('double_tick');
    _ttsService.speak('메인 화면으로 이동합니다.');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _handleRefreshQR() {
    _hapticService.vibrateCustomSequence('notification');
    _ttsService.speak('QR 코드를 새로 생성합니다.');
    _createNewQR();
  }

  void _handleVoiceGuide() {
    _hapticService.vibrateCustomSequence('tick');
    _speakPageGuide();
  }
} 