import 'package:flutter/material.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/global_tap_handler.dart';

/// 햅틱 피드백이 적용된 공통 버튼 위젯
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String hapticType;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool enabled;

  const HapticButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hapticType = 'tick', // 기본값: 'tick'
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && onPressed != null ? _handleTap : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }

  void _handleTap() {
    // 햅틱 피드백 실행 (비동기)
    HapticService.instance.vibrateCustomSequence(hapticType);
    
    // 원래 콜백 실행
    onPressed?.call();
  }
}

/// 더블 탭 기능이 있는 햅틱 버튼
class HapticDoubleTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final String singleTapHapticType;
  final String doubleTapHapticType;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool enabled;
  final Duration doubleTapDelay;

  const HapticDoubleTapButton({
    Key? key,
    required this.child,
    this.onSingleTap,
    this.onDoubleTap,
    this.singleTapHapticType = 'tick',
    this.doubleTapHapticType = 'double_tick',
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.enabled = true,
    this.doubleTapDelay = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<HapticDoubleTapButton> createState() => _HapticDoubleTapButtonState();
}

class _HapticDoubleTapButtonState extends State<HapticDoubleTapButton> {
  int _lastTapTime = 0;
  bool _isWaitingForSecondTap = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }

  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_isWaitingForSecondTap && (now - _lastTapTime) < widget.doubleTapDelay.inMilliseconds) {
      // 더블 탭 감지
      _isWaitingForSecondTap = false;
      HapticService.instance.vibrateCustomSequence(widget.doubleTapHapticType);
      widget.onDoubleTap?.call();
    } else {
      // 첫 번째 탭
      _lastTapTime = now;
      _isWaitingForSecondTap = true;
      
      HapticService.instance.vibrateCustomSequence(widget.singleTapHapticType);
      widget.onSingleTap?.call();
      
      // 지연 후 더블 탭 대기 상태 해제
      Future.delayed(widget.doubleTapDelay, () {
        if (mounted) {
          setState(() {
            _isWaitingForSecondTap = false;
          });
        }
      });
    }
  }
}

/// 햅틱 ElevatedButton
class HapticElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String hapticType;
  final ButtonStyle? style;

  const HapticElevatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hapticType = 'tick',
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed != null ? _handlePressed : null,
      style: style,
      child: child,
    );
  }

  void _handlePressed() {
    HapticService.instance.vibrateCustomSequence(hapticType);
    onPressed?.call();
  }
}

/// 햅틱 TextButton
class HapticTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String hapticType;
  final ButtonStyle? style;

  const HapticTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.hapticType = 'tick',
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed != null ? _handlePressed : null,
      style: style,
      child: child,
    );
  }

  void _handlePressed() {
    HapticService.instance.vibrateCustomSequence(hapticType);
    onPressed?.call();
  }
}

/// 햅틱 IconButton
class HapticIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String hapticType;
  final double? iconSize;
  final Color? color;
  final String? tooltip;

  const HapticIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.hapticType = 'tick',
    this.iconSize,
    this.color,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed != null ? _handlePressed : null,
      icon: icon,
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
    );
  }

  void _handlePressed() {
    HapticService.instance.vibrateCustomSequence(hapticType);
    onPressed?.call();
  }
} 