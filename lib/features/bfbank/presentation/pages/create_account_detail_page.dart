import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../widgets/default_page.dart';
import 'create_account_id_verification_page.dart';

class CreateAccountDetailPage extends StatefulWidget {
  final AccountProduct product;

  const CreateAccountDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<CreateAccountDetailPage> createState() => _CreateAccountDetailPageState();
}

class _CreateAccountDetailPageState extends State<CreateAccountDetailPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final ScrollController _scrollController = ScrollController();
  
  AccountTerms? _accountTerms;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
    
    // 페이지 진입 시 자동 음성 안내와 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hapticService.vibrateCustomSequence('notification');
      _ttsService.speak('${widget.product.name} 상세 안내 페이지입니다. 약관 내용을 들으시려면 화면 가운데를 한 번 눌러주세요. 오른쪽 아래 확인 버튼을 누르면 본인 인증으로 이동합니다.');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    try {
      final terms = await IntegratedDummyDataService.fetchAccountTerms();
      setState(() {
        _accountTerms = terms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _ttsService.speak('약관 정보를 불러오는데 실패했습니다.');
    }
  }

  void _handleConfirm() {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('본인 인증을 진행합니다. 신분증을 준비해주세요.');
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CreateAccountIdVerificationPage(
          product: widget.product,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _handleGoBack() {
    _hapticService.vibrateCustomSequence('tick');
    Navigator.pop(context);
  }

  void _handleGoHome() {
    _hapticService.vibrateCustomSequence('tick');
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleReadTerms() {
    _hapticService.vibrateCustomSequence('tick');
    if (_accountTerms != null) {
      final fullMessage = [
        widget.product.name,
        _accountTerms!.content,
        ..._accountTerms!.sections.map((section) {
          return '${section.title}. ${section.content.join(' ')}';
        }),
      ].join('. ');
      
      _ttsService.speak(fullMessage);
    } else {
      _ttsService.speak('약관 정보를 불러오는 중입니다.');
    }
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
          upperLeftWidget: _buildButtonContent('assets/icons/GoBack.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent('assets/icons/Draw.svg', '약관'),
          lowerRightWidget: _buildButtonContent('assets/icons/Check.svg', '확인'),
          onUpperLeftPress: _handleGoBack,
          onUpperRightPress: _handleGoHome,
          onLowerLeftPress: _handleReadTerms,
          onLowerRightPress: _handleConfirm,
          // TTS 메시지 추가
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '약관',
          lowerRightTTS: '확인',
          mainWidget: GestureDetector(
            onTap: _handleReadTerms,
            child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          onTap: _handleReadTerms,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                              const SizedBox(width: 20),
                              const Text(
                                '약관 상세 안내',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 상품명 (React Native 스타일)
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 상품 기본 정보
                      Card(
                        color: Colors.black54,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '상품 정보',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildProductInfo('분류', widget.product.category),
                              _buildProductInfo('금리', '연 ${widget.product.interestRate}%'),
                              _buildProductInfo('최소입금액', '${widget.product.minimumAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'),
                              _buildProductInfo('최대입금액', '${widget.product.maximumAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원'),
                            ],
                          ),
                        ),
                      ),

                      // 약관 내용
                      if (_accountTerms != null) ...[
                        Card(
                          color: Colors.black54,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _accountTerms!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Text(
                                  _accountTerms!.content,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 약관 세부 내용
                                ..._accountTerms!.sections.map((section) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...section.content.map((content) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          content,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Card(
                          color: Colors.black54,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '약관 정보를 불러올 수 없습니다',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadTerms,
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // 안내 메시지
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '안내',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '계좌 개설을 위해서는 본인 인증이 필요합니다.\n신분증을 준비해 주세요.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 