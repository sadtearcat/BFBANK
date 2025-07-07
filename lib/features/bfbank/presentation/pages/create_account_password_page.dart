import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/account_product.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/tts_service.dart';
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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordValidated = false;
  bool _confirmPasswordValidated = false;
  bool _isCreating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _ttsService.speak('${widget.personalInfo['name']}님, 계좌 비밀번호를 설정해주세요.');
    
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  void _handleCreateAccount() async {
    if (!_passwordValidated || !_confirmPasswordValidated) {
      _ttsService.speak('비밀번호를 올바르게 입력해주세요.');
      return;
    }

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
        _ttsService.speak(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
        _errorMessage = '계좌 개설 중 오류가 발생했습니다.';
      });
      _ttsService.speak(_errorMessage);
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
      lowerLeftWidget: _buildButtonContent(Icons.cancel, '취소'),
      lowerRightWidget: _buildButtonContent(Icons.check, '계좌개설'),
      onUpperLeftPress: _handleGoBack,
      onUpperRightPress: _handleGoHome,
      onLowerLeftPress: _handleGoBack,
      onLowerRightPress: _isCreating ? null : _handleCreateAccount,
      mainWidget: _isCreating
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 32),
                Text(
                  '계좌를 개설하고 있습니다',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                const Text(
                  '계좌 비밀번호 설정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // 비밀번호 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 24),
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _passwordValidated ? Colors.green : Colors.white54,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _handleHandwritingInput(false),
                      icon: const Icon(Icons.draw, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 비밀번호 확인 입력 필드
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 24),
                        decoration: InputDecoration(
                          labelText: '비밀번호 확인',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _confirmPasswordValidated ? Colors.green : Colors.white54,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _handleHandwritingInput(true),
                      icon: const Icon(Icons.draw, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),

                // 에러 메시지
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                // 성공 메시지
                if (_passwordValidated && _confirmPasswordValidated) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '비밀번호가 올바르게 설정되었습니다',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
} 