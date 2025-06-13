class DetectedItem {
  final String id;
  final String className;
  final double confidence;
  final String imagePath;
  final DateTime detectedAt;

  const DetectedItem({
    required this.id,
    required this.className,
    required this.confidence,
    required this.imagePath,
    required this.detectedAt,
  });

  // 높은 신뢰도인지 확인
  bool get isHighConfidence => confidence >= 0.8;

  // 설명 텍스트
  String get description => '$className (${(confidence * 100).toStringAsFixed(1)}%)';

  // JSON 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'className': className,
    'confidence': confidence,
    'imagePath': imagePath,
    'detectedAt': detectedAt.toIso8601String(),
  };

  factory DetectedItem.fromJson(Map<String, dynamic> json) => DetectedItem(
    id: json['id'] as String,
    className: json['className'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    imagePath: json['imagePath'] as String,
    detectedAt: DateTime.parse(json['detectedAt'] as String),
  );
} 