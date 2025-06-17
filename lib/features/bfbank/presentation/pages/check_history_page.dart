import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/models/transaction_history.dart';

class CheckHistoryPage extends StatefulWidget {
  const CheckHistoryPage({Key? key}) : super(key: key);

  @override
  State<CheckHistoryPage> createState() => _CheckHistoryPageState();
}

class _CheckHistoryPageState extends State<CheckHistoryPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  List<TransactionHistory> _histories = [];
  bool _isLoading = true;
  bool _hasAccount = true; // 임시로 true
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadTransactionHistories();
    
    // 페이지 진입 시 TTS 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
  }

  Future<void> _loadTransactionHistories() async {
    setState(() => _isLoading = true);
    
    try {
      // 실제로는 계좌 ID를 사용해서 API 호출
      final histories = await IntegratedDummyDataService.fetchTransactionHistories();
      setState(() {
        _histories = histories;
        _hasAccount = histories.isNotEmpty;
      });
      
      // 첫 번째 내역 자동 읽기
      if (_histories.isNotEmpty) {
        _speakTransactionDetail(_histories[0]);
      }
    } catch (error) {
      print('Error loading histories: $error');
      setState(() => _hasAccount = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _speakPageGuide() {
    _hapticService.vibrateCustomSequence('notification');
    // React Native와 정확히 동일한 메시지
    const guide = '''계좌 내역 화면입니다.
화면 가운데를 좌우로 움직여 계좌 내역을 조회할 수 있습니다.
왼쪽 아래와 오른쪽 아래 버튼을 눌러도 계좌 내역을 넘길 수 있습니다.
내역을 선택하시면 상세 정보를 확인하실 수 있습니다.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  void _speakTransactionDetail(TransactionHistory transaction) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH시 mm분', 'ko_KR');
    final formattedDate = dateFormat.format(transaction.transactionDate);
    
    final message = '''
    $formattedDate
    
    ${transaction.transactionName}
    
    ${transaction.formattedAmount}
    
    ${transaction.typeLabel}되었습니다.
    ''';
    
    _ttsService.speak(message);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _hapticService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_hasAccount || _histories.isEmpty) {
      return _buildNoAccountView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent(Icons.arrow_back, '이전'),
          upperRightWidget: _buildButtonContent(Icons.home, '메인'),
          lowerLeftWidget: _buildButtonContent(Icons.keyboard_arrow_left, '이전'),
          lowerRightWidget: _buildButtonContent(Icons.keyboard_arrow_right, '다음'),
          mainWidget: _buildCarouselContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: _handlePreviousTransaction,
          onLowerRightPress: _handleNextTransaction,
          // React Native와 동일한 더블탭 TTS 메시지
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '이전',
          lowerRightTTS: '다음',
        ),
      ),
    );
  }

  Widget _buildNoAccountView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent(Icons.arrow_back, '이전'),
          upperRightWidget: _buildButtonContent(Icons.home, '메인'),
          mainWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.white70,
              ),
              const SizedBox(height: 20),
              const Text(
                '등록된 계좌가 없습니다.\n계좌를 먼저 생성해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
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

  Widget _buildCarouselContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 음성 안내 버튼
        GestureDetector(
          onTap: () {
            _hapticService.vibrateCustomSequence('tick');
            if (_histories.isNotEmpty) {
              _speakTransactionDetail(_histories[_currentIndex]);
            }
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
                const Icon(Icons.volume_up, color: Colors.white, size: 25),
                const SizedBox(width: 12),
                const Text(
                  '거래 내역 듣기',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
        
        // 현재 인덱스 표시
        Text(
          '${_currentIndex + 1} / ${_histories.length}',
          style: const TextStyle(color: Colors.grey, fontSize: 18),
        ),
        const SizedBox(height: 20),
        
        // 캐러셀
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 300,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
              _hapticService.vibrateCustomSequence('tick');
              _speakTransactionDetail(_histories[index]);
            },
          ),
          items: _histories.map((transaction) {
            return Builder(
              builder: (BuildContext context) {
                return _buildTransactionCard(transaction);
              },
            );
          }).toList(),
        ),
        
        const SizedBox(height: 20),
        
        // 선택 안내
        const Text(
          '화면을 터치하여 상세 정보를 확인하세요',
          style: TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionHistory transaction) {
    final dateFormat = DateFormat('MM월 dd일 HH:mm');
    final formattedDate = dateFormat.format(transaction.transactionDate);
    
    return GestureDetector(
      onTap: () => _handleSelectTransaction(transaction),
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: transaction.isWithdrawal 
              ? const Color(0xFF2C1810) // 출금: 어두운 빨강
              : const Color(0xFF0F2419), // 입금: 어두운 초록
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: transaction.isWithdrawal 
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.green.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 거래 타입 아이콘
              Icon(
                transaction.isWithdrawal 
                    ? Icons.arrow_upward 
                    : Icons.arrow_downward,
                color: transaction.isWithdrawal ? Colors.red : Colors.green,
                size: 40,
              ),
              const SizedBox(height: 15),
              
              // 거래 상대방
              Text(
                transaction.transactionName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // 거래 금액
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  color: transaction.isWithdrawal ? Colors.red : Colors.green,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // 거래 날짜
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              
              // 거래 타입
              Text(
                transaction.typeLabel,
                style: TextStyle(
                  color: transaction.isWithdrawal ? Colors.red : Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

  void _handlePreviousTransaction() {
    if (_currentIndex > 0) {
      _carouselController.previousPage();
      _hapticService.vibrateCustomSequence('tick');
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('첫 번째 내역입니다.');
    }
  }

  void _handleNextTransaction() {
    if (_currentIndex < _histories.length - 1) {
      _carouselController.nextPage();
      _hapticService.vibrateCustomSequence('tick');
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('마지막 내역입니다.');
    }
  }

  void _handleSelectTransaction(TransactionHistory transaction) {
    _hapticService.vibrateCustomSequence('success');
    _ttsService.speak('상세 정보를 확인합니다.');
    
    // CheckHistoryDetail 페이지로 이동
    Navigator.of(context).pushNamed(
      '/check-history-detail',
      arguments: {
        'transaction': transaction,
      },
    );
  }
} 