import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../widgets/default_page.dart';
import 'create_account_detail_page.dart';

class CreateAccountMainPage extends StatefulWidget {
  const CreateAccountMainPage({super.key});

  @override
  State<CreateAccountMainPage> createState() => _CreateAccountMainPageState();
}

class _CreateAccountMainPageState extends State<CreateAccountMainPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final PageController _pageController = PageController();
  
  List<AccountProduct> _accountProducts = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountProducts();
    
    // 페이지 진입 시 자동 음성 안내와 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hapticService.vibrateCustomSequence('notification');
      _ttsService.speak('계좌 개설 페이지입니다. 원하는 계좌 상품을 선택해주세요. 화면을 좌우로 스와이프하거나 오른쪽 아래 선택 버튼을 눌러주세요.');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadAccountProducts() async {
    try {
      final products = await IntegratedDummyDataService.fetchAccountProducts();
      setState(() {
        _accountProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _ttsService.speak('계좌 상품을 불러오는데 실패했습니다.');
    }
  }

  void _handleProductSelect() {
    if (_accountProducts.isNotEmpty) {
      final selectedProduct = _accountProducts[_currentIndex];
      _hapticService.vibrateCustomSequence('tick');
      _ttsService.speak('${selectedProduct.name}이 선택되었습니다. 상세 정보를 확인하세요.');
      
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CreateAccountDetailPage(
            product: selectedProduct,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  void _handlePreviousProduct() {
    if (_currentIndex > 0) {
      _hapticService.vibrateCustomSequence('tick');
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('첫 번째 상품입니다.');
    }
  }

  void _handleNextProduct() {
    if (_currentIndex < _accountProducts.length - 1) {
      _hapticService.vibrateCustomSequence('tick');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('마지막 상품입니다.');
    }
  }

  void _handleGoBack() {
    _hapticService.vibrateCustomSequence('tick');
    Navigator.pop(context);
  }

  void _handleGoHome() {
    _hapticService.vibrateCustomSequence('tick');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: _buildButtonContent('assets/icons/ArrowLeft.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent('assets/icons/Prev.svg', '이전상품'),
          lowerRightWidget: _buildButtonContent('assets/icons/Check.svg', '선택'),
          onUpperLeftPress: _handleGoBack,
          onUpperRightPress: _handleGoHome,
          onLowerLeftPress: _handlePreviousProduct,
          onLowerRightPress: _handleProductSelect,
          // TTS 메시지 추가
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '이전상품',
          lowerRightTTS: '선택',
          mainWidget: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _accountProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '계좌 상품을 불러올 수 없습니다',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAccountProducts,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                          final currentProduct = _accountProducts[_currentIndex];
                          final message = '${currentProduct.name}. ${currentProduct.description}. 연 ${currentProduct.interestRate}% 금리 적용. ${currentProduct.benefits.join(', ')}';
                          _ttsService.speak(message);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                            const SizedBox(width: 20),
                            const Text(
                              '계좌 개설',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 계좌 상품 캐러셀
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                          final product = _accountProducts[index];
                          _hapticService.vibrateCustomSequence('tick');
                          _ttsService.speak('${product.name}. 연 ${product.interestRate}% 금리');
                        },
                        itemCount: _accountProducts.length,
                        itemBuilder: (context, index) {
                          final product = _accountProducts[index];
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              color: Colors.black54,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 상품명 (React Native 스타일)
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    
                                    // 상품 정보 (React Native 스타일)
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow('상품개요', product.features['상품개요'] ?? ''),
                                            const SizedBox(height: 10),
                                            _buildInfoRow('상품특징', product.features['상품특징'] ?? ''),
                                            const SizedBox(height: 10),
                                            _buildInfoRow('예금과목', product.features['예금과목'] ?? ''),
                                            const SizedBox(height: 10),
                                            _buildInfoRow('금리', '연 ${product.interestRate}%'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // 페이지 인디케이터
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _accountProducts.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentIndex 
                                ? Colors.white 
                                : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 현재 상품 정보
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '${_currentIndex + 1} / ${_accountProducts.length} - ${_accountProducts[_currentIndex].name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 영역 (30% 비율, React Native 스타일)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.22, // 전체 화면의 약 30%
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 내용 영역 (70% 비율, React Native 스타일)
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
} 