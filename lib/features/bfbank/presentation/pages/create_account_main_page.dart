import 'package:flutter/material.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
import '../widgets/default_page.dart';
import 'create_account_detail_page.dart';

class CreateAccountMainPage extends StatefulWidget {
  const CreateAccountMainPage({super.key});

  @override
  State<CreateAccountMainPage> createState() => _CreateAccountMainPageState();
}

class _CreateAccountMainPageState extends State<CreateAccountMainPage> {
  final TtsService _ttsService = TtsService();
  final PageController _pageController = PageController();
  
  List<AccountProduct> _accountProducts = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountProducts();
    _ttsService.speak('계좌 개설 페이지입니다. 원하는 계좌 상품을 선택해주세요. 화면을 좌우로 스와이프하거나 오른쪽 아래 선택 버튼을 눌러주세요.');
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextProduct() {
    if (_currentIndex < _accountProducts.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleGoBack() {
    Navigator.pop(context);
  }

  void _handleGoHome() {
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
      upperLeftWidget: _buildButtonContent(Icons.arrow_back, '이전'),
      upperRightWidget: _buildButtonContent(Icons.home, '메인'),
      lowerLeftWidget: _buildButtonContent(Icons.arrow_left, '이전상품'),
      lowerRightWidget: _buildButtonContent(Icons.check, '선택'),
      onUpperLeftPress: _handleGoBack,
      onUpperRightPress: _handleGoHome,
      onLowerLeftPress: _handlePreviousProduct,
      onLowerRightPress: _handleProductSelect,
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
                // 음성 안내 버튼 (React Native 스타일)
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: GestureDetector(
                    onTap: () {
                      final currentProduct = _accountProducts[_currentIndex];
                      final message = '${currentProduct.name}. ${currentProduct.description}. 연 ${currentProduct.interestRate}% 금리 적용. ${currentProduct.benefits.join(', ')}';
                      _ttsService.speak(message);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up, color: Colors.white, size: 30),
                          const SizedBox(width: 20),
                          const Text(
                            '계좌 개설',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
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
                      _ttsService.speak('${product.name}으로 이동했습니다.');
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