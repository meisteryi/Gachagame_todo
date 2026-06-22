import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_manager.dart';

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
    final random = Random();
    // 💡 수초마다 1.5초 ~ 2.5초 사이의 랜덤한 흔들림 주기를 부여합니다.
    final int randomDurationMs = 1500 + random.nextInt(1000);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: randomDurationMs),
    );
    if (widget.isAnimated) {
      _controller.value = random.nextDouble(); // 💡 흔들리는 타이밍(시작점)도 랜덤하게 흩뿌림
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

    Color color1 = const Color(0xFF8AB060);
    Color color2 = const Color(0xFFC2D368);
    List<List<int>> pixels;

    if (type == 'red_algae') {
      color1 = const Color(0xFFB45252);
      color2 = const Color(0xFFCF8ACB);
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
      color1 = const Color(0xFF646365);
      color2 = const Color(0xFF8AB060);
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
      color1 = const Color(0xFFCF8ACB);
      color2 = const Color(0xFF6A536E);
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
      color1 = const Color(0xFF43436A);
      color2 = const Color(0xFF646365);
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
    } else if (type == 'purple_kelp') {
      color1 = const Color(0xFF646365);
      color2 = const Color(0xFF212123);
      pixels = [
        [e, c1, c2, e, e, e],
        [e, c2, c1, e, e, e],
        [e, c1, c2, c2, e, e],
        [e, c1, c1, c2, e, e],
        [e, c2, c1, c1, e, e],
        [e, c1, c2, c1, e, e],
        [e, c1, c1, c2, e, e],
        [e, c2, c1, c1, e, e],
        [e, c1, c2, c1, e, e],
        [e, c1, c1, c1, e, e],
      ];
    } else if (type == 'short_grass') {
      color1 = const Color(0xFFEDE19E);
      color2 = const Color(0xFF8AB060);
      pixels = [
        [e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e],
        [e, c1, e, e, e, c2, e, e],
        [c1, c1, e, c1, e, c2, c2, e],
        [c1, c2, c1, c1, c2, c1, c2, e],
        [c1, c1, c1, c2, c1, c1, c1, e],
      ];
    } else if (type == 'blue_coral') {
      color1 = const Color(0xFF4B80CA);
      color2 = const Color(0xFF68C2D3);
      pixels = [
        [e, e, c1, e, e, e, c2, e],
        [e, c1, c1, e, e, c2, c2, e],
        [c1, c1, e, c1, c2, c2, e, e],
        [e, c1, c1, c1, c1, c2, e, e],
        [e, e, c1, c1, c1, e, e, e],
        [e, c2, c1, c1, c1, c2, e, e],
        [c2, c2, c1, c1, c1, c2, c2, e],
        [c2, c1, c1, c1, c1, c1, c2, e],
      ];
    } else if (type == 'tall_bamboo') {
      color1 = const Color(0xFFC2D368);
      color2 = const Color(0xFF8AB060);
      pixels = [
        [e, e, c1, c2, e, e],
        [e, e, c1, c2, e, e],
        [e, c1, c1, c2, c2, e],
        [e, e, c1, c2, e, e],
        [e, e, c1, c2, e, e],
        [e, e, c1, c2, e, e],
        [e, c1, c1, c2, c2, e],
        [e, e, c1, c2, e, e],
        [e, e, c1, c2, e, e],
        [e, e, c1, c2, e, e],
        [e, c1, c1, c2, c2, e],
        [e, e, c1, c2, e, e],
      ];
    } else if (type == 'golden_leaf') {
      color1 = const Color(0xFFD3A068);
      color2 = const Color(0xFFA77B5B);
      pixels = [
        [e, e, c1, c2, e, e, e],
        [e, c1, c1, c2, c2, e, e],
        [e, e, c1, c2, e, e, e],
        [e, c2, c1, c1, c1, e, e],
        [c2, c2, c1, c2, c1, c1, e],
        [e, e, c1, c2, e, e, e],
        [e, c1, c1, c1, c2, e, e],
        [c1, c1, c2, c1, c2, c2, e],
        [e, e, c1, c2, e, e, e],
      ];
    } else {
      // green_algae (default)
      color1 = const Color(0xFF8AB060);
      color2 = const Color(0xFFC2D368);
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

    final resolvedColors = AppTheme.getSeaweedColors(type);
    color1 = resolvedColors['c1']!;
    color2 = resolvedColors['c2']!;

    final pixelWidth = size.width / pixels[0].length;
    final pixelHeight = size.height / pixels.length;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == e) {
          continue;
        }
        paint.color = pixels[y][x] == c1 ? color1 : color2;

        // 🌱 수초가 물결에 따라 살랑거리는 픽셀 애니메이션 (위쪽일수록 좌우로 더 흔들림)
        double sway = 0;
        int bottomY = pixels.length - 1;
        if (y < bottomY) {
          sway =
              sin(time * pi * 2 - y * 0.4) *
              (bottomY - y) *
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
