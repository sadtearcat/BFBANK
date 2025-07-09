import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/account_product.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../widgets/default_page.dart';

class CreateAccountSuccessPage extends StatefulWidget {
  final AccountProduct product;
  final Map<String, String> personalInfo;
  final String accountNumber;
  final String accountName;

  const CreateAccountSuccessPage({
    super.key,
    required this.product,
    required this.personalInfo,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  State<CreateAccountSuccessPage> createState() => _CreateAccountSuccessPageState();
}

class _CreateAccountSuccessPageState extends State<CreateAccountSuccessPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    
    // 음성 안내와 햅틱 피드백
    Future.delayed(const Duration(milliseconds: 500), () {
      _hapticService.vibrateCustomSequence('cheerful_success');
      _ttsService.speak('통장 개설이 완료되었습니다. ${widget.product.name}, 계좌 번호는 ${widget.accountNumber}입니다.');
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _handleGoHome() {
    // 계좌 개설 완료 결과를 반환하면서 메인 페이지로 이동
    _hapticService.vibrateCustomSequence('tick');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleViewAccount() {
    // 나중에 계좌 상세 페이지로 연결
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('계좌 상세 정보를 확인합니다.');
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleGoToMain() {
    _hapticService.vibrateCustomSequence('tick');
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleGoToSettings() {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('설정 페이지로 이동합니다.');
    // 나중에 설정 페이지로 연결
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleGoToHistory() {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('거래 내역을 확인합니다.');
    // 나중에 거래 내역 페이지로 연결
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleGoToSend() {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('송금 페이지로 이동합니다.');
    // 나중에 송금 페이지로 연결
    Navigator.popUntil(context, (route) => route.isFirst);
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
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          upperRightWidget: _buildButtonContent('assets/icons/Settings.svg', '설정'),
          lowerLeftWidget: _buildButtonContent('assets/icons/History.svg', '조회'),
          lowerRightWidget: _buildButtonContent('assets/icons/Send.svg', '송금'),
          onUpperLeftPress: _handleGoToMain,
          onUpperRightPress: _handleGoToSettings,
          onLowerLeftPress: _handleGoToHistory,
          onLowerRightPress: _handleGoToSend,
          // TTS 메시지 추가
          upperLeftTTS: '메인',
          upperRightTTS: '설정',
          lowerLeftTTS: '조회',
          lowerRightTTS: '송금',
          mainWidget: Column(
            children: [
              // 음성 안내 버튼
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onTap: () {
                    final message = '계좌 개설이 완료되었습니다. ${widget.accountNumber}번 계좌가 생성되었습니다. 이제 모든 뱅킹 서비스를 이용하실 수 있습니다.';
                    _ttsService.speak(message);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                      const SizedBox(width: 20),
                      const Text(
                        '계좌 개설 완료 안내',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 메인 콘텐츠
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 성공 아이콘
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 성공 메시지
                      const Text(
                        '계좌 개설 완료!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 축하 메시지
                      const Text(
                        'BF Bank 계좌가 성공적으로 개설되었습니다.\n이제 모든 뱅킹 서비스를 이용하실 수 있습니다.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 계좌 정보
                      if (widget.accountNumber != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF444444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '개설된 계좌 정보',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              _buildInfoRow('계좌번호', widget.accountNumber),
                              const SizedBox(height: 8),
                              _buildInfoRow('상품명', widget.product.name),
                              const SizedBox(height: 8),
                              _buildInfoRow('개설일', '2023-10-27'), // Placeholder for actual open date
                              const SizedBox(height: 8),
                              _buildInfoRow('금리', '연 0.5%'), // Placeholder for actual interest rate
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                      
                      // 안내 메시지
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '이제 아래 메뉴를 이용하실 수 있습니다:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• 메인: 계좌 조회 및 주요 기능\n• 설정: 계좌 및 앱 설정\n• 조회: 거래 내역 확인\n• 송금: 타 계좌로 송금',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
    );
  }
} 