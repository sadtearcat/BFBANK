// 📄 [DEVELOPER TOOL] 손글씨 인식 테스트 페이지 - 개발자용 실시간 테스트 도구
// 역할: 실제 사용자 입력 패턴으로 손글씨 인식 시스템을 테스트
// 기능: 실시간 onPrediction 콜백, 누적 입력, 통계 표시, 테스트 제어
// 사용: 개발 중 손글씨 인식 성능 및 정확도 검증용

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/handwriting_model_service.dart';
import '../models/handwriting_prediction.dart';
import 'drawing_canvas.dart';

/// 실제 사용 패턴과 동일한 손글씨 인식 테스트 페이지
/// 
/// 🔗 **실제 사용 패턴 반영:**
/// - handwriting_input_modal.dart와 동일한 DrawingCanvas + onPrediction 구조
/// - 실시간 자동 인식 (1초 지연)
/// - 제스처 지원 (X = 삭제, V = 완료)
/// - 누적 입력 (여러 숫자 연속 입력)
/// - 테스트용 추가 버튼들만 포함
/// 
/// 🚨 **이전 문제점 해결:**
/// - ❌ 이전: canvasState.getImageData() → modelService.recognizeHandwriting() (수동 호출)
/// - ✅ 현재: DrawingCanvas onPrediction 콜백 (실시간 자동 인식)
/// - 실제 사용자 경험과 100% 동일한 테스트 환경
class HandwritingTestPage extends StatefulWidget {
  const HandwritingTestPage({super.key});

  @override
  State<HandwritingTestPage> createState() => _HandwritingTestPageState();
}

class _HandwritingTestPageState extends State<HandwritingTestPage> {
  final HandwritingModelService _service = HandwritingModelService.instance;
  
  // 실제 사용 패턴과 동일한 상태 관리
  String _currentInput = '';
  String _lastPrediction = '';
  String _statusText = '모델 초기화 중...';
  bool _isModelLoaded = false;
  bool _isLoading = false;
  
  // 테스트 전용 상태
  int _totalPredictions = 0;
  int _successfulPredictions = 0;
  List<String> _predictionHistory = [];
  
  // DrawingCanvas 컨트롤러 (실제 사용 패턴)
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  /// 모델 초기화 (실제 사용 패턴과 동일)
  Future<void> _initializeModel() async {
    setState(() {
      _isLoading = true;
      _statusText = '손글씨 인식 모델 로드 중...';
    });

    try {
      final success = await _service.loadModel();
      setState(() {
        _isModelLoaded = success;
        _statusText = success 
          ? '✅ 모델 로드 완료 - 손글씨를 그려보세요!' 
          : '❌ 모델 로드 실패';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = '❌ 모델 초기화 오류: $e';
        _isLoading = false;
        _isModelLoaded = false;
      });
    }
  }

  /// 실제 사용 패턴과 동일한 예측 처리
  void _handlePrediction(HandwritingPrediction prediction) {
    if (!_isModelLoaded) return;

    // 테스트 통계 업데이트
    setState(() {
      _totalPredictions++;
      _lastPrediction = prediction.digit;
      
      // 예측 히스토리 추가 (최근 10개만 유지)
      _predictionHistory.insert(0, 
        '${prediction.digit} (${(prediction.confidence * 100).toStringAsFixed(1)}%)');
      if (_predictionHistory.length > 10) {
        _predictionHistory.removeLast();
      }
    });

    if (prediction.errorMessage != null) {
      print('❌ Prediction error: ${prediction.errorMessage}');
      setState(() {
        _statusText = '❌ 인식 오류: ${prediction.errorMessage}';
      });
      return;
    }

    // 실제 사용 패턴과 동일한 처리
    if (prediction.digit == 'delete') {
      _deleteLastDigit();
    } else if (prediction.digit == 'complete') {
      _complete();
    } else if (prediction.shouldAccept) {
      // 숫자만 입력으로 처리
      if (RegExp(r'^[0-9]$').hasMatch(prediction.digit)) {
        _addDigit(prediction.digit);
        setState(() {
          _successfulPredictions++;
          _statusText = '✅ "${prediction.digit}" 인식됨 (신뢰도: ${(prediction.confidence * 100).toStringAsFixed(1)}%)';
      });
      } else {
        setState(() {
          _statusText = '⚠️ 특수 기호 인식: ${prediction.digit}';
        });
      }
    } else {
      setState(() {
        _statusText = '⚠️ 낮은 신뢰도: "${prediction.digit}" (${(prediction.confidence * 100).toStringAsFixed(1)}%)';
      });
    }
  }

  /// 실제 사용 패턴과 동일한 숫자 추가
  void _addDigit(String digit) {
    setState(() {
      _currentInput += digit;
    });
    
    // 실제 사용 패턴과 동일한 햅틱 피드백
    HapticFeedback.lightImpact();
  }

  /// 실제 사용 패턴과 동일한 마지막 숫자 삭제
  void _deleteLastDigit() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        _statusText = '🗑️ 마지막 숫자 삭제됨';
    });
      HapticFeedback.mediumImpact();
    }
  }

  /// 실제 사용 패턴과 동일한 완료 처리
  void _complete() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _statusText = '✅ 입력 완료: $_currentInput';
      });
      HapticFeedback.lightImpact();
      
      // 테스트용: 완료된 입력을 히스토리에 추가
      _predictionHistory.insert(0, '✅ COMPLETED: $_currentInput');
    } else {
      setState(() {
        _statusText = '⚠️ 입력된 숫자가 없습니다';
      });
    }
  }

  /// 테스트 전용: 전체 지우기
  void _clearAll() {
    setState(() {
      _currentInput = '';
      _lastPrediction = '';
      _statusText = '🧹 전체 지워짐 - 새로 시작하세요';
    });
    _canvasKey.currentState?.clearCanvas();
    HapticFeedback.heavyImpact();
  }

  /// 테스트 전용: 캔버스만 지우기
  void _clearCanvas() {
    _canvasKey.currentState?.clearCanvas();
    setState(() {
      _statusText = '🎨 캔버스 지워짐';
    });
    HapticFeedback.mediumImpact();
  }

  /// 테스트 전용: 통계 리셋
  void _resetStats() {
      setState(() {
      _totalPredictions = 0;
      _successfulPredictions = 0;
      _predictionHistory.clear();
      _statusText = '📊 통계 리셋됨';
      });
  }

  /// 테스트 전용: 더미 숫자 5 테스트
  Future<void> _testDummyDigit() async {
    if (!_isModelLoaded) {
      setState(() {
        _statusText = '❌ 모델이 로드되지 않았습니다';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = '🧪 더미 숫자 5 테스트 중...';
    });

    try {
      final dummyData = _service.generateDummyDigit5();
      final prediction = await _service.recognizeHandwriting(dummyData);
      
      setState(() {
        _isLoading = false;
        if (prediction.isSuccess) {
          _statusText = '✅ 더미 테스트 성공: "${prediction.digit}" (신뢰도: ${(prediction.confidence * 100).toStringAsFixed(1)}%)';
        } else {
          _statusText = '❌ 더미 테스트 실패: ${prediction.errorMessage ?? "낮은 신뢰도"}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = '❌ 더미 테스트 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final successRate = _totalPredictions > 0 
        ? (_successfulPredictions / _totalPredictions * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // handwriting_input_modal과 동일한 배경색
      appBar: AppBar(
        title: const Text('손글씨 인식 테스트 (실제 사용 패턴)'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 테스트 전용 버튼들
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _isLoading ? null : _testDummyDigit,
            tooltip: '더미 테스트',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeModel,
            tooltip: '모델 재로드',
          ),
        ],
      ),
      body: Column(
        children: [
          // 입력 표시 영역 (실제 사용 패턴과 동일)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
        child: Column(
          children: [
                const Text(
                  '입력된 숫자',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentInput.isEmpty ? '(없음)' : _currentInput,
                  style: TextStyle(
                    color: _currentInput.isEmpty ? Colors.white38 : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (_lastPrediction.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '최근 인식: $_lastPrediction',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 상태 및 통계 표시 (테스트 전용)
            Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              ),
            child: Column(
              children: [
                Text(
                _statusText,
                style: const TextStyle(
                    color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
                const SizedBox(height: 8),
            Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                    Text(
                      '총 예측: $_totalPredictions',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '성공: $_successfulPredictions',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                    Text(
                      '성공률: $successRate%',
                      style: const TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 사용법 안내 (실제 사용 패턴과 동일)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '• 숫자 0-9를 그려서 입력\n'
              '• "X" 그려서 마지막 숫자 지우기\n'
              '• "V" 그려서 입력 완료\n'
              '• 1초 후 자동 인식됩니다',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
            ),
              textAlign: TextAlign.center,
            ),
          ),
            
          // 손글씨 캔버스 (실제 사용 패턴과 동일)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isModelLoaded
                  ? DrawingCanvas(
                key: _canvasKey,
                      onPrediction: _handlePrediction, // 실제 사용 패턴과 동일
                      autoProcessDelay: const Duration(seconds: 1), // 실제 사용 패턴과 동일
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
              ),
            ),
            
          // 테스트 전용 컨트롤 버튼들
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTestButton(
                  icon: Icons.clear_all,
                  label: '전체 지우기',
                  onTap: _clearAll,
                  color: Colors.red,
                ),
                _buildTestButton(
                  icon: Icons.brush,
                  label: '캔버스만',
                  onTap: _clearCanvas,
                  color: Colors.orange,
                    ),
                _buildTestButton(
                  icon: Icons.bar_chart,
                  label: '통계 리셋',
                  onTap: _resetStats,
                  color: Colors.purple,
                ),
                _buildTestButton(
                  icon: Icons.check,
                  label: '완료',
                  onTap: _complete,
                  color: Colors.green,
                ),
              ],
                            ),
          ),

          // 예측 히스토리 (테스트 전용)
          if (_predictionHistory.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    '최근 예측 히스토리:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                  const SizedBox(height: 4),
                  ...(_predictionHistory.take(5).map((history) => Text(
                        history,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ))),
                ],
              ),
            ),
          ],
      ),
    );
  }

  /// 테스트 전용 버튼 빌더
  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 