import 'package:flutter/material.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/tts_service.dart';
import 'haptic_button.dart';

class DefaultPage extends StatelessWidget {
  final Widget? upperLeftWidget;
  final Widget? upperRightWidget;
  final Widget? lowerLeftWidget;
  final Widget? lowerRightWidget;
  final Widget? mainWidget;
  final VoidCallback? onUpperLeftPress;
  final VoidCallback? onUpperRightPress;
  final VoidCallback? onLowerLeftPress;
  final VoidCallback? onLowerRightPress;
  // 더블탭 TTS 메시지들
  final String? upperLeftTTS;
  final String? upperRightTTS;
  final String? lowerLeftTTS;
  final String? lowerRightTTS;

  const DefaultPage({
    Key? key,
    this.upperLeftWidget,
    this.upperRightWidget,
    this.lowerLeftWidget,
    this.lowerRightWidget,
    this.mainWidget,
    this.onUpperLeftPress,
    this.onUpperRightPress,
    this.onLowerLeftPress,
    this.onLowerRightPress,
    this.upperLeftTTS,
    this.upperRightTTS,
    this.lowerLeftTTS,
    this.lowerRightTTS,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // 상단 버튼들
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  // 왼쪽 상단 버튼
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: _buildButton(
                        upperLeftWidget,
                        onUpperLeftPress,
                        const Color(0xFF1C2C58),
                        upperLeftTTS,
                      ),
                    ),
                  ),
                  // 오른쪽 상단 버튼
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: _buildButton(
                        upperRightWidget,
                        onUpperRightPress,
                        const Color(0xFF3A3A3C),
                        upperRightTTS,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 메인 영역
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: mainWidget ?? Container(),
                ),
              ),
            ),
          ),
          // 하단 버튼들
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  // 왼쪽 하단 버튼
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: _buildButton(
                        lowerLeftWidget,
                        onLowerLeftPress,
                        const Color(0xFF7B61FF),
                        lowerLeftTTS,
                      ),
                    ),
                  ),
                  // 오른쪽 하단 버튼
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: _buildButton(
                        lowerRightWidget,
                        onLowerRightPress,
                        const Color(0xFF34C759),
                        lowerRightTTS,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(Widget? content, VoidCallback? onPressed, Color backgroundColor, String? ttsMessage) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ttsMessage != null 
        ? HapticDoubleTapButton(
            onSingleTap: () {
              TtsService().speak(ttsMessage);
            },
            onDoubleTap: onPressed,
            singleTapHapticType: 'tick',
            doubleTapHapticType: 'double_tick',
            backgroundColor: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: content ?? Container(),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed != null ? () {
              // 기본 햅틱 피드백 적용 (더블탭이 아닌 경우)
              HapticService.instance.vibrateCustomSequence('tick');
              onPressed();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: content ?? Container(),
            ),
          ),
    );
  }
} 