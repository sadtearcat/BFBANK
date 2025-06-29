// 📄 [CORE MODEL] 손글씨 인식 예측 결과 데이터 모델
// 역할: YOLO 모델의 분류 결과를 구조화하여 저장하고 검증
// 기능: 성공/실패 상태, 신뢰도 임계값 검사, 사용자 친화적 메시지 제공
// 사용: HandwritingModelService에서 인식 결과를 래핑할 때 사용

/// Represents a handwriting recognition prediction result
class HandwritingPrediction {
  final String digit;
  final double confidence;
  final bool isSuccess;
  final String? errorMessage;
  final double threshold;

  const HandwritingPrediction._({
    required this.digit,
    required this.confidence,
    required this.isSuccess,
    this.errorMessage,
    this.threshold = 0.7,
  });

  /// General constructor for HandwritingPrediction
  HandwritingPrediction({
    required int digit,
    required double confidence,
    required bool isRecognized,
    String? message,
    double threshold = 0.7,
  }) : digit = digit.toString(),
       confidence = confidence,
       isSuccess = isRecognized,
       errorMessage = message,
       threshold = threshold;

  /// Creates a successful prediction
  factory HandwritingPrediction.success({
    required String digit,
    required double confidence,
    double threshold = 0.7,
  }) {
    return HandwritingPrediction._(
      digit: digit,
      confidence: confidence,
      isSuccess: true,
      threshold: threshold,
    );
  }

  /// Creates a low confidence prediction
  factory HandwritingPrediction.lowConfidence(
    String digit,
    double confidence,
    double threshold,
  ) {
    return HandwritingPrediction._(
      digit: digit,
      confidence: confidence,
      isSuccess: false,
      threshold: threshold,
    );
  }

  /// Creates an error prediction
  factory HandwritingPrediction.error(String errorMessage) {
    return HandwritingPrediction._(
      digit: '',
      confidence: 0.0,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// Creates prediction from raw model output probabilities
  factory HandwritingPrediction.fromModelOutput(
    List<double> probabilities, {
    double threshold = 0.7,
  }) {
    if (probabilities.isEmpty) {
      return HandwritingPrediction.error('Empty prediction probabilities');
    }

    // Find the digit with highest probability
    double maxConfidence = 0.0;
    int predictedDigit = 0;
    
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        predictedDigit = i;
      }
    }

    if (maxConfidence >= threshold) {
      return HandwritingPrediction.success(
        digit: predictedDigit.toString(),
        confidence: maxConfidence,
        threshold: threshold,
      );
    } else {
      return HandwritingPrediction.lowConfidence(
        predictedDigit.toString(),
        maxConfidence,
        threshold,
      );
    }
  }

  /// Whether the prediction should be accepted
  bool get shouldAccept => isSuccess && confidence >= threshold;

  /// User-friendly message for this prediction
  String get userMessage {
    if (errorMessage != null) {
      return '오류: $errorMessage';
    }
    
    if (isSuccess) {
      return '인식됨: $digit (확신도: ${(confidence * 100).toStringAsFixed(1)}%)';
    } else {
      return '불확실한 인식: $digit (확신도: ${(confidence * 100).toStringAsFixed(1)}%, 임계값: ${(threshold * 100).toStringAsFixed(1)}%)';
    }
  }

  @override
  String toString() {
    return 'HandwritingPrediction(digit: $digit, confidence: $confidence, isSuccess: $isSuccess, error: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is HandwritingPrediction &&
        other.digit == digit &&
        other.confidence == confidence &&
        other.isSuccess == isSuccess &&
        other.errorMessage == errorMessage &&
        other.threshold == threshold;
  }

  @override
  int get hashCode {
    return Object.hash(
      digit,
      confidence,
      isSuccess,
      errorMessage,
      threshold,
    );
  }
} 