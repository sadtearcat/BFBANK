// 📄 [UI WIDGET] 손글씨 입력 오버레이 캔버스 - 기존 UI 위에 투명 캔버스 오버레이
// 역할: 기존 페이지 UI를 그대로 보여주면서 그 위에 전체 화면 투명 캔버스 제공
// 기능: 투명 배경 손글씨 입력, 실시간 인식, 입력 완료 시 오버레이 종료
// 사용: send_main_page.dart에서 기존 모달 대신 오버레이 방식으로 사용

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'drawing_canvas.dart';
import '../models/handwriting_prediction.dart';

/// 기존 UI 위에 투명한 손글씨 입력 오버레이를 제공하는 위젯
/// 
/// **핵심 기능:**
/// - 전체 화면 투명 배경
/// - 기존 UI는 그대로 보임
/// - 손글씨 입력 시에만 시각적 피드백
/// - 입력 완료 또는 체크 제스처 시 자동 종료
class HandwritingOverlayCanvas extends StatefulWidget {
  /// 숫자 인식 완료 시 호출되는 콜백
  final Function(String) onDigitRecognized;
  
  /// 오버레이 종료 시 호출되는 콜백
  final VoidCallback? onClose;
  
  /// 오버레이 표시 여부
  final bool isVisible;

  const HandwritingOverlayCanvas({
    super.key,
    required this.onDigitRecognized,
    this.onClose,
    this.isVisible = true,
  });

  @override
  State<HandwritingOverlayCanvas> createState() => _HandwritingOverlayCanvasState();
}

class _HandwritingOverlayCanvasState extends State<HandwritingOverlayCanvas> {
  
  String _currentInput = '';
  String _lastPrediction = '';
  bool _isDrawing = false;
  
  // 🔧 ADD: DrawingCanvas 제어를 위한 GlobalKey
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey<DrawingCanvasState>();
  
  @override
  void initState() {
    super.initState();
    // 🔧 애니메이션 제거 - 즉각적 표시
  }
  
  @override
  void dispose() {
    // 🔧 애니메이션 컨트롤러 제거
    super.dispose();
  }

  /// 손글씨 인식 결과 처리
  void _handlePrediction(HandwritingPrediction prediction) {
    if (prediction.errorMessage != null) {
      // print('❌ Overlay prediction error: ${prediction.errorMessage}'); // 🔧 디버깅 메시지 주석 처리
      return;
    }

    setState(() {
      _lastPrediction = prediction.digit;
    });

    // 🔧 애니메이션 제거 - 즉각적 피드백

    // 제스처 및 숫자 처리
    if (prediction.digit == 'delete' || prediction.digit == '✗') {
      _deleteLastDigit();
    } else if (prediction.digit == 'complete' || prediction.digit == '✓') {
      _complete();
    } else if (prediction.shouldAccept && RegExp(r'^[0-9]$').hasMatch(prediction.digit)) {
      _addDigit(prediction.digit);
    }
  }

  /// 숫자 추가
  void _addDigit(String digit) {
    setState(() {
      _currentInput += digit;
    });
    
    // 햅틱 피드백
    HapticFeedback.lightImpact();
    
    // 🔧 ADD: 숫자 인식 후 캔버스 클리어 (다음 입력을 위해)
    _clearCanvas();
    
    // 개별 숫자 인식 시 콜백 호출
    widget.onDigitRecognized(digit);
  }

  /// 🔧 ADD: 캔버스 클리어 헬퍼 메서드
  void _clearCanvas() {
    _canvasKey.currentState?.clearCanvas();
  }

  /// 마지막 숫자 삭제
  void _deleteLastDigit() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
      HapticFeedback.mediumImpact();
      
      // 🔧 ADD: 삭제 제스처 후 캔버스 클리어
      _clearCanvas();
      
      // 삭제 제스처 콜백 호출
      widget.onDigitRecognized('delete');
    }
  }

  /// 입력 완료
  void _complete() {
    HapticFeedback.heavyImpact();
    
    // 🔧 ADD: 완료 제스처 후 캔버스 클리어
    _clearCanvas();
    
    // 완료 제스처 콜백 호출
    widget.onDigitRecognized('complete');
    
    // 오버레이 종료
    _closeOverlay();
  }

  /// 오버레이 종료
  void _closeOverlay() {
    // 🔧 애니메이션 제거 - 즉각적 종료
    widget.onClose?.call();
  }

  /// 그리기 시작 감지
  void _onDrawingStart() {
    setState(() {
      _isDrawing = true;
    });
  }

  /// 그리기 종료 감지
  void _onDrawingEnd() {
    setState(() {
      _isDrawing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    // 🔧 FadeTransition 제거 - 즉각적 표시
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
                         // 🎯 전체 화면 투명 캔버스
             Positioned.fill(
               child: DrawingCanvas(
                 key: _canvasKey,  // 🔧 ADD: 캔버스 제어를 위한 key
                 onPrediction: _handlePrediction,
                 onDrawingStart: _onDrawingStart,  // 🔧 그리기 시작 감지
                 onDrawingEnd: _onDrawingEnd,      // 🔧 그리기 종료 감지
                 autoProcessDelay: const Duration(milliseconds: 800),
                 isVisible: true,
                 // 투명 배경으로 기존 UI가 보이도록 설정
               ),
             ),
            
            // 🔧 그리기 중 메시지 간소화 (필요시 주석 해제)
            // if (_isDrawing)
            //   Positioned.fill(
            //     child: Container(
            //       color: Colors.black.withOpacity(0.1),
            //       child: Center(
            //         child: Container(
            //           padding: const EdgeInsets.symmetric(
            //             horizontal: 20,
            //             vertical: 10,
            //           ),
            //           decoration: BoxDecoration(
            //             color: Colors.black.withOpacity(0.7),
            //             borderRadius: BorderRadius.circular(25),
            //           ),
            //           child: const Text(
            //             '손글씨 입력 중...',
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 16,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            
            // 📱 상태 표시 (우상단) - 🔧 ScaleTransition 제거
            if (_lastPrediction.isNotEmpty || _currentInput.isNotEmpty)
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_lastPrediction.isNotEmpty)
                        Text(
                          '인식: $_lastPrediction',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (_currentInput.isNotEmpty)
                        Text(
                          '입력: $_currentInput',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // 🔧 디버깅용 도움말 주석 처리
            // Positioned(
            //   bottom: 100,
            //   left: 20,
            //   child: Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.7),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: const Column(
            //       mainAxisSize: MainAxisSize.min,
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           '📝 손글씨 입력 모드',
            //           style: TextStyle(
            //             color: Colors.white,
            //             fontSize: 14,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         SizedBox(height: 4),
            //         Text(
            //           '• 숫자 0-9 그리기\n• ✗ 그려서 삭제\n• ✓ 그려서 완료',
            //           style: TextStyle(
            //             color: Colors.white70,
            //             fontSize: 12,
            //             height: 1.3,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      );
  }
} 