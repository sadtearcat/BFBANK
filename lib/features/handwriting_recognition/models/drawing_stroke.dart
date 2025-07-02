// 📄 [DRAWING MODEL] 손글씨 그리기 스트로크 데이터 모델
// 역할: 사용자가 그린 스트로크(선)의 점들과 속성을 저장
// 기능: 제스처 감지(X=삭제, V=완료), 경계 상자 계산, 스트로크 조작
// 사용: DrawingCanvas에서 그리기 데이터를 관리할 때 사용

import 'dart:ui';

/// Represents a single stroke in handwriting recognition
class DrawingStroke {
  final List<Offset> points;
  final Paint paint;
  final DateTime timestamp;

  DrawingStroke({
    required this.points,
    required this.paint,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a copy of this stroke with new points
  DrawingStroke copyWith({
    List<Offset>? points,
    Paint? paint,
    DateTime? timestamp,
  }) {
    return DrawingStroke(
      points: points ?? List.from(this.points),
      paint: paint ?? this.paint,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Adds a point to this stroke
  DrawingStroke addPoint(Offset point) {
    return copyWith(points: [...points, point]);
  }

  /// Gets the bounding box of this stroke
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = point.dx < minX ? point.dx : minX;
      maxX = point.dx > maxX ? point.dx : maxX;
      minY = point.dy < minY ? point.dy : minY;
      maxY = point.dy > maxY ? point.dy : maxY;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Checks if this stroke represents a specific gesture
  bool isGesture(String gestureType) {
    if (points.length < 3) return false;
    
    switch (gestureType) {
      case 'delete': // X gesture
        return _isXGesture();
      case 'complete': // V gesture
        return _isVGesture();
      default:
        return false;
    }
  }

  /// Detects X gesture for deletion
  bool _isXGesture() {
    if (points.length < 4) return false;
    
    final bounds = this.bounds;
    final width = bounds.width;
    final height = bounds.height;
    
    // Must be roughly square-ish
    if (width < 50 || height < 50 || (width / height) > 2 || (height / width) > 2) {
      return false;
    }
    
    // Check for diagonal crossing pattern
    final firstHalf = points.take(points.length ~/ 2).toList();
    final secondHalf = points.skip(points.length ~/ 2).toList();
    
    // First half should go from one corner to opposite
    // Second half should go from another corner to its opposite
    return _isDiagonalPattern(firstHalf, bounds) && _isDiagonalPattern(secondHalf, bounds);
  }

  /// Detects V gesture for completion
  bool _isVGesture() {
    if (points.length < 3) return false;
    
    final bounds = this.bounds;
    if (bounds.width < 30 || bounds.height < 30) return false;
    
    // Find the lowest point (should be in the middle)
    int lowestIndex = 0;
    for (int i = 1; i < points.length; i++) {
      if (points[i].dy > points[lowestIndex].dy) {
        lowestIndex = i;
      }
    }
    
    // Lowest point should be roughly in the middle
    if (lowestIndex < points.length * 0.2 || lowestIndex > points.length * 0.8) {
      return false;
    }
    
    // Check if we have downward then upward movement
    final leftPart = points.take(lowestIndex + 1).toList();
    final rightPart = points.skip(lowestIndex).toList();
    
    return _isDownwardTrend(leftPart) && _isUpwardTrend(rightPart);
  }

  bool _isDiagonalPattern(List<Offset> points, Rect bounds) {
    if (points.length < 2) return false;
    
    final start = points.first;
    final end = points.last;
    
    final deltaX = (end.dx - start.dx).abs();
    final deltaY = (end.dy - start.dy).abs();
    
    // Should be roughly diagonal
    return deltaX > bounds.width * 0.3 && deltaY > bounds.height * 0.3;
  }

  bool _isDownwardTrend(List<Offset> points) {
    if (points.length < 2) return false;
    return points.last.dy > points.first.dy;
  }

  bool _isUpwardTrend(List<Offset> points) {
    if (points.length < 2) return false;
    return points.last.dy < points.first.dy;
  }
} 