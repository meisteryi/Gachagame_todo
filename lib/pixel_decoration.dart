import 'dart:math';
import 'package:flutter/material.dart';

// --- 수조 장식물 도트 픽셀 위젯 ---
class PixelDecoration extends StatefulWidget {
  final String type;
  final bool isAnimated;

  const PixelDecoration({
    super.key,
    required this.type,
    this.isAnimated = true,
  });

  @override
  State<PixelDecoration> createState() => _PixelDecorationState();

  static Size sizeFor(String type) {
    switch (type) {
      case 'ammonite':
        return const Size(44, 44);
      case 'basalt':
        return const Size(64, 36);
      case 'spongebob_house':
        return const Size(48, 68);
      case 'sunken_ship':
        return const Size(72, 52);
      default:
        return const Size(44, 44);
    }
  }
}

class _PixelDecorationState extends State<PixelDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + random.nextInt(1400)),
    );
    if (widget.isAnimated) {
      _controller.value = random.nextDouble();
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
    final sz = PixelDecoration.sizeFor(widget.type);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: sz,
        painter: PixelDecorationPainter(widget.type, _controller.value),
      ),
    );
  }
}

class PixelDecorationPainter extends CustomPainter {
  final String type;
  final double time;
  PixelDecorationPainter(this.type, this.time);

  static const int e = 0;
  static const int c1 = 1;
  static const int c2 = 2;
  static const int c3 = 3;
  static const int c4 = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    late List<Color> palette;
    late List<List<int>> pixels;

