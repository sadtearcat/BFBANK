// 📄 [DEVELOPER TOOL] 전처리 성능 벤치마크 페이지 - 성능 측정 및 최적화 도구
// 역할: 다양한 전처리 옵션의 성능을 비교하고 최적화 방향을 제시
// 기능: 고급 전처리 ON/OFF, 앙상블 처리, 벤치마크 모드, 디버그 로그
// 사용: 전처리 파이프라인 성능 튜닝 및 최적화 작업 시 사용

import 'package:flutter/material.dart';
import 'drawing_canvas.dart';
import '../models/handwriting_prediction.dart';

/// 전처리 성능 벤치마크 테스트 페이지
class BenchmarkTestPage extends StatefulWidget {
  const BenchmarkTestPage({super.key});

  @override
  State<BenchmarkTestPage> createState() => _BenchmarkTestPageState();
}

class _BenchmarkTestPageState extends State<BenchmarkTestPage> {
  String _currentInput = '';
  bool _showOverlay = false;
  bool _enableAdvancedProcessing = false;  // ✅ 기본값 변경 (좌표 변환 문제 해결)
  bool _enableTemperatureEnsemble = false;
  bool _enableBenchmark = false;
  bool _enableDebugLogs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('전처리 성능 벤치마크 테스트'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Main content
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current input display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Text(
                    '입력: $_currentInput',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Configuration options
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '전처리 설정',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 고급 전처리 토글
                        SwitchListTile(
                          title: const Text('고급 전처리', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('1. 무게중심 정렬 2. 기울기 보정(PCA) 3. 동적 선 굵기 4. 향상된 정규화', style: TextStyle(color: Colors.grey)),
                          value: _enableAdvancedProcessing,
                          onChanged: (value) {
                            setState(() {
                              _enableAdvancedProcessing = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        
                        // 앙상블 처리 토글
                        SwitchListTile(
                          title: const Text('앙상블 처리', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('다중 이미지 변형으로 강건성 향상', style: TextStyle(color: Colors.grey)),
                          value: _enableTemperatureEnsemble,
                          onChanged: (value) {
                            setState(() {
                              _enableTemperatureEnsemble = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                        
                        // 벤치마크 모드 토글
                        SwitchListTile(
                          title: const Text('벤치마크 모드', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('기본 vs 고급 전처리 성능 비교', style: TextStyle(color: Colors.grey)),
                          value: _enableBenchmark,
                          onChanged: (value) {
                            setState(() {
                              _enableBenchmark = value;
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                        
                        // 디버그 로그 토글
                        SwitchListTile(
                          title: const Text('디버그 로그', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('상세한 전처리 정보 출력', style: TextStyle(color: Colors.grey)),
                          value: _enableDebugLogs,
                          onChanged: (value) {
                            setState(() {
                              _enableDebugLogs = value;
                            });
                          },
                          activeColor: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[700]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '사용 방법:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. 위의 전처리 옵션을 설정하세요\n'
                        '2. "손글씨 입력 시작" 버튼을 눌러 시작하세요\n'
                        '3. 화면에 숫자를 그려보세요\n'
                        '4. 콘솔 로그에서 성능 지표를 확인하세요\n'
                        '5. 다양한 설정을 비교해보세요',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Control buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showOverlay = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '손글씨 입력 시작',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentInput = '';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '입력 지우기',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Drawing canvas overlay
          if (_showOverlay)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: IconButton(
                        onPressed: () {
                setState(() {
                  _showOverlay = false;
                });
              },
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  
                  // Drawing canvas
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DrawingCanvas(
                        onPrediction: (prediction) {
                          if (prediction.digit == 'delete') {
                            setState(() {
                              if (_currentInput.isNotEmpty) {
                                _currentInput = _currentInput.substring(0, _currentInput.length - 1);
                              }
                            });
                          } else if (prediction.digit == 'complete') {
                setState(() {
                  _showOverlay = false;
                });
                          } else if (prediction.shouldAccept && RegExp(r'^[0-9]$').hasMatch(prediction.digit)) {
                            setState(() {
                              _currentInput += prediction.digit;
                            });
                          }
                        },
                        autoProcessDelay: const Duration(seconds: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 