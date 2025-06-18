import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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
    // 로케일 데이터가 초기화되지 않았을 경우를 대비한 안전장치
    try {
      await initializeDateFormatting('ko_KR', null);
    } catch (e) {
      // 이미 초기화된 경우 예외가 발생할 수 있으므로 무시
      print('Locale data already initialized or error: $e');
    }
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
    
    // React Native formatDateManually와 동일한 형식
    String formattedDate;
    String formattedTime;
    
    try {
      final dateFormat = DateFormat('yyyy년 MM월 dd일', 'ko_KR');
      final timeFormat = DateFormat('HH:mm:ss', 'ko_KR');
      formattedDate = dateFormat.format(widget.transaction.transactionDate);
      formattedTime = timeFormat.format(widget.transaction.transactionDate);
    } catch (e) {
      // 폴백: 로케일 오류 시 기본 포맷 사용
      final date = widget.transaction.transactionDate;
      formattedDate = "${date.year}년 ${date.month}월 ${date.day}일";
      formattedTime = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
      print('Error using DateFormat: $e');
    }
    
    // React Native와 동일한 TTS 메시지 형식
    final fullMessage = '''$formattedDate

$formattedTime

${widget.transaction.transactionName}

${widget.transaction.formattedAmount}

${typeLabel}되었습니다.''';
    
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
          upperLeftWidget: _buildButtonContent('assets/icons/ArrowLeft.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent('assets/icons/Cancel.svg', '취소'),
          lowerRightWidget: _buildButtonContent('assets/icons/Check.svg', '확인'),
          mainWidget: GestureDetector(
            onTap: () {
              _hapticService.vibrateCustomSequence('tick');
              _speakTransactionDetail();
            },
            child: _buildTransactionDetailContent(),
          ),
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

  Widget _buildButtonContent(String assetPath, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          assetPath,
          width: 60,
          height: 60,
          color: Colors.white,
        ),
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
    // 안전한 DateFormat 사용 - React Native formatDateManually와 동일한 형식
    String formattedDate;
    String formattedTime;
    
    try {
      final dateFormat = DateFormat('yyyy년 MM월 dd일', 'ko_KR');
      final timeFormat = DateFormat('HH:mm:ss', 'ko_KR');
      formattedDate = dateFormat.format(widget.transaction.transactionDate);
      formattedTime = timeFormat.format(widget.transaction.transactionDate);
    } catch (e) {
      // 폴백: 로케일 오류 시 기본 포맷 사용
      final date = widget.transaction.transactionDate;
      formattedDate = "${date.year}년 ${date.month}월 ${date.day}일";
      formattedTime = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
      print('Error using DateFormat: $e');
    }
    
    final isWithdrawal = widget.transaction.transactionType == 'WITHDRAWAL';
    final typeLabel = widget.transaction.typeLabel;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 음성 안내 버튼 (React Native와 동일한 스타일)
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                const SizedBox(width: 12),
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
          
          // 날짜와 시간 (React Native와 동일한 레이아웃)
          Column(
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

          // 거래 이름 (React Native와 동일한 스타일)
          Text(
            widget.transaction.transactionName,
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.left,
          ),

          const SizedBox(height: 26),

          // 거래 타입과 금액 (React Native bankContainer와 동일한 레이아웃)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  widget.transaction.formattedAmount,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
    Navigator.of(context).pushNamedAndRemoveUntil('/bfbank-main', (route) => false);
  }
} 

