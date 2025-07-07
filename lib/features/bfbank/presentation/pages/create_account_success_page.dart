import 'package:flutter/material.dart';
import '../../data/models/account_product.dart';
import '../../data/services/tts_service.dart';
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

  @override
  void initState() {
    super.initState();
    
    // 음성 안내 (React Native 스타일)
    Future.delayed(const Duration(milliseconds: 500), () {
      _ttsService.speak('통장 개설이 완료되었습니다. ${widget.product.name}, 계좌 번호는 ${widget.accountNumber}입니다.');
    });
  }

  void _handleGoHome() {
    // 계좌 개설 완료 결과를 반환하면서 메인 페이지로 이동
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleViewAccount() {
    // 나중에 계좌 상세 페이지로 연결
    _ttsService.speak('계좌 상세 정보를 확인합니다.');
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget _buildButtonContent(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 32),
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

  @override
  Widget build(BuildContext context) {
    return DefaultPage(
      upperLeftWidget: _buildButtonContent(Icons.close, '닫기'),
      upperRightWidget: _buildButtonContent(Icons.home, '메인'),
      lowerLeftWidget: _buildButtonContent(Icons.home, '메인화면'),
      lowerRightWidget: _buildButtonContent(Icons.account_balance, '계좌확인'),
      onUpperLeftPress: _handleGoHome,
      onUpperRightPress: _handleGoHome,
      onLowerLeftPress: _handleGoHome,
      onLowerRightPress: _handleViewAccount,
      mainWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 (React Native 스타일)
            const Text(
              '통장 개설 완료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // 계좌 정보 (React Native 스타일)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.accountNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '개설이 완료되었습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 