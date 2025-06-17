import 'package:flutter/material.dart';
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
  
  // 설정 값들 - 안전한 기본값으로 초기화
  bool _ttsEnabled = true;
  bool _hapticEnabled = true;
  bool _voiceGuidanceOnPageEnter = true;
  bool _autoLogin = false;
  double _speechRate = 0.5;
  double _volume = 1.0;
  
  // TTS 큐 설정 - 안전한 기본값
  bool _ttsQueueMode = false; // 기본적으로 비활성화
  int _ttsMaxQueueSize = 5; // 더 작은 기본값
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSettings();
    
    // 페이지 진입 시 TTS 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 설정 로딩 완료 후에 음성 안내 실행
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

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      print('Loading settings from SharedPreferences...');
      final settings = await SettingsStorageService.loadSettings();
      
      setState(() {
        _ttsEnabled = settings['ttsEnabled'] ?? true;
        _hapticEnabled = settings['hapticEnabled'] ?? true;
        _speechRate = (settings['speechRate'] ?? 0.5).toDouble().clamp(0.1, 1.0);
        _volume = (settings['volume'] ?? 1.0).toDouble().clamp(0.1, 1.0);
        _voiceGuidanceOnPageEnter = settings['voiceGuidanceOnPageEnter'] ?? true;
        _autoLogin = settings['autoLogin'] ?? false;
        _ttsQueueMode = settings['ttsQueueMode'] ?? false; // 기본값 false
        _ttsMaxQueueSize = (settings['ttsMaxQueueSize'] ?? 5).clamp(1, 15);
      });
      
      print('Settings loaded: TTS Queue Mode = $_ttsQueueMode, Max Queue Size = $_ttsMaxQueueSize');
      
      // 서비스에 설정 적용
      await _applySettingsToServices();
      
    } catch (error) {
      print('Error loading settings: $error');
      // 에러 시 안전한 기본값 유지
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 로드된 설정을 서비스에 적용
  Future<void> _applySettingsToServices() async {
    // TTS 서비스 설정
    _ttsService.setEnabled(_ttsEnabled);
    await _ttsService.setSpeechRate(_speechRate);
    await _ttsService.setVolume(_volume);
    
    // GlobalTtsManager 설정
    _globalTts.setQueueMode(_ttsQueueMode);
    _globalTts.setMaxQueueSize(_ttsMaxQueueSize);
    
    // 햅틱 서비스 설정
    _hapticService.setEnabled(_hapticEnabled);
    
    print('Settings applied to services');
  }

  /// 백그라운드에서 설정 저장 (사용자에게 알리지 않음)
  void _saveSettingsInBackground() {
    // 비동기로 실행하되 UI를 블록하지 않음
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
        print('Settings auto-saved in background');
      } catch (error) {
        print('Background save error: $error');
      }
    });
  }

  void _speakPageGuide() {
    _hapticService.vibrateCustomSequence('notification');
    const guide = '''
    설정 화면입니다.
    이 화면에서는 접근성 설정, 음성 설정, 앱 설정을 변경할 수 있습니다.
    
    접근성 설정에서는 TTS 음성 안내, 햅틱 피드백, 페이지 진입 시 음성 안내를 켜고 끌 수 있습니다.
    
    음성 설정에서는 음성 속도와 볼륨을 조절하고, TTS 큐 모드를 설정할 수 있습니다.
    TTS 큐 모드를 켜면 여러 음성 안내가 순서대로 재생되고, 끄면 새로운 음성이 이전 음성을 중단합니다.
    
    앱 설정에서는 자동 로그인을 설정할 수 있습니다.
    
    왼쪽 위에는 이전 버튼이, 오른쪽 위에는 홈 버튼이 있습니다.
    왼쪽 아래에는 설정 초기화 버튼이, 오른쪽 아래에는 설정 저장 버튼이 있습니다.
    
    각 설정 항목을 터치하면 상세한 설명을 들을 수 있습니다.
    ''';
    _ttsService.speak(guide);
  }

  void _handleBack(BuildContext context) {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('이전');
    Navigator.of(context).pop();
  }

  void _handleHome(BuildContext context) {
    _hapticService.vibrateCustomSequence('tick');
    _ttsService.speak('메인');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _resetSettings() async {
    _hapticService.vibrateCustomSequence('warning');
    _ttsService.speak('설정을 초기화합니다.');
    
    try {
      // SharedPreferences에서 설정 삭제
      final success = await SettingsStorageService.resetSettings();
      
      if (success) {
        setState(() {
          _ttsEnabled = true;
          _hapticEnabled = true;
          _speechRate = 0.5;
          _volume = 1.0;
          _voiceGuidanceOnPageEnter = true;
          _autoLogin = false;
          _ttsQueueMode = false; // 기본값 false
          _ttsMaxQueueSize = 5;
        });
        
        // 서비스에 초기화된 설정 적용
        await _applySettingsToServices();
        
        _hapticService.vibrateCustomSequence('success');
        _ttsService.speak('설정이 기본값으로 초기화되었습니다. TTS 큐 모드는 비활성화되었습니다.');
        print('Settings reset to defaults: TTS Queue Mode = $_ttsQueueMode');
      } else {
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak('설정 초기화에 실패했습니다.');
      }
    } catch (error) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('설정 초기화 중 오류가 발생했습니다.');
      print('Error resetting settings: $error');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            '설정 저장 완료',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '설정이 성공적으로 저장되었습니다.',
            style: TextStyle(color: Colors.white70),
          ),
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
          upperLeftWidget: _buildButtonContent(Icons.arrow_back, '이전'),
          upperRightWidget: _buildButtonContent(Icons.home, '메인'),
          lowerLeftWidget: _buildButtonContent(Icons.refresh, '초기화'),
          lowerRightWidget: _buildButtonContent(Icons.check, '저장'),
          mainWidget: _buildSettingsContent(),
          onUpperLeftPress: () => _handleBack(context),
          onUpperRightPress: () => _handleHome(context),
          onLowerLeftPress: _resetSettings,
          onLowerRightPress: _saveSettings,
          // React Native와 동일한 더블탭 TTS 메시지 (React Native에서는 Settings 페이지에 useTTSOnFocus가 없어서 간단하게)
          upperLeftTTS: '이전',
          upperRightTTS: '홈',
          lowerLeftTTS: '초기화',
          lowerRightTTS: '저장',
        ),
      ),
    );
  }

  Widget _buildButtonContent(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    final user = IntegratedDummyDataService.getCurrentUser();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // 사용자 정보
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  '${user.username} 님의 설정',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // 접근성 설정
          _buildSettingsSection(
            '접근성 설정',
            [
              _buildSwitchTile(
                'TTS 음성 안내',
                'Text-to-Speech 기능을 사용합니다',
                _ttsEnabled,
                (value) {
                  setState(() => _ttsEnabled = value);
                  _hapticService.vibrateCustomSequence('tick');
                  _ttsService.speak(value ? 'TTS 음성 안내가 활성화되었습니다' : 'TTS 음성 안내가 비활성화되었습니다');
                },
              ),
              _buildSwitchTile(
                '햅틱 피드백',
                '진동을 통한 피드백을 제공합니다',
                _hapticEnabled,
                (value) {
                  setState(() => _hapticEnabled = value);
                  if (value) {
                    _hapticService.vibrateCustomSequence('success');
                  }
                  _ttsService.speak(value ? '햅틱 피드백이 활성화되었습니다' : '햅틱 피드백이 비활성화되었습니다');
                },
              ),
              _buildSwitchTile(
                '페이지 진입 시 음성 안내',
                '새 페이지 진입 시 자동으로 안내를 들려줍니다',
                _voiceGuidanceOnPageEnter,
                (value) {
                  setState(() => _voiceGuidanceOnPageEnter = value);
                  _hapticService.vibrateCustomSequence('tick');
                  _ttsService.speak(value ? '페이지 진입 시 음성 안내가 활성화되었습니다' : '페이지 진입 시 음성 안내가 비활성화되었습니다');
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 음성 설정
          _buildSettingsSection(
            '음성 설정',
            [
              _buildSliderTile(
                '음성 속도',
                '음성 안내 속도를 조절합니다',
                _speechRate,
                0.1,
                1.0,
                (value) {
                  setState(() => _speechRate = value);
                  _ttsService.setSpeechRate(value);
                },
                onChangeEnd: (value) {
                  _ttsService.speak('음성 속도가 변경되었습니다');
                },
              ),
              _buildSliderTile(
                '음성 볼륨',
                '음성 안내 볼륨을 조절합니다',
                _volume,
                0.1,
                1.0,
                (value) {
                  setState(() => _volume = value);
                  _ttsService.setVolume(value);
                },
                onChangeEnd: (value) {
                  _ttsService.speak('음성 볼륨이 변경되었습니다');
                },
              ),
              _buildSwitchTile(
                'TTS 큐 모드',
                '연속적인 음성 안내를 위해 큐에 순서대로 저장합니다',
                _ttsQueueMode,
                (value) {
                  setState(() => _ttsQueueMode = value);
                  _globalTts.setQueueMode(value);
                  _hapticService.vibrateCustomSequence('tick');
                  
                  if (value) {
                    _ttsService.speak('TTS 큐 모드가 활성화되었습니다. 음성 안내가 순서대로 재생됩니다.');
                  } else {
                    _ttsService.speak('TTS 즉시 재생 모드가 활성화되었습니다. 새로운 음성이 기존 음성을 중단합니다.');
                  }
                },
              ),
              if (_ttsQueueMode)
                _buildSimpleIntSlider(
                  '최대 큐 크기',
                  '한 번에 저장할 수 있는 최대 음성 안내 수',
                  _ttsMaxQueueSize,
                  1,
                  15, // 더 안전한 최대값
                  (value) {
                    setState(() => _ttsMaxQueueSize = value);
                    _globalTts.setMaxQueueSize(value);
                    _ttsService.speak('최대 큐 크기가 $value개로 설정되었습니다');
                  },
                ),
            ],
          ),

          const SizedBox(height: 20),

          // 앱 설정
          _buildSettingsSection(
            '앱 설정',
            [
              _buildSwitchTile(
                '자동 로그인',
                '앱 실행 시 자동으로 로그인합니다',
                _autoLogin,
                (value) {
                  setState(() => _autoLogin = value);
                  _hapticService.vibrateCustomSequence('tick');
                  _ttsService.speak(value ? '자동 로그인이 활성화되었습니다' : '자동 로그인이 비활성화되었습니다');
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        // 터치 시 항목 설명 음성 안내
        _hapticService.vibrateCustomSequence('tick');
        _ttsService.speak('$title. $subtitle. 현재 ${value ? "활성화" : "비활성화"} 상태입니다. 터치하여 변경할 수 있습니다.');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF1E3A8A) : const Color(0xFF4B5563),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재 상태: ${value ? "활성화됨" : "비활성화됨"}',
                    style: TextStyle(
                      color: value ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: value,
              onChanged: (newValue) {
                onChanged(newValue);
                // 즉시 피드백
                _hapticService.vibrateCustomSequence(newValue ? 'success' : 'warning');
                _ttsService.speak('$title이 ${newValue ? "활성화" : "비활성화"}되었습니다.');
                
                // 실시간 저장
                _saveSettingsInBackground();
              },
              activeColor: Colors.greenAccent,
              activeTrackColor: Colors.green.withValues(alpha: 0.5),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    ValueChanged<double>? onChangeEnd,
  }) {
    return GestureDetector(
      onTap: () {
        // 터치 시 항목 설명 음성 안내
        _hapticService.vibrateCustomSequence('tick');
        final percentage = ((value - min) / (max - min) * 100).round();
        _ttsService.speak('$title. $subtitle. 현재 $percentage퍼센트로 설정되어 있습니다. 슬라이더를 움직여 조절할 수 있습니다.');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF4B5563),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  '${(min * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: (newValue) {
                        onChanged(newValue);
                        // 슬라이더 움직일 때마다 햅틱 피드백
                        _hapticService.vibrateCustomSequence('tick');
                      },
                      onChangeEnd: (newValue) {
                        if (onChangeEnd != null) {
                          onChangeEnd(newValue);
                        }
                        // 최종 값 음성 안내
                        final percentage = ((newValue - min) / (max - min) * 100).round();
                        _ttsService.speak('$title이 $percentage퍼센트로 설정되었습니다.');
                        
                        // 실시간 저장
                        _saveSettingsInBackground();
                      },
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  '${(max * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '현재 값: ${((value - min) / (max - min) * 100).round()}%',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleIntSlider(
    String title,
    String subtitle,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        // 터치 시 항목 설명 음성 안내
        _hapticService.vibrateCustomSequence('tick');
        _ttsService.speak('$title. $subtitle. 현재 $value개로 설정되어 있습니다. 슬라이더를 움직여 1개부터 $max개까지 조절할 수 있습니다.');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  '$min개',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                    ),
                    child: Slider(
                      value: value.toDouble(),
                      min: min.toDouble(),
                      max: max.toDouble(),
                      divisions: max - min,
                      onChanged: (double val) {
                        final newValue = val.round();
                        onChanged(newValue);
                        _hapticService.vibrateCustomSequence('tick');
                        _ttsService.speak('최대 큐 크기가 $newValue개로 설정되었습니다');
                        
                        // 실시간 저장
                        _saveSettingsInBackground();
                      },
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  '$max개',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '현재 값: $value개',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    _hapticService.vibrateCustomSequence('notification');
    _ttsService.speak('설정을 저장하고 있습니다.');
    
    // 먼저 서비스에 실시간 적용
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
        _ttsService.speak('설정이 영구적으로 저장되었습니다.');
        _showSuccessDialog();
        print('Settings permanently saved: TTS Queue Mode = $_ttsQueueMode');
      } else {
        _hapticService.vibrateCustomSequence('error');
        _ttsService.speak('설정 저장에 실패했습니다.');
      }
    } catch (error) {
      _hapticService.vibrateCustomSequence('error');
      _ttsService.speak('설정 저장 중 오류가 발생했습니다.');
      print('Error saving settings: $error');
    }
  }
} 