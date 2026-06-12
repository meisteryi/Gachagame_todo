import 'dart:math';
import 'package:flutter/material.dart';

// --- 귀여운 2D 도트 수초를 그리는 위젯 ---
class PixelSeaweed extends StatefulWidget {
  final String type;
  final bool isAnimated;

  const PixelSeaweed({
    super.key,
    this.type = 'green_algae',
    this.isAnimated = true,
  });

  @override
  State<PixelSeaweed> createState() => _PixelSeaweedState();
}

class _PixelSeaweedState extends State<PixelSeaweed>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 수초가 살랑거리는 속도
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(40, 50), // 수초에 맞게 세로로 약간 긴 비율
          painter: PixelSeaweedPainter(widget.type, _controller.value),
        );
      },
    );
  }
}

class PixelSeaweedPainter extends CustomPainter {
  final String type;
  final double time;
  PixelSeaweedPainter(this.type, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const int e = 0; // 투명 (배경)
    const int c1 = 1; // 주색
    const int c2 = 2; // 보조색

    Color color1 = Colors.green;
    Color color2 = Colors.lightGreen;
    List<List<int>> pixels;

    if (type == 'red_algae') {
      color1 = Colors.red;
      color2 = Colors.redAccent;
      pixels = [
        [e, e, c1, e, e, e, c2, e],
        [e, c1, c1, e, e, c2, c2, e],
        [e, c1, e, e, c2, c2, e, e],
        [e, c1, c1, c2, c2, e, e, e],
        [e, e, c1, c1, e, e, e, e],
        [e, c1, c1, c1, c1, e, e, e],
        [c1, c1, e, c1, c1, c1, e, e],
        [c1, e, e, e, c1, c1, e, e],
      ];
    } else if (type == 'kelp') {
      color1 = Colors.green[800]!;
      color2 = Colors.green[600]!;
      pixels = [
        [e, e, c1, c1, e, e],
        [e, c1, c1, c2, e, e],
        [e, c1, c2, c2, e, e],
        [e, c1, c1, c2, e, e],
        [e, e, c1, c1, e, e],
        [e, c1, c1, c2, e, e],
        [e, c1, c2, c2, e, e],
        [e, c1, c1, c1, e, e],
      ];
    } else if (type == 'coral') {
      color1 = Colors.pinkAccent;
      color2 = Colors.pink;
      pixels = [
        [e, c1, e, e, e, c2, e],
        [c1, c1, c1, e, c2, c2, c2],
        [e, c1, c1, c1, c2, c2, e],
        [e, e, c1, c1, c1, e, e],
        [e, c1, c1, c1, c1, c1, e],
        [c1, c1, c1, c1, c1, c1, c1],
        [e, c1, c1, c1, c1, c1, e],
        [e, e, c1, c1, c1, e, e],
      ];
    } else if (type == 'anemone') {
      color1 = Colors.purpleAccent;
      color2 = Colors.deepPurpleAccent;
      pixels = [
        [c1, e, c2, e, c1, e, c2],
        [c1, c1, c2, c2, c1, c1, c2],
        [e, c1, c1, c2, c1, c2, e],
        [e, e, c1, c1, c1, e, e],
        [e, c2, c1, c1, c1, c2, e],
        [c2, c2, c2, c1, c2, c2, c2],
        [e, c2, c2, c2, c2, c2, e],
        [e, e, c2, c2, c2, e, e],
      ];
    } else {
      // green_algae (default)
      color1 = Colors.green;
      color2 = Colors.lightGreen;
      pixels = [
        [e, e, c2, e, e],
        [e, c2, c1, e, e],
        [c2, c1, c1, e, e],
        [e, c1, c1, c2, e],
        [e, e, c1, c1, c2],
        [e, c2, c1, c1, e],
        [c2, c1, c1, e, e],
        [e, c1, c1, e, e],
      ];
    }

    final pixelWidth = size.width / pixels[0].length;
    final pixelHeight = size.height / pixels.length;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == e) continue;
        paint.color = pixels[y][x] == c1 ? color1 : color2;

        // 🌱 수초가 물결에 따라 살랑거리는 픽셀 애니메이션 (위쪽일수록 좌우로 더 흔들림)
        double sway = 0;
        if (y < 7) {
          sway =
              sin(time * pi * 2 - y * 0.4) *
              (7 - y) *
              0.15; // 💡 픽셀 스냅 대신 소수점 단위의 부드러운 웨이브 적용
        }

        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth + (sway * pixelWidth),
            y * pixelHeight,
            pixelWidth,
            pixelHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelSeaweedPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.time != time;
}
