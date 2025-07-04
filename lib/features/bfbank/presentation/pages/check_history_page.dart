import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/dev_config.dart';
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
  bool _hasAccount = DevConfig.enableAutoAccountAssignment; // DevConfig로 제어
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactionHistoriesSync();
    _initializeServicesAsync();
    
    // 페이지 진입 시 TTS 안내 (지연)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _speakPageGuide();
      });
    });
  }

  void _loadTransactionHistoriesSync() {
    // 동기적으로 더미 데이터 즉시 로드
    setState(() {
      _histories = IntegratedDummyDataService.getTransactionHistories();
      _hasAccount = DevConfig.enableAutoAccountAssignment;
      _isLoading = false;
    });
  }

  Future<void> _initializeServicesAsync() async {
    // 비동기로 서비스 초기화 (UI 블로킹 방지)
    try {
      await _ttsService.initialize();
      await initializeDateFormatting('ko_KR', null);
    } catch (e) {
      print('Service initialization error: $e');
    }
  }

  void _speakPageGuide() {
    _hapticService.vibrateCustomSequence('notification');
    // 거래 내역 화면 음성 안내
    const guide = '''계좌 내역 화면입니다.
화면 가운데를 좌우로 움직여 계좌 내역을 조회할 수 있습니다.
왼쪽 아래와 오른쪽 아래 버튼을 눌러도 계좌 내역을 넘길 수 있습니다.
내역을 선택하시면 상세 정보를 확인하실 수 있습니다.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  void _speakTransactionDetail(TransactionHistory transaction) {
    // 안전한 DateFormat 사용
    String formattedDate;
    try {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH시 mm분', 'ko_KR');
      formattedDate = dateFormat.format(transaction.transactionDate);
    } catch (e) {
      // 폴백: 로케일 오류 시 기본 포맷 사용
      final date = transaction.transactionDate;
      formattedDate = "${date.year}년 ${date.month}월 ${date.day}일 ${date.hour}시 ${date.minute}분";
      print('Error using DateFormat: $e');
    }
    
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

    // 개발 단계에서는 항상 계좌가 있는 것으로 처리
    // if (!_hasAccount || _histories.isEmpty) {
    //   return _buildNoAccountView();
    // }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent('assets/icons/ArrowLeft.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent('assets/icons/Prev.svg', '이전'),
          lowerRightWidget: _buildButtonContent('assets/icons/Next.svg', '다음'),
          mainWidget: _buildCarouselContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: _handlePreviousTransaction,
          onLowerRightPress: _handleNextTransaction,
          // 더블탭 TTS 메시지
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
          upperLeftWidget: _buildButtonContent('assets/icons/ArrowLeft.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          mainWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/History2.svg', width: 100, height: 100, color: Colors.white),
              const SizedBox(height: 30),
              const Text(
                '거래 내역이 없습니다',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
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

  Widget _buildCarouselContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/Volume.svg', width: 22, height: 22, color: Colors.white),
                const SizedBox(width: 12),
                const Text('거래 내역 듣기', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
        ),
        
        // 현재 인덱스 표시
        Text(
          '${_currentIndex + 1} / ${_histories.length}',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 12),
        
        // 캐러셀 - 남은 공간을 모두 사용
        Expanded(
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: double.infinity,
              enableInfiniteScroll: false,
              enlargeCenterPage: true,
              viewportFraction: 0.85,
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
        ),
        
        const SizedBox(height: 12),
        
        // 선택 안내
        const Text(
          '화면을 터치하여 상세 정보를 확인하세요',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionHistory transaction) {
    // 안전한 DateFormat 사용
    String formattedDate;
    try {
    final dateFormat = DateFormat('MM월 dd일 HH:mm');
      formattedDate = dateFormat.format(transaction.transactionDate);
    } catch (e) {
      // 폴백: 로케일 오류 시 기본 포맷 사용
      final date = transaction.transactionDate;
      formattedDate = "${date.month}월 ${date.day}일 ${date.hour}:${date.minute}";
      print('Error using DateFormat: $e');
    }
    
    return GestureDetector(
      onTap: () {
        _hapticService.vibrateCustomSequence('tick');
        _speakTransactionDetail(transaction);
      },
      onDoubleTap: () => _handleSelectTransaction(transaction),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 거래 날짜 (상단)
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // 거래 상대방 (메인)
              Text(
                transaction.transactionName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // 거래 타입과 금액 (하단 - 한 줄로)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: transaction.isWithdrawal ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      transaction.formattedAmount,
                      style: TextStyle(
                        color: transaction.isWithdrawal ? Colors.red : Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
    Navigator.of(context).pushNamedAndRemoveUntil('/bfbank-main', (route) => false);
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