import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/default_page.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/integrated_dummy_data_service.dart';
import '../../data/services/global_tts_manager.dart';
import '../../data/services/settings_storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();
  final GlobalTtsManager _globalTts = GlobalTtsManager();
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  // 현재 선택된 설정 항목 인덱스
  int _currentIndex = 0;
  
  // 설정 값들
  bool _ttsEnabled = true;
  bool _hapticEnabled = true;
  bool _voiceGuidanceOnPageEnter = true;
  bool _autoLogin = false;
  double _speechRate = 0.5;
  double _volume = 1.0;
  bool _ttsQueueMode = false;
  int _ttsMaxQueueSize = 5;
  
  bool _isLoading = true;
  
  // 설정 항목들 정의
  List<SettingItem> _settingItems = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSettings();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isLoading && _voiceGuidanceOnPageEnter) {
          _speakPageGuide();
        }
      });
    });
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
  }

  void _initializeSettingItems() {
    _settingItems = [
      // 사용자 정보
      SettingItem(
        type: SettingType.info,
        title: '사용자 정보',
        description: '현재 로그인된 사용자의 정보를 확인할 수 있습니다',
        category: '사용자',
      ),
      
      // 접근성 설정
      SettingItem(
        type: SettingType.toggle,
        title: 'TTS 음성 안내',
        description: 'Text-to-Speech 기능을 사용하여 화면의 내용을 음성으로 안내합니다',
        category: '접근성',
        value: _ttsEnabled,
        onToggle: (value) {
          setState(() => _ttsEnabled = value);
          _ttsService.speak(value ? 'TTS 음성 안내가 활성화되었습니다' : 'TTS 음성 안내가 비활성화되었습니다');
          _saveSettingsInBackground();
        },
      ),
      
      SettingItem(
        type: SettingType.toggle,
        title: '햅틱 피드백',
        description: '터치나 동작에 대한 진동 피드백을 제공합니다',
        category: '접근성',
        value: _hapticEnabled,
        onToggle: (value) {
          setState(() => _hapticEnabled = value);
          if (value) _hapticService.vibrateCustomSequence('success');
          _ttsService.speak(value ? '햅틱 피드백이 활성화되었습니다' : '햅틱 피드백이 비활성화되었습니다');
          _saveSettingsInBackground();
        },
      ),
      
      SettingItem(
        type: SettingType.toggle,
        title: '페이지 진입 시 음성 안내',
        description: '새로운 페이지에 진입할 때 자동으로 해당 페이지의 사용 방법을 안내합니다',
        category: '접근성',
        value: _voiceGuidanceOnPageEnter,
        onToggle: (value) {
          setState(() => _voiceGuidanceOnPageEnter = value);
          _ttsService.speak(value ? '페이지 진입 시 음성 안내가 활성화되었습니다' : '페이지 진입 시 음성 안내가 비활성화되었습니다');
          _saveSettingsInBackground();
        },
      ),
      
      // 음성 설정
      SettingItem(
        type: SettingType.slider,
        title: '음성 속도',
        description: 'TTS 음성 안내의 재생 속도를 조절합니다. 느림(10%)부터 빠름(100%)까지 설정할 수 있습니다',
        category: '음성',
        value: _speechRate,
        min: 0.1,
        max: 1.0,
        onSliderChange: (value) {
          setState(() => _speechRate = value);
          _ttsService.setSpeechRate(value);
          _saveSettingsInBackground();
        },
        onSliderEnd: (value) {
          final percentage = ((value - 0.1) / (1.0 - 0.1) * 100).round();
          _ttsService.speak('음성 속도가 $percentage퍼센트로 설정되었습니다');
        },
      ),
      
      SettingItem(
        type: SettingType.slider,
        title: '음성 볼륨',
        description: 'TTS 음성 안내의 볼륨을 조절합니다. 작음(10%)부터 큼(100%)까지 설정할 수 있습니다',
        category: '음성',
        value: _volume,
        min: 0.1,
        max: 1.0,
        onSliderChange: (value) {
          setState(() => _volume = value);
          _ttsService.setVolume(value);
          _saveSettingsInBackground();
        },
        onSliderEnd: (value) {
          final percentage = ((value - 0.1) / (1.0 - 0.1) * 100).round();
          _ttsService.speak('음성 볼륨이 $percentage퍼센트로 설정되었습니다');
        },
      ),
      
      SettingItem(
        type: SettingType.toggle,
        title: 'TTS 큐 모드',
        description: '여러 음성 안내가 동시에 발생할 때 순서대로 재생할지, 즉시 교체할지를 설정합니다',
        category: '음성',
        value: _ttsQueueMode,
        onToggle: (value) {
          setState(() => _ttsQueueMode = value);
          _globalTts.setQueueMode(value);
          _ttsService.speak(value ? 'TTS 큐 모드가 활성화되었습니다. 음성 안내가 순서대로 재생됩니다' : 'TTS 즉시 재생 모드가 활성화되었습니다. 새로운 음성이 기존 음성을 중단합니다');
          _saveSettingsInBackground();
          // TTS 큐 모드 변경 시 설정 항목 다시 초기화
          _initializeSettingItems();
        },
      ),
      
      // TTS 큐 모드가 활성화된 경우에만 표시
      if (_ttsQueueMode)
        SettingItem(
          type: SettingType.intSlider,
          title: '최대 큐 크기',
          description: 'TTS 큐 모드에서 한 번에 저장할 수 있는 최대 음성 안내 개수를 설정합니다',
          category: '음성',
          value: _ttsMaxQueueSize,
          min: 1,
          max: 15,
          onIntSliderChange: (value) {
            setState(() => _ttsMaxQueueSize = value);
            _globalTts.setMaxQueueSize(value);
            _ttsService.speak('최대 큐 크기가 $value개로 설정되었습니다');
            _saveSettingsInBackground();
          },
        ),
      
      // 앱 설정
      SettingItem(
        type: SettingType.toggle,
        title: '자동 로그인',
        description: '앱을 실행할 때 별도의 로그인 절차 없이 자동으로 메인 화면으로 이동합니다',
        category: '앱',
        value: _autoLogin,
        onToggle: (value) {
          setState(() => _autoLogin = value);
          _ttsService.speak(value ? '자동 로그인이 활성화되었습니다' : '자동 로그인이 비활성화되었습니다');
          _saveSettingsInBackground();
        },
      ),
    ];
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await SettingsStorageService.loadSettings();
      
      setState(() {
        _ttsEnabled = settings['ttsEnabled'] ?? true;
        _hapticEnabled = settings['hapticEnabled'] ?? true;
        _speechRate = (settings['speechRate'] ?? 0.5).toDouble().clamp(0.1, 1.0);
        _volume = (settings['volume'] ?? 1.0).toDouble().clamp(0.1, 1.0);
        _voiceGuidanceOnPageEnter = settings['voiceGuidanceOnPageEnter'] ?? true;
        _autoLogin = settings['autoLogin'] ?? false;
        _ttsQueueMode = settings['ttsQueueMode'] ?? false;
        _ttsMaxQueueSize = (settings['ttsMaxQueueSize'] ?? 5).clamp(1, 15);
      });
      
      await _applySettingsToServices();
      _initializeSettingItems();
      
    } catch (error) {
      print('Error loading settings: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applySettingsToServices() async {
    _ttsService.setEnabled(_ttsEnabled);
    await _ttsService.setSpeechRate(_speechRate);
    await _ttsService.setVolume(_volume);
    _globalTts.setQueueMode(_ttsQueueMode);
    _globalTts.setMaxQueueSize(_ttsMaxQueueSize);
    _hapticService.setEnabled(_hapticEnabled);
  }

  void _saveSettingsInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _applySettingsToServices();
        await SettingsStorageService.saveSettings(
          ttsEnabled: _ttsEnabled,
          hapticEnabled: _hapticEnabled,
          voiceGuidanceOnPageEnter: _voiceGuidanceOnPageEnter,
          autoLogin: _autoLogin,
          speechRate: _speechRate,
          volume: _volume,
          ttsQueueMode: _ttsQueueMode,
          ttsMaxQueueSize: _ttsMaxQueueSize,
        );
      } catch (error) {
        print('Background save error: $error');
      }
    });
  }

  void _speakPageGuide() {
    _hapticService.vibrateCustomSequence('notification');
    final guide = '''
    설정 화면입니다.
    각 설정 항목을 좌우로 스와이프하여 확인할 수 있습니다.
    현재 총 ${_settingItems.length}개의 설정 항목이 있습니다.
    각 항목을 터치하면 상세 설명을 듣고, 더블 탭하여 설정을 변경할 수 있습니다.
    왼쪽 아래와 오른쪽 아래 버튼으로도 이전, 다음 설정으로 이동할 수 있습니다.
    ''';
    _ttsService.speak(guide);
  }

  void _speakCurrentSetting() {
    if (_settingItems.isNotEmpty && _currentIndex < _settingItems.length) {
      final item = _settingItems[_currentIndex];
      _hapticService.vibrateCustomSequence('tick');
      
      String message = '${item.category} 설정의 ${item.title}입니다. ${item.description}';
      
      switch (item.type) {
        case SettingType.toggle:
          message += ' 현재 ${item.value == true ? "활성화" : "비활성화"} 상태입니다. 더블 탭하여 변경할 수 있습니다.';
          break;
                 case SettingType.slider:
           final percentage = (((item.value as double) - item.min!) / (item.max! - item.min!) * 100).round();
           message += ' 현재 $percentage퍼센트로 설정되어 있습니다. 더블 탭하여 조절할 수 있습니다.';
           break;
        case SettingType.intSlider:
          message += ' 현재 ${item.value}개로 설정되어 있습니다. 더블 탭하여 조절할 수 있습니다.';
          break;
        case SettingType.info:
          message += ' 터치하여 정보를 확인할 수 있습니다.';
          break;
      }
      
      _ttsService.speak(message);
    }
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

  void _handlePreviousSetting() {
    if (_currentIndex > 0) {
      _carouselController.previousPage();
      _hapticService.vibrateCustomSequence('tick');
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('첫 번째 설정입니다.');
    }
  }

  void _handleNextSetting() {
    if (_currentIndex < _settingItems.length - 1) {
      _carouselController.nextPage();
      _hapticService.vibrateCustomSequence('tick');
    } else {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('마지막 설정입니다.');
    }
  }

  Future<void> _resetSettings() async {
    _hapticService.vibrateCustomSequence('warning');
    _ttsService.speak('모든 설정을 초기화합니다.');
    
    try {
      final success = await SettingsStorageService.resetSettings();
      
      if (success) {
        setState(() {
          _ttsEnabled = true;
          _hapticEnabled = true;
          _speechRate = 0.5;
          _volume = 1.0;
          _voiceGuidanceOnPageEnter = true;
          _autoLogin = false;
          _ttsQueueMode = false;
          _ttsMaxQueueSize = 5;
          _currentIndex = 0; // 첫 번째 설정으로 이동
        });
        
        await _applySettingsToServices();
        _initializeSettingItems();
        
        _hapticService.vibrateCustomSequence('success');
        _ttsService.speak('모든 설정이 기본값으로 초기화되었습니다.');
      } else {
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak('설정 초기화에 실패했습니다.');
      }
    } catch (error) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('설정 초기화 중 오류가 발생했습니다.');
    }
  }

  Future<void> _saveSettings() async {
    _hapticService.vibrateCustomSequence('notification');
    _ttsService.speak('모든 설정을 저장하고 있습니다.');
    
    await _applySettingsToServices();
    
    try {
      final success = await SettingsStorageService.saveSettings(
        ttsEnabled: _ttsEnabled,
        hapticEnabled: _hapticEnabled,
        voiceGuidanceOnPageEnter: _voiceGuidanceOnPageEnter,
        autoLogin: _autoLogin,
        speechRate: _speechRate,
        volume: _volume,
        ttsQueueMode: _ttsQueueMode,
        ttsMaxQueueSize: _ttsMaxQueueSize,
      );
      
      if (success) {
        _hapticService.vibrateCustomSequence('success');
        _ttsService.speak('모든 설정이 성공적으로 저장되었습니다.');
        _showSuccessDialog();
      } else {
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak('설정 저장에 실패했습니다.');
      }
    } catch (error) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('설정 저장 중 오류가 발생했습니다.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text('설정 저장 완료', style: TextStyle(color: Colors.white)),
          content: const Text('설정이 성공적으로 저장되었습니다.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                _hapticService.vibrateCustomSequence('tick');
                Navigator.of(context).pop();
                _ttsService.speak('확인');
              },
              child: const Text('확인', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
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
          onLowerLeftPress: _handlePreviousSetting,
          onLowerRightPress: _handleNextSetting,
          upperLeftTTS: '이전',
          upperRightTTS: '메인',
          lowerLeftTTS: '이전 설정',
          lowerRightTTS: '다음 설정',
        ),
      ),
    );
  }

  Widget _buildButtonContent(String assetPath, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(assetPath, width: 48, height: 48, color: Colors.white),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCarouselContent() {
    if (_settingItems.isEmpty) {
      return const Center(
        child: Text('설정을 불러오는 중입니다...', style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 음성 안내 버튼
          GestureDetector(
            onTap: _speakCurrentSetting,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
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
                  const Text('설정 항목 듣기', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
          ),
          
          // 현재 인덱스 표시
          Text(
            '${_currentIndex + 1} / ${_settingItems.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 15),
          
          // 캐러셀
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
                  // 자동 음성 안내는 제거 (너무 시끄러울 수 있음)
                },
              ),
            items: _settingItems.map((settingItem) {
              return Builder(
                builder: (BuildContext context) {
                  return _buildSettingCard(settingItem);
                },
              );
            }).toList(),
            ),
          ),
          
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildSettingCard(SettingItem item) {
    final user = IntegratedDummyDataService.getCurrentUser();
    
    Color cardColor;
    Color borderColor;
    
    switch (item.category) {
      case '사용자':
        cardColor = const Color(0xFF2D1810);
        borderColor = Colors.orange.withValues(alpha: 0.3);
        break;
      case '접근성':
        cardColor = const Color(0xFF0F2419);
        borderColor = Colors.green.withValues(alpha: 0.3);
        break;
      case '음성':
        cardColor = const Color(0xFF1A1D3A);
        borderColor = Colors.blue.withValues(alpha: 0.3);
        break;
      case '앱':
        cardColor = const Color(0xFF2A1A2A);
        borderColor = Colors.purple.withValues(alpha: 0.3);
        break;
      default:
        cardColor = const Color(0xFF333333);
        borderColor = Colors.grey.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: () {
        _speakCurrentSetting();
      },
      onDoubleTap: () {
        _handleSettingInteraction(item);
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카테고리 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              
              // 제목
              Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              
              // 현재 값 표시
              _buildCurrentValue(item),
              const SizedBox(height: 10),
              
              // 설명
              Expanded(
                child: Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.3),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 사용자 정보인 경우 추가 정보 표시
              if (item.type == SettingType.info) ...[
                const SizedBox(height: 10),
                Text('${user.username} 님', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(user.phoneNumber, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ],
          ),
        ),
        ),
      );
  }

  Widget _buildCurrentValue(SettingItem item) {
    switch (item.type) {
      case SettingType.toggle:
        final isEnabled = item.value as bool;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFF4CAF50) : const Color(0xFF666666),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled ? const Color(0xFF81C784) : const Color(0xFF999999),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isEnabled ? Icons.check : Icons.close,
                  size: 14,
                  color: isEnabled ? const Color(0xFF4CAF50) : const Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEnabled ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
             case SettingType.slider:
         final percentage = (((item.value as double) - item.min!) / (item.max! - item.min!) * 100).round();
         return Column(
           children: [
             Text(
               '$percentage%',
               style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             LinearProgressIndicator(
               value: ((item.value as double) - item.min!) / (item.max! - item.min!),
               backgroundColor: Colors.grey.withValues(alpha: 0.3),
               valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
             ),
           ],
         );
      case SettingType.intSlider:
        return Text(
          '${item.value}개',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        );
      case SettingType.info:
        return const Icon(Icons.info, color: Colors.orange, size: 40);
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleSettingInteraction(SettingItem item) {
    switch (item.type) {
      case SettingType.toggle:
        if (item.onToggle != null) {
          final newValue = !(item.value as bool);
          // 값 먼저 업데이트
          item.value = newValue;
          // 콜백 실행 (이미 setState 포함)
          item.onToggle!(newValue);
          _hapticService.vibrateCustomSequence(newValue ? 'success' : 'warning');
          
          // 상태 변화 음성 안내
          final statusText = newValue ? '활성화되었습니다' : '비활성화되었습니다';
          _ttsService.speak('${item.title}이 $statusText');
        }
        break;
      case SettingType.slider:
        _showSliderDialog(item);
        break;
      case SettingType.intSlider:
        _showIntSliderDialog(item);
        break;
      case SettingType.info:
        _speakCurrentSetting();
        break;
    }
  }

  void _showSliderDialog(SettingItem item) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: Text(item.title, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
                         children: [
               Text(
                 '${(((item.value as double) - item.min!) / (item.max! - item.min!) * 100).round()}%',
                 style: const TextStyle(color: Colors.white, fontSize: 24),
               ),
              Slider(
                value: item.value as double,
                min: item.min!,
                max: item.max!,
                onChanged: (value) {
                  setDialogState(() {
                    item.value = value;
                  });
                  item.onSliderChange?.call(value);
                  _hapticService.vibrateCustomSequence('tick');
                },
                onChangeEnd: (value) {
                  item.onSliderEnd?.call(value);
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _ttsService.speak('설정이 완료되었습니다.');
              },
              child: const Text('완료', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntSliderDialog(SettingItem item) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: Text(item.title, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.value}개',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              Slider(
                value: (item.value as int).toDouble(),
                min: (item.min as int).toDouble(),
                max: (item.max as int).toDouble(),
                divisions: (item.max as int) - (item.min as int),
                onChanged: (value) {
                  final newValue = value.round();
                  setDialogState(() {
                    item.value = newValue;
                  });
                  item.onIntSliderChange?.call(newValue);
                  _hapticService.vibrateCustomSequence('tick');
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _ttsService.speak('설정이 완료되었습니다.');
              },
              child: const Text('완료', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}

// 설정 항목 모델
enum SettingType { toggle, slider, intSlider, info }

class SettingItem {
  final SettingType type;
  final String title;
  final String description;
  final String category;
  dynamic value;
  final double? min;
  final double? max;
  final Function(bool)? onToggle;
  final Function(double)? onSliderChange;
  final Function(double)? onSliderEnd;
  final Function(int)? onIntSliderChange;

  SettingItem({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.value,
    this.min,
    this.max,
    this.onToggle,
    this.onSliderChange,
    this.onSliderEnd,
    this.onIntSliderChange,
  });
} 