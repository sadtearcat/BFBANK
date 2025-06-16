import 'dart:ui';

/// OCR 처리 결과를 담는 모델
class OcrResult {
  final String text;
  final double confidence;
  final DateTime timestamp;
  final String? language;
  final List<OcrBlock>? blocks;

  const OcrResult({
    required this.text,
    required this.confidence,
    required this.timestamp,
    this.language,
    this.blocks,
  });

  /// 신뢰도가 높은지 확인
  bool get isHighConfidence => confidence >= 0.7;

  /// 디스플레이용 신뢰도 텍스트
  String get displayConfidence => '${(confidence * 100).toStringAsFixed(1)}%';

  /// 텍스트가 비어있는지 확인
  bool get isEmpty => text.trim().isEmpty;

  /// 텍스트가 있는지 확인
  bool get isNotEmpty => !isEmpty;

  /// 박스별 신뢰도 통계
  Map<String, double> get confidenceStats {
    if (blocks == null || blocks!.isEmpty) {
      return {'overall': confidence};
    }

    final List<double> lineConfidences = [];
    final List<double> elementConfidences = [];
    
    for (final block in blocks!) {
      if (block.lines != null) {
        for (final line in block.lines!) {
          if (line.confidence != null) {
            lineConfidences.add(line.confidence!);
          }
          if (line.elements != null) {
            for (final element in line.elements!) {
              if (element.confidence != null) {
                elementConfidences.add(element.confidence!);
              }
            }
          }
        }
      }
    }

    return {
      'overall': confidence,
      'avgLine': lineConfidences.isEmpty ? 0.0 : lineConfidences.reduce((a, b) => a + b) / lineConfidences.length,
      'avgElement': elementConfidences.isEmpty ? 0.0 : elementConfidences.reduce((a, b) => a + b) / elementConfidences.length,
      'minLine': lineConfidences.isEmpty ? 0.0 : lineConfidences.reduce((a, b) => a < b ? a : b),
      'maxLine': lineConfidences.isEmpty ? 0.0 : lineConfidences.reduce((a, b) => a > b ? a : b),
      'minElement': elementConfidences.isEmpty ? 0.0 : elementConfidences.reduce((a, b) => a < b ? a : b),
      'maxElement': elementConfidences.isEmpty ? 0.0 : elementConfidences.reduce((a, b) => a > b ? a : b),
    };
  }

  /// 낮은 신뢰도의 박스들 찾기
  List<String> getLowConfidenceTexts({double threshold = 0.5}) {
    final lowConfidenceTexts = <String>[];
    
    if (blocks == null) return lowConfidenceTexts;
    
    for (final block in blocks!) {
      if (block.lines != null) {
        for (final line in block.lines!) {
          if (line.confidence != null && line.confidence! < threshold) {
            lowConfidenceTexts.add('LINE: "${line.text}" (${(line.confidence! * 100).toStringAsFixed(1)}%)');
          }
          if (line.elements != null) {
            for (final element in line.elements!) {
              if (element.confidence != null && element.confidence! < threshold) {
                lowConfidenceTexts.add('ELEMENT: "${element.text}" (${(element.confidence! * 100).toStringAsFixed(1)}%)');
              }
            }
          }
        }
      }
    }
    
    return lowConfidenceTexts;
  }

  @override
  String toString() => 'OcrResult(text: "$text", confidence: $displayConfidence)';
}

/// OCR 텍스트 블록 정보 (위치 정보 포함)
class OcrBlock {
  final String text;
  final double? confidence;
  final List<String>? languages;
  final List<OcrLine>? lines;
  final Rect? boundingBox;
  final List<Offset>? cornerPoints;

  const OcrBlock({
    required this.text,
    this.confidence,
    this.languages,
    this.lines,
    this.boundingBox,
    this.cornerPoints,
  });

  /// 디스플레이용 신뢰도
  String get displayConfidence => confidence != null ? '${(confidence! * 100).toStringAsFixed(1)}%' : 'N/A';

  @override
  String toString() => 'OcrBlock(text: "$text", confidence: $displayConfidence, box: $boundingBox)';
}

/// OCR 텍스트 라인 정보 (위치 및 신뢰도 포함)
class OcrLine {
  final String text;
  final double? confidence;
  final List<OcrElement>? elements;
  final Rect? boundingBox;
  final List<Offset>? cornerPoints;
  final double? angle;

  const OcrLine({
    required this.text,
    this.confidence,
    this.elements,
    this.boundingBox,
    this.cornerPoints,
    this.angle,
  });

  /// 신뢰도가 높은지 확인
  bool get isHighConfidence => confidence != null && confidence! >= 0.7;

  /// 디스플레이용 신뢰도
  String get displayConfidence => confidence != null ? '${(confidence! * 100).toStringAsFixed(1)}%' : 'N/A';

  @override
  String toString() => 'OcrLine(text: "$text", confidence: $displayConfidence)';
}

/// OCR 텍스트 요소 정보 (가장 세밀한 박스별 신뢰도)
class OcrElement {
  final String text;
  final double? confidence;
  final Rect? boundingBox;
  final List<Offset>? cornerPoints;
  final double? angle;

  const OcrElement({
    required this.text,
    this.confidence,
    this.boundingBox,
    this.cornerPoints,
    this.angle,
  });

  /// 신뢰도가 높은지 확인
  bool get isHighConfidence => confidence != null && confidence! >= 0.7;

  /// 디스플레이용 신뢰도
  String get displayConfidence => confidence != null ? '${(confidence! * 100).toStringAsFixed(1)}%' : 'N/A';

  /// 신뢰도 레벨 (Low/Medium/High)
  String get confidenceLevel {
    if (confidence == null) return 'Unknown';
    if (confidence! >= 0.8) return 'High';
    if (confidence! >= 0.5) return 'Medium';
    return 'Low';
  }

  @override
  String toString() => 'OcrElement(text: "$text", confidence: $displayConfidence, level: $confidenceLevel)';
} 