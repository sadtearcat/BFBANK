import 'package:flutter/material.dart';

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

  Widget _buildButton(Widget? content, VoidCallback? onPressed, Color backgroundColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        ),
        child: content ?? Container(),
      ),
    );
  }
} 