import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/ocr_result.dart';

/// OCR 결과 박스를 이미지 위에 덧그려주는 위젯
class OcrOverlayWidget extends StatelessWidget {
  final Widget child; // 원본 이미지 위젯
  final OcrResult? ocrResult;
  final bool showBoxes;
  final bool showConfidence;
  final double confidenceThreshold;

  const OcrOverlayWidget({
    super.key,
    required this.child,
    this.ocrResult,
    this.showBoxes = true,
    this.showConfidence = true,
    this.confidenceThreshold = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showBoxes && ocrResult != null)
          Positioned.fill(
            child: CustomPaint(
              painter: OcrBoxPainter(
                ocrResult: ocrResult!,
                showConfidence: showConfidence,
                confidenceThreshold: confidenceThreshold,
              ),
            ),
          ),
      ],
    );
  }
}

/// OCR 박스를 그리는 커스텀 페인터
class OcrBoxPainter extends CustomPainter {
  final OcrResult ocrResult;
  final bool showConfidence;
  final double confidenceThreshold;

  OcrBoxPainter({
    required this.ocrResult,
    required this.showConfidence,
    required this.confidenceThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ocrResult.blocks == null) return;

    for (final block in ocrResult.blocks!) {
      // 블록 박스 그리기 (파란색)
      if (block.boundingBox != null) {
        _drawBox(
          canvas,
          size,
          block.boundingBox!,
          Colors.blue,
          2.0,
          'BLOCK',
          null,
        );
      }

      // 라인 박스 그리기 (초록색/빨간색)
      if (block.lines != null) {
        for (final line in block.lines!) {
          if (line.boundingBox != null) {
            final isLowConfidence = line.confidence != null && 
                                  line.confidence! < confidenceThreshold;
            
            _drawBox(
              canvas,
              size,
              line.boundingBox!,
              isLowConfidence ? Colors.red : Colors.green,
              1.5,
              'LINE',
              line.confidence,
            );
          }

          // 엘리먼트 박스 그리기 (상세)
          if (line.elements != null) {
            for (final element in line.elements!) {
              if (element.boundingBox != null) {
                final isLowConfidence = element.confidence != null && 
                                      element.confidence! < confidenceThreshold;
                
                _drawBox(
                  canvas,
                  size,
                  element.boundingBox!,
                  isLowConfidence ? Colors.orange : Colors.yellow,
                  1.0,
                  'ELEM',
                  element.confidence,
                );
              }
            }
          }
        }
      }
    }
  }

  void _drawBox(
    Canvas canvas,
    Size size,
    Rect boundingBox,
    Color color,
    double strokeWidth,
    String label,
    double? confidence,
  ) {
    // 박스 그리기
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRect(boundingBox, paint);

    // 신뢰도 표시 (옵션)
    if (showConfidence && confidence != null) {
      final textStyle = TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      );

      final confidenceText = '${(confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: confidenceText,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 박스 위에 신뢰도 표시
      final textOffset = Offset(
        boundingBox.left,
        boundingBox.top - textPainter.height - 2,
      );
      
      // 배경 그리기
      final bgRect = Rect.fromLTWH(
        textOffset.dx - 2,
        textOffset.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = Colors.black54);
      
      // 텍스트 그리기
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

/// 신뢰도별 색상 헬퍼
class OcrConfidenceColors {
  static Color getConfidenceColor(double? confidence, {double threshold = 0.5}) {
    if (confidence == null) return Colors.grey;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= threshold) return Colors.yellow;
    return Colors.red;
  }

  static Color getConfidenceLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 