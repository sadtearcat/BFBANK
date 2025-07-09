import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../widgets/default_page.dart';
import '../../../handwriting_recognition/widgets/handwriting_input_modal.dart';
import 'create_account_success_page.dart';

class CreateAccountPasswordPage extends StatefulWidget {
  final AccountProduct product;
  final Map<String, String> personalInfo;

  const CreateAccountPasswordPage({
    super.key,
    required this.product,
    required this.personalInfo,
  });

  @override
  State<CreateAccountPasswordPage> createState() => _CreateAccountPasswordPageState();
}

class _CreateAccountPasswordPageState extends State<CreateAccountPasswordPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordValidated = false;
  bool _confirmPasswordValidated = false;
  bool _isCreating = false;
  String _errorMessage = '';
  String _password = ''; // 키패드 입력용 비밀번호

  @override
  void initState() {
    super.initState();
    
    // 페이지 진입 시 자동 음성 안내와 햅틱
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hapticService.vibrateCustomSequence('notification');
      _ttsService.speak('${widget.personalInfo['name']}님, 계좌 비밀번호를 설정해주세요.');
    });
    
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _passwordValidated = password.length == 4 && RegExp(r'^[0-9]+$').hasMatch(password);
    });
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _confirmPasswordValidated = confirmPassword.isNotEmpty && 
                                 password == confirmPassword &&
                                 _passwordValidated;
      if (confirmPassword.isNotEmpty && password != confirmPassword) {
        _errorMessage = '비밀번호가 일치하지 않습니다';
      } else if (_passwordValidated && _confirmPasswordValidated) {
        _errorMessage = '';
      }
    });
  }

  void _handleHandwritingInput(bool isConfirmPassword) {
    _hapticService.vibrateCustomSequence('tick');
    final targetController = isConfirmPassword ? _confirmPasswordController : _passwordController;
    
    showDialog(
      context: context,
      builder: (context) => HandwritingInputModal(
        onDigitRecognized: (text) {
          if (text.length <= 4) {
            setState(() {
              targetController.text = text;
            });
            _ttsService.speak(isConfirmPassword ? '비밀번호 확인이 입력되었습니다.' : '비밀번호가 입력되었습니다.');
          } else {
            _ttsService.speak('비밀번호는 4자리까지만 입력할 수 있습니다.');
          }
        },
      ),
    );
  }

  void _addDigit(String digit) {
    if (_password.length < 6) {
      setState(() {
        _password += digit;
      });
      _hapticService.vibrateCustomSequence('tick');
      _ttsService.speak(digit);
    }
  }

  void _deleteLastDigit() {
    if (_password.isNotEmpty) {
      setState(() {
        _password = _password.substring(0, _password.length - 1);
      });
      _hapticService.vibrateCustomSequence('tick');
      _ttsService.speak('삭제');
    }
  }

  Widget _buildKeypadButton(String digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF555555),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _handleCreateAccount() async {
    if (!_passwordValidated || !_confirmPasswordValidated) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('비밀번호를 올바르게 입력해주세요.');
      return;
    }

    _hapticService.vibrateCustomSequence('tick');
    setState(() {
      _isCreating = true;
    });

    _ttsService.speak('계좌를 개설하고 있습니다. 잠시만 기다려주세요.');

    try {
      final result = await IntegratedDummyDataService.createAccount(
        product: widget.product,
        personalInfo: widget.personalInfo,
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        _hapticService.vibrateCustomSequence('success');
        _ttsService.speak('계좌 개설이 완료되었습니다.');
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CreateAccountSuccessPage(
              product: widget.product,
              personalInfo: widget.personalInfo,
              accountNumber: result['accountNumber'],
              accountName: result['accountName'],
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        setState(() {
          _isCreating = false;
          _errorMessage = result['message'] ?? '계좌 개설에 실패했습니다.';
        });
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
        _errorMessage = '계좌 개설 중 오류가 발생했습니다.';
      });
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak(_errorMessage);
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
          lowerLeftWidget: _buildButtonContent('assets/icons/Cancel.svg', '취소'),
          lowerRightWidget: _buildButtonContent('assets/icons/Check.svg', '계좌개설'),
          onUpperLeftPress: _handleGoBack,
          onUpperRightPress: _handleGoHome,
          onLowerLeftPress: _handleGoBack,
          onLowerRightPress: _isCreating ? null : _handleCreateAccount,
          // TTS 메시지 추가
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '취소',
          lowerRightTTS: '계좌개설',
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
                    const message = '계좌 비밀번호를 설정하세요. 6자리 숫자로 입력해주세요.';
                    _ttsService.speak(message);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/icons/Volume.svg', width: 30, height: 30, color: Colors.white),
                      const SizedBox(width: 20),
                      const Text(
                        '비밀번호 설정 안내',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      const Text(
                        '계좌 비밀번호 설정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 안내 메시지
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '계좌 이용을 위한 6자리 숫자 비밀번호를 설정하세요.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• 연속된 숫자나 동일한 숫자는 피해주세요\n• 생년월일 등 개인정보와 관련된 숫자는 피해주세요',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 비밀번호 입력
                      const Text(
                        '비밀번호 입력',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 비밀번호 표시 영역
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: index < _password.length 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  index < _password.length ? '●' : '',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 숫자 키패드
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            if (index == 9) {
                              // 빈 공간
                              return Container();
                            } else if (index == 10) {
                              // 0
                              return _buildKeypadButton('0');
                            } else if (index == 11) {
                              // 삭제 버튼
                              return GestureDetector(
                                onTap: _deleteLastDigit,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF555555),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.backspace,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // 1-9
                              return _buildKeypadButton('${index + 1}');
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 비밀번호 확인 상태
                      if (_password.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _password.length == 6 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _password.length == 6 
                                    ? Icons.check_circle 
                                    : Icons.info,
                                color: _password.length == 6 
                                    ? Colors.green 
                                    : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _password.length == 6 
                                    ? '비밀번호가 설정되었습니다.' 
                                    : '${_password.length}/6 자리 입력됨',
                                style: TextStyle(
                                  color: _password.length == 6 
                                      ? Colors.green 
                                      : Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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