    switch (type) {

      // ════════════════════════════════════════
      // 암모나이트 화석 (나선형, 황금갈색)
      // ════════════════════════════════════════
      case 'ammonite':
        palette = [
          Colors.transparent,
          const Color(0xFF7A5310), // 진한 갈색
          const Color(0xFFBF8C3A), // 중간 황금
          const Color(0xFFE8C87A), // 연한 크림
          const Color(0xFF4A3008), // 외곽 어두운
        ];
        pixels = [
          [e, e, e, c4, c4, c4, c4, c4, e, e],
          [e, e, c4, c1, c2, c2, c2, c1, c4, e],
          [e, c4, c1, c2, c3, c3, c2, c2, c1, c4],
          [c4, c1, c2, c3, c4, c4, c3, c2, c2, c1],
          [c4, c1, c2, c3, c4, e, c3, c3, c2, c1],
          [c4, c2, c2, c3, c3, c3, c1, c2, c2, c1],
          [c4, c1, c2, c2, c1, c2, c2, c1, c1, c4],
          [e, c4, c1, c1, c2, c2, c1, c1, c4, e],
          [e, e, c4, c4, c1, c1, c4, c4, e, e],
          [e, e, e, e, c4, c4, e, e, e, e],
        ];
        break;

      // ════════════════════════════════════════
      // 큰 현무암 (넓고 낮은 바위, 회색 계열)
      // ════════════════════════════════════════
      case 'basalt':
        palette = [
          Colors.transparent,
          const Color(0xFF2A2A2A), // 아주 어두운 회
          const Color(0xFF505050), // 중간 회
          const Color(0xFF787878), // 밝은 회 (하이라이트)
          const Color(0xFF141414), // 최외각 검정
        ];
        pixels = [
          [e, e, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, e, e],
          [e, c4, c1, c3, c2, c1, c2, c1, c2, c1, c2, c1, c4, e],
          [c4, c1, c2, c1, c3, c2, c1, c2, c1, c3, c1, c2, c1, c4],
          [c4, c2, c1, c2, c1, c1, c2, c1, c2, c1, c2, c1, c2, c4],
          [c4, c1, c2, c1, c2, c3, c1, c3, c1, c2, c1, c2, c1, c4],
          [c4, c2, c1, c2, c1, c2, c1, c2, c1, c1, c2, c1, c2, c4],
          [e, c4, c1, c2, c1, c1, c2, c1, c2, c1, c2, c1, c4, e],
          [e, e, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, e, e],
          [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        ];
        break;

      // ════════════════════════════════════════
      // 스폰지밥 집 (파인애플 모양)
      // ════════════════════════════════════════
      case 'spongebob_house':
        palette = [
          Colors.transparent,
          const Color(0xFFD4841A), // 주황 몸통
          const Color(0xFF2D8B18), // 초록 잎
          const Color(0xFF8B4A00), // 진한 주황 (창문/윤곽)
          const Color(0xFFF5DC60), // 노란 하이라이트
        ];
        pixels = [
          [e, e, e, c2, c2, c2, e, e, e, e],  // 잎 꼭대기
          [e, e, c2, e, c2, e, c2, e, e, e],
          [e, c2, e, c2, e, c2, e, c2, e, e],
          [e, e, c2, c2, c2, c2, c2, e, e, e],
          [e, c3, c3, c3, c3, c3, c3, c3, e, e], // 몸통 윤곽
          [e, c3, c1, c4, c1, c4, c1, c3, e, e],
          [e, c1, c3, c4, c4, c4, c3, c1, e, e], // 창문
          [e, c1, c4, c4, e, c4, c4, c1, e, e],
          [e, c1, c3, c4, c4, c4, c3, c1, e, e],
          [e, c3, c1, c4, c1, c4, c1, c3, e, e],
          [e, c1, c1, c3, c1, c3, c1, c1, e, e],
          [e, c3, c1, c1, c3, c1, c1, c3, e, e],
          [e, c1, c1, c1, c1, c1, c1, c1, e, e],
          [e, c3, c3, c3, c3, c3, c3, c3, e, e], // 바닥
          [e, e, e, e, e, e, e, e, e, e],
        ];
        break;

      // ════════════════════════════════════════
      // 침몰한 배 잔해
      // ════════════════════════════════════════
      case 'sunken_ship':
      default:
        palette = [
          Colors.transparent,
          const Color(0xFF5C3A1A), // 썩은 나무 갈색
          const Color(0xFF8B6340), // 중간 갈색
          const Color(0xFF3A3A50), // 회청색 금속
          const Color(0xFFA08060), // 연 베이지 갈색
        ];
        pixels = [
          [e, e, e, e, c3, c3, e, e, e, e, e, e, e, e, e],
          [e, e, e, c3, c1, c3, c3, e, e, e, e, e, e, e, e],
          [e, e, c3, c1, c2, c1, c3, e, e, e, e, e, e, e, e],
          [e, c3, c1, c2, c3, c2, c1, c3, c3, c3, e, e, e, e, e],
          [c3, c1, c1, c2, c3, c2, c1, c1, c2, c1, c3, e, e, e, e],
          [c1, c2, c1, c1, c2, c1, c2, c4, c1, c2, c1, c3, e, e, e],
          [c1, c1, c2, c3, c1, c3, c4, c1, c4, c1, c2, c1, c3, e, e],
          [c3, c1, c1, c1, c2, c1, c1, c1, c1, c2, c1, c1, c1, c3, e],
          [e, c3, c3, c1, c1, c1, c2, c1, c1, c1, c1, c3, c3, e, e],
          [e, e, e, c3, c3, c3, c3, c3, c3, c3, c3, e, e, e, e],
          [e, e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        ];
        break;
    }

    final int rows = pixels.length;
    final int cols = pixels[0].length;
    final double pw = size.width / cols;
    final double ph = size.height / rows;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        final int cell = pixels[y][x];
        if (cell == e) continue;
        paint.color = palette[cell];

        // 바닥 부분은 아주 미세하게 흔들림
        double sway = 0;
        if (y < rows - 3) {
          sway = sin(time * pi * 2) * (rows - 1 - y) * 0.025;
        }

        canvas.drawRect(
          Rect.fromLTWH(x * pw + sway * pw, y * ph, pw, ph),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelDecorationPainter old) =>
      old.type != type || old.time != time;
}
