import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../widgets/default_page.dart';
import '../../../object_detection/presentation/pages/camera_detection_page.dart';
import 'create_account_password_page.dart';

class CreateAccountIdVerificationPage extends StatefulWidget {
  final AccountProduct product;

  const CreateAccountIdVerificationPage({
    super.key,
    required this.product,
  });

  @override
  State<CreateAccountIdVerificationPage> createState() => _CreateAccountIdVerificationPageState();
}

class _CreateAccountIdVerificationPageState extends State<CreateAccountIdVerificationPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  
  bool _isProcessing = false;
  Map<String, String>? _ocrResult;
  String _verificationStatus = 'idle'; // idle, camera, processing, success, failed

  @override
  void initState() {
    super.initState();
    
    // 페이지 진입 시 자동 음성 안내와 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hapticService.vibrateCustomSequence('notification');
      _ttsService.speak('본인 인증 페이지입니다. 신분증을 준비하시고 오른쪽 아래 신분증 촬영 버튼을 눌러주세요.');
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _handleStartCamera() {
    _hapticService.vibrateCustomSequence('tick');
    setState(() {
      _verificationStatus = 'camera';
    });
    
    _ttsService.speak('카메라를 시작합니다. 신분증을 화면에 맞춰주세요.');
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CameraDetectionPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((result) {
      // 카메라에서 돌아왔을 때 처리
      if (result != null && result is String) {
        // 실제로는 갤러리에서 가장 최근 이미지를 가져와야 함
        _processIdCard(result);
      } else {
        setState(() {
          _verificationStatus = 'idle';
        });
        _ttsService.speak('신분증 촬영이 취소되었습니다.');
      }
    });
  }

  void _processIdCard(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _verificationStatus = 'processing';
    });
    
    _ttsService.speak('신분증을 인식하고 있습니다. 잠시 기다려주세요.');
    
    try {
      final result = await IntegratedDummyDataService.processIdCardOcr(imagePath);
      
      if (result['status'] == 'success') {
        setState(() {
          _ocrResult = result;
          _verificationStatus = 'success';
          _isProcessing = false;
        });
        
        _hapticService.vibrateCustomSequence('success');
        _ttsService.speak('본인 인증이 완료되었습니다. ${result['name']}님, 계좌 비밀번호를 설정해주세요.');
      } else {
        setState(() {
          _verificationStatus = 'failed';
          _isProcessing = false;
        });
        
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak('신분증 인식에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      setState(() {
        _verificationStatus = 'failed';
        _isProcessing = false;
      });
      
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('인증 처리 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _handleRetry() {
    _hapticService.vibrateCustomSequence('tick');
    setState(() {
      _verificationStatus = 'idle';
      _ocrResult = null;
    });
    
    _ttsService.speak('다시 신분증을 촬영해주세요.');
  }

  void _handleConfirm() {
    if (_ocrResult != null) {
      _hapticService.vibrateCustomSequence('tick');
      _ttsService.speak('계좌 비밀번호 설정으로 이동합니다.');
      
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CreateAccountPasswordPage(
            product: widget.product,
            personalInfo: _ocrResult!,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
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
          upperLeftWidget: _buildButtonContent('assets/icons/GoBack.svg', '이전'),
          upperRightWidget: _buildButtonContent('assets/icons/Home.svg', '메인'),
          lowerLeftWidget: _buildButtonContent(
            _verificationStatus == 'success' ? 'assets/icons/Cancel.svg' : 'assets/icons/Cancel.svg',
            _verificationStatus == 'success' ? '재촬영' : '취소',
          ),
          lowerRightWidget: _buildButtonContent(
            _verificationStatus == 'success' ? 'assets/icons/Check.svg' : 'assets/icons/QR.svg',
            _verificationStatus == 'success' ? '확인' : '신분증촬영',
          ),
          onUpperLeftPress: _handleGoBack,
          onUpperRightPress: _handleGoHome,
          onLowerLeftPress: _verificationStatus == 'success' ? _handleRetry : _handleGoBack,
          onLowerRightPress: _verificationStatus == 'success' ? _handleConfirm : _handleStartCamera,
          // TTS 메시지 추가
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: _verificationStatus == 'success' ? '재촬영' : '취소',
          lowerRightTTS: _verificationStatus == 'success' ? '확인' : '신분증촬영',
          mainWidget: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      _hapticService.vibrateCustomSequence('tick');
                      _ttsService.speak('본인 인증 페이지입니다. 신분증을 준비하시고 오른쪽 아래 신분증 촬영 버튼을 눌러주세요.');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                        const SizedBox(width: 20),
                        const Text(
                          '본인 인증',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 제목
                const Text(
                  '본인 인증',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  '${widget.product.name} 계좌 개설',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),

                // 상태별 콘텐츠
                Expanded(
                  child: _buildStatusContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_verificationStatus) {
      case 'idle':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 24),
            const Text(
              '신분증을 준비해주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '본인 확인을 위해 신분증 촬영이 필요합니다.\n오른쪽 아래 신분증촬영 버튼을 눌러주세요.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'camera':
      case 'processing':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              _verificationStatus == 'camera' ? '카메라를 시작하고 있습니다...' : '신분증을 인식하고 있습니다...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );

      case 'success':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              '본인 인증 완료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_ocrResult != null) ...[
              Text(
                '${_ocrResult!['name']}님',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '본인 확인이 완료되었습니다.\n오른쪽 아래 확인 버튼을 눌러 계속 진행하세요.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );

      case 'failed':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              '인증 실패',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '신분증 인식에 실패했습니다.\n다시 시도해주세요.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildIdleContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white54,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white54,
                size: 80,
              ),
              SizedBox(height: 16),
              Text(
                '신분증을\n준비해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        const Text(
          '주민등록증 또는 운전면허증을\n준비하신 후 촬영 버튼을 눌러주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: _handleStartCamera,
          icon: const Icon(Icons.camera_alt),
          label: const Text(
            '신분증 촬영하기',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
        SizedBox(height: 32),
        
        Text(
          '신분증을 인식하고 있습니다',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        
        Text(
          '잠시만 기다려주세요...',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          const SizedBox(height: 24),
          
          const Text(
            '본인 인증 완료',
            style: TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          if (_ocrResult != null) ...[
            Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '인증된 정보',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoRow('이름', _ocrResult!['name'] ?? ''),
                    _buildInfoRow('생년월일', _ocrResult!['birthDate'] ?? ''),
                    _buildInfoRow('인증률', '${(double.parse(_ocrResult!['confidence'] ?? '0') * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '인증 성공',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '이제 계좌 비밀번호를 설정해주세요.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFailedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error,
          color: Colors.red,
          size: 80,
        ),
        const SizedBox(height: 24),
        
        const Text(
          '인증 실패',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          '신분증 인식에 실패했습니다.\n다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red,
              width: 1,
            ),
          ),
          child: const Column(
            children: [
              Text(
                '촬영 팁',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• 신분증이 화면 중앙에 위치하도록 해주세요\n• 조명이 충분한 곳에서 촬영해주세요\n• 신분증이 선명하게 보이도록 해주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        ElevatedButton.icon(
          onPressed: _handleRetry,
          icon: const Icon(Icons.refresh),
          label: const Text(
            '다시 시도',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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