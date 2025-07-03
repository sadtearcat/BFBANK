import 'package:flutter/material.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/models/favorite_account.dart';
import 'receiving_account_page.dart';

/// 최근 송금 계좌 선택 페이지
class SendRecentAccountPage extends StatefulWidget {
  const SendRecentAccountPage({super.key});

  @override
  State<SendRecentAccountPage> createState() => _SendRecentAccountPageState();
}

class _SendRecentAccountPageState extends State<SendRecentAccountPage> {
  final TtsService _ttsService = TtsService();
  
  List<FavoriteAccount> _recentAccounts = [];
  int _currentIndex = 0;
  FavoriteAccount? _selectedAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadFavoriteAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPageGuide();
    });
  }

  Future<void> _loadFavoriteAccounts() async {
    try {
      final accounts = await IntegratedDummyDataService.fetchFavoriteAccounts();
      setState(() {
        _recentAccounts = accounts;
        _isLoading = false;
        if (accounts.isNotEmpty) {
          _selectedAccount = accounts[0];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading favorite accounts: $e');
    }
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _speakPageGuide() {
    const guide = '''최근 송금한 계좌 목록입니다.
화면 가운데를 좌우로 움직여 송금할 계좌를 선택해주세요.
계좌 번호를 직접 입력하시려면 왼쪽 아래를,
선택을 완료하시려면 오른쪽 아래를 눌러주세요.
왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.''';
    _ttsService.speak(guide);
  }

  void _speakCurrentAccount() {
    if (_selectedAccount != null) {
      final account = _selectedAccount!;
      final accountSpaced = account.receiverAccount.split('').join(' ');
      final date = _formatDate(account.lastTransactionDate);
      
      final message = '''${account.receiverName}
${accountSpaced}
${date}에
송금한 계좌입니다.''';
      _ttsService.speak(message);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 ${date.hour}시 ${date.minute}분';
  }

  void _navigateToAccount(int direction) {
    if (_recentAccounts.isEmpty) return;
    
    setState(() {
      if (direction > 0) {
        _currentIndex = (_currentIndex + 1) % _recentAccounts.length;
      } else {
        _currentIndex = (_currentIndex - 1 + _recentAccounts.length) % _recentAccounts.length;
      }
      _selectedAccount = _recentAccounts[_currentIndex];
    });
    
    _speakCurrentAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultPage(
          upperLeftWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_ios, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('이전', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          upperRightWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('메인', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          lowerLeftWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('입력', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          lowerRightWidget: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, color: Colors.white, size: 60),
              SizedBox(height: 8),
              Text('선택', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          mainWidget: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF3B82F6),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Voice button
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up, color: Colors.white, size: 30),
                        SizedBox(width: 20),
                        Text(
                          '송금 하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Account carousel
                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      '계좌 목록을 불러오는 중...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ] else if (_recentAccounts.isNotEmpty) ...[
                    GestureDetector(
                      onPanUpdate: (details) {
                        // 좌우 스와이프 감지
                        if (details.delta.dx > 5) {
                          _navigateToAccount(-1); // 왼쪽으로 스와이프 = 이전 계좌
                        } else if (details.delta.dx < -5) {
                          _navigateToAccount(1); // 오른쪽으로 스와이프 = 다음 계좌
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _selectedAccount!.receiverName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedAccount!.receiverAccount,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedAccount!.receiverBankName,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _formatDate(_selectedAccount!.lastTransactionDate),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '송금 횟수: ${_selectedAccount!.frequency}회',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 페이지 인디케이터
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_recentAccounts.length, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentIndex ? Colors.white : Colors.white30,
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 20),
                    const Text(
                      '좌우로 밀어서 선택하세요',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '최근 송금 내역이 없습니다',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '직접 입력',
          lowerRightTTS: '선택 완료',
          onUpperLeftPress: () => Navigator.pop(context),
          onUpperRightPress: () => Navigator.popUntil(context, (route) => route.isFirst),
          onLowerLeftPress: () => Navigator.pop(context),
          onLowerRightPress: () => _handleSelectAccount(context),
        ),
      ),
    );
  }

  void _handleSelectAccount(BuildContext context) {
    if (_selectedAccount != null) {
      // FavoriteAccount를 ReceivingAccountPage가 받는 형식으로 변환
      final selectedAccountMap = {
        'receiverName': _selectedAccount!.receiverName,
        'receiverAccount': _selectedAccount!.receiverAccount,
        'bankName': _selectedAccount!.receiverBankName,
      };
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceivingAccountPage(
            selectedAccount: selectedAccountMap,
          ),
        ),
      );
    }
  }
} 