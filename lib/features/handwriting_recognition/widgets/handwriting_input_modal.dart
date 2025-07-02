// 📄 [UI WIDGET] 손글씨 입력 모달 - 전체화면 손글씨 입력 인터페이스
// 역할: 사용자에게 손글씨 입력 UI를 제공하고 인식 결과를 처리
// 기능: 실시간 인식 결과 표시, 제스처 처리, 입력 완료/취소 관리
// 사용: send_main_page.dart에서 계좌번호 입력 시 호출되는 메인 UI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'drawing_canvas.dart';
import '../models/handwriting_prediction.dart';

/// Modal dialog for handwriting input with real-time recognition
class HandwritingInputModal extends StatefulWidget {
  final Function(String) onDigitRecognized;

  const HandwritingInputModal({
    super.key,
    required this.onDigitRecognized,
  });

  @override
  State<HandwritingInputModal> createState() => _HandwritingInputModalState();
}

class _HandwritingInputModalState extends State<HandwritingInputModal> {
  String _currentInput = '';
  String _lastPrediction = '';

  void _handlePrediction(HandwritingPrediction prediction) {
    if (prediction.errorMessage != null) {
      print('❌ Prediction error: ${prediction.errorMessage}');
      return;
    }

    setState(() {
      _lastPrediction = prediction.digit;
    });

    // Handle different types of predictions
    if (prediction.digit == 'delete') {
      _deleteLastDigit();
    } else if (prediction.digit == 'complete') {
      _complete();
    } else if (prediction.shouldAccept) {
      // Only accept digit predictions with high confidence
      if (RegExp(r'^[0-9]$').hasMatch(prediction.digit)) {
        _addDigit(prediction.digit);
      }
    }
  }

  void _addDigit(String digit) {
    setState(() {
      _currentInput += digit;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _deleteLastDigit() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _complete() {
    if (_currentInput.isNotEmpty) {
      widget.onDigitRecognized(_currentInput);
      Navigator.of(context).pop();
    } else {
      // Show message if no input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력된 숫자가 없습니다')),
      );
    }
  }

  void _clear() {
    setState(() {
      _currentInput = '';
      _lastPrediction = '';
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFF1E3A8A),
        appBar: AppBar(
          title: const Text('손글씨 입력'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _complete,
            ),
          ],
        ),
        body: Column(
          children: [
            // Input display
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

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '• 숫자 0-9를 그려서 입력\n'
                '• "X" 그려서 마지막 숫자 지우기\n'
                '• "V" 그려서 입력 완료',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
                  onPrediction: _handlePrediction,
                  autoProcessDelay: const Duration(seconds: 1),
                ),
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.clear,
                    label: '전체 지우기',
                    onTap: _clear,
                    isEnabled: _currentInput.isNotEmpty,
                  ),
                  _buildControlButton(
                    icon: Icons.backspace,
                    label: '한 글자 지우기',
                    onTap: _deleteLastDigit,
                    isEnabled: _currentInput.isNotEmpty,
                  ),
                  _buildControlButton(
                    icon: Icons.check,
                    label: '완료',
                    onTap: _complete,
                    isEnabled: _currentInput.isNotEmpty,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 