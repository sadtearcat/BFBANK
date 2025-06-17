import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/default_page.dart';
import '../../data/models/transaction_history.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';

class CheckHistoryDetailPage extends StatefulWidget {
  final TransactionHistory transaction;

  const CheckHistoryDetailPage({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<CheckHistoryDetailPage> createState() => _CheckHistoryDetailPageState();
}

class _CheckHistoryDetailPageState extends State<CheckHistoryDetailPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
    // React Native와 정확히 동일한 메시지
    const guide = '''거래 내역 상세 화면입니다.
아래 버튼을 누르면 계좌 조회 페이지로 이동됩니다.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  void _speakTransactionDetail() {
    final typeLabel = widget.transaction.typeLabel;
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH시 mm분', 'ko_KR');
    final formattedDate = dateFormat.format(widget.transaction.transactionDate);
    
    final fullMessage = '''거래유형: $typeLabel

거래명: ${widget.transaction.transactionName}

거래금액: ${widget.transaction.formattedAmount}

잔액: ${widget.transaction.formattedBalance}

계좌번호: ${widget.transaction.transactionAccount}

거래일시: $formattedDate''';
    
    _ttsService.speak(fullMessage);
  }

  @override
  void dispose() {
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
          lowerLeftWidget: _buildButtonContent(Icons.cancel, '취소'),
          lowerRightWidget: _buildButtonContent(Icons.check, '확인'),
          mainWidget: _buildTransactionDetailContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: () => _handleBack(context),
          onLowerRightPress: () => _handleBack(context),
          // React Native와 동일한 더블탭 TTS 메시지
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '취소',
          lowerRightTTS: '확인',
        ),
      ),
    );
  }

  Widget _buildButtonContent(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.white),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetailContent() {
    final dateFormat = DateFormat('yyyy년 MM월 dd일', 'ko_KR');
    final timeFormat = DateFormat('HH시 mm분', 'ko_KR');
    final formattedDate = dateFormat.format(widget.transaction.transactionDate);
    final formattedTime = timeFormat.format(widget.transaction.transactionDate);
    
    final isWithdrawal = widget.transaction.transactionType == 'WITHDRAWAL';
    final typeLabel = widget.transaction.typeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 음성 안내 버튼
          GestureDetector(
            onTap: () {
              _hapticService.vibrateCustomSequence('tick');
              _speakTransactionDetail();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    '계좌 상세 조회',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 날짜와 시간
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 30,
                  color: Color(0xFFCCCCCC),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 30,
                  color: Color(0xFFCCCCCC),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 거래 이름
          Text(
            widget.transaction.transactionName,
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 26),

          // 거래 유형과 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 거래 유형 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isWithdrawal ? const Color(0xFFDC3545) : const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // 거래 금액
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  widget.transaction.formattedAmount,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isWithdrawal ? const Color(0xFFDC3545) : const Color(0xFF34C759),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 추가 정보 (잔액, 계좌번호)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '거래 후 잔액',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.transaction.formattedBalance,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '상대방 계좌번호',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.transaction.transactionAccount,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('이전 페이지로 돌아갑니다.');
    Navigator.of(context).pop();
  }

  void _handleHome(BuildContext context) {
    _hapticService.vibrateCustomSequence('double_tick');
    _ttsService.speak('메인 화면으로 이동합니다.');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
} 