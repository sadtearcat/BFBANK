import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/tts_service.dart';
import '../../data/services/haptic_service.dart';

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({Key? key}) : super(key: key);

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  final TtsService _ttsService = TtsService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _ttsService.initialize();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          '🛠️ Developer Options',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _hapticService.vibrateCustomSequence('tick');
            Navigator.of(context).pop();
          },
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildOptionCard(
              title: 'Handwriting\nBenchmark',
              subtitle: 'Performance Testing',
              icon: Icons.speed,
              color: Colors.orange,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _ttsService.speak('손글씨 인식 벤치마크 테스트를 시작합니다.');
                Navigator.pushNamed(context, '/benchmark-test');
              },
            ),
            _buildOptionCard(
              title: 'Handwriting\nTest',
              subtitle: 'Real Model Testing',
              icon: Icons.edit,
              color: Colors.indigo,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _ttsService.speak('실제 손글씨 인식 모델 테스트를 시작합니다.');
                Navigator.pushNamed(context, '/handwriting-test');
              },
            ),            _buildOptionCard(
              title: 'TTS Test',
              subtitle: 'Voice Testing',
              icon: Icons.record_voice_over,
              color: Colors.blue,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _showTtsTestDialog();
              },
            ),
            _buildOptionCard(
              title: 'Haptic Test',
              subtitle: 'Vibration Testing',
              icon: Icons.vibration,
              color: Colors.purple,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _showHapticTestDialog();
              },
            ),
            _buildOptionCard(
              title: 'ML Model Info',
              subtitle: 'Model Details',
              icon: Icons.psychology,
              color: Colors.green,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _showModelInfoDialog();
              },
            ),
            _buildOptionCard(
              title: 'Debug Logs',
              subtitle: 'Console Output',
              icon: Icons.bug_report,
              color: Colors.red,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _showDebugLogsDialog();
              },
            ),
            _buildOptionCard(
              title: 'Device Info',
              subtitle: 'System Information',
              icon: Icons.info,
              color: Colors.teal,
              onTap: () {
                _hapticService.vibrateCustomSequence('tick');
                _showDeviceInfoDialog();
              },
            ),
          ],
        ),
      ),
    );
  }  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[800],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTtsTestDialog() {
    final TextEditingController controller = TextEditingController(
      text: '안녕하세요. TTS 테스트입니다.',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'TTS Test',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter text to speak...',
                hintStyle: TextStyle(color: Colors.grey[400]),                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _ttsService.speak(controller.text);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Speak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _ttsService.stop();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showHapticTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Haptic Test',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test different vibration patterns:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHapticButton('Success', 'success', Colors.green),
                _buildHapticButton('Error', 'error', Colors.red),
                _buildHapticButton('Warning', 'warning', Colors.orange),
                _buildHapticButton('Tick', 'tick', Colors.blue),                _buildHapticButton('Double Tick', 'double_tick', Colors.purple),
                _buildHapticButton('Notification', 'notification', Colors.teal),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildHapticButton(String label, String pattern, Color color) {
    return ElevatedButton(
      onPressed: () {
        _hapticService.vibrateCustomSequence(pattern);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _showModelInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],        title: const Text(
          'ML Model Information',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Handwriting Recognition Model:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Model: my_emnist_model2.tflite\n'
                '• Input Shape: [1, 28, 28, 1]\n'
                '• Output Shape: [1, 12]\n'
                '• Classes: 0-9, delete, complete\n'
                '• Framework: TensorFlow Lite\n'
                '• Dataset: EMNIST (Extended MNIST)',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }  void _showDebugLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Debug Information',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debug Mode: ${kDebugMode ? "ON" : "OFF"}',
                style: TextStyle(
                  color: kDebugMode ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Actions:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Developer options accessed\n'
                '• Services initialized\n'
                '• UI components loaded\n'
                '• Ready for testing',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showDeviceInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Device Information',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Platform: ${Theme.of(context).platform.name}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Screen Size: ${MediaQuery.of(context).size.width.toInt()} x ${MediaQuery.of(context).size.height.toInt()}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),              Text(
                'Pixel Ratio: ${MediaQuery.of(context).devicePixelRatio}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Debug Mode: ${kDebugMode ? "Enabled" : "Disabled"}',
                style: TextStyle(
                  color: kDebugMode ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}