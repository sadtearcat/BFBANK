import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    결제 페이지입니다.
    QR를 스캔하여 송금할 계좌와 금액을 입력해주세요.
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
          upperLeftWidget: _buildButtonContent('assets/icons/ArrowLeft.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent('assets/icons/Cancel.svg', '취소'),
          lowerRightWidget: _buildButtonContent('assets/icons/Check.svg', '확인'),
          mainWidget: _buildMainContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: null,
          onLowerRightPress: null,
          // React Native와 동일한 더블탭 TTS 메시지
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '취소',
          lowerRightTTS: '확인',
        ),
      ),
    );
  }

  Widget _buildButtonContent(String assetPath, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          assetPath,
          width: 48,
          height: 48,
          color: Colors.white,
        ),
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

  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Voice Button (React Native와 동일)
        GestureDetector(
          onTap: () {
            _hapticService.vibrateCustomSequence('tick');
            _speakPageGuide();
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
                SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                const SizedBox(width: 20),
                const Text(
                  '결제 하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // QR Container (React Native PaymentMainScreen과 동일)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '남은 시간: $_remainingTime',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              _isGenerating
                  ? const Text('QR 생성 중...', style: TextStyle(color: Colors.black))
                  : SvgPicture.asset('assets/icons/QR.svg', width: 200, height: 200, color: Colors.black),
            ],
          ),
        ),
      ],
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
    Navigator.of(context).pushNamedAndRemoveUntil('/bfbank-main', (route) => false);
  }
} 