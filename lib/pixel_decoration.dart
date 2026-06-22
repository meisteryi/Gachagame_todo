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
  static const int c5 = 5;

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
          const Color(0xFF5D3F1E), // 진한 외곽/나선선
          const Color(0xFFC69752), // 중간 황금갈색
          const Color(0xFFF3D299), // 연한 베이지 하이라이트
          const Color(0xFF3E2713), // 제일 어두운 브라운 테두리
        ];
        pixels = [
          [e, e, e, e, c4, c4, c4, c4, e, e, e, e],
          [e, e, c4, c4, c2, c2, c2, c2, c4, c4, e, e],
          [e, c4, c2, c2, c3, c3, c3, c3, c2, c2, c4, e],
          [c4, c2, c3, c1, c1, c1, c1, c1, c3, c2, c2, c4],
          [c4, c2, c1, c3, c3, c3, c3, c2, c1, c3, c2, c4],
          [c4, c2, c1, c3, c2, c2, c1, c1, c1, c3, c2, c4],
          [c4, c2, c1, c3, c2, c1, c3, c3, c1, c3, c2, c4],
          [c4, c2, c2, c1, c2, c1, c1, c1, c2, c2, c2, c4],
          [e, c4, c2, c2, c1, c2, c2, c2, c2, c2, c4, e],
          [e, e, c4, c4, c2, c2, c2, c2, c2, c4, c4, e],
          [e, e, e, e, c4, c4, c4, c4, c4, c4, e, e],
        ];
        break;

      // ════════════════════════════════════════
      // 큰 현무암 (넓고 낮은 바위, 회색 계열)
      // ════════════════════════════════════════
      case 'basalt':
        palette = [
          Colors.transparent,
          const Color(0xFF2E2E3E), // 어두운 청회색
          const Color(0xFF4E5066), // 중간 회적색
          const Color(0xFF7A7D9A), // 밝은 청회색 (하이라이트)
          const Color(0xFF1B1B26), // 주상절리 기둥 틈새/테두리 검정
        ];
        pixels = [
          [e, e, e, e, c4, c4, c4, c4, e, e, e, e, e, e, e, e],
          [e, e, e, c4, c3, c3, c2, c2, c4, e, e, e, e, e, e, e],
          [e, e, c4, c2, c3, c2, c1, c1, c2, c4, e, e, e, e, e, e],
          [e, c4, c2, c2, c2, c1, c1, c1, c1, c2, c4, c4, c4, e, e, e],
          [c4, c3, c3, c2, c1, c4, c1, c4, c1, c1, c2, c3, c2, c4, e, e],
          [c4, c2, c2, c1, c4, c1, c4, c1, c4, c1, c2, c2, c1, c2, c4, e],
          [c4, c1, c1, c1, c4, c1, c4, c1, c4, c1, c1, c1, c1, c1, c2, c4],
          [c4, c1, c1, c1, c4, c1, c4, c1, c4, c1, c1, c1, c1, c1, c1, c4],
          [c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4, c4],
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
          const Color(0xFF3E2713), // 아주 어두운 나무 갈색 (그늘)
          const Color(0xFF6B4527), // 메인 선체 갈색
          const Color(0xFF2A483A), // 선체에 낀 초록 이끼/수초
          const Color(0xFF9E7047), // 밝은 나무 하이라이트
          const Color(0xFF1E1108), // 선체 윤곽 검정
        ];
        pixels = [
          [e, e, e, e, e, e, c5, c5, e, e, e, e, e, e, e, e, e, e],
          [e, e, e, e, e, c5, c2, c4, c5, e, e, e, e, e, e, e, e, e],
          [e, e, e, e, e, c5, c2, c2, c5, e, e, e, e, e, e, e, e, e], // 돛대 잔해
          [e, e, e, e, e, e, c5, c5, e, e, e, e, e, e, e, e, e, e],
          [e, e, e, c5, c5, c5, c5, c5, c5, c5, c5, e, e, e, e, e, e, e],
          [e, c5, c5, c2, c2, c4, c2, c2, c4, c2, c2, c5, c5, e, e, e, e, e], // 갑판선
          [c5, c2, c2, c4, c2, c2, c2, c2, c2, c2, c2, c2, c2, c5, e, e, e, e],
          [c5, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c2, c5, e, e, e], // 어두운 안쪽 선체
          [c5, c2, c3, c2, c5, c2, c3, c2, c5, c2, c3, c2, c2, c2, c2, c5, e, e], // 이끼와 구멍
          [e, c5, c2, c2, c2, c2, c2, c2, c2, c2, c2, c2, c2, c2, c5, c5, e, e],
          [e, e, c5, c2, c3, c2, c2, c2, c3, c2, c2, c2, c2, c5, e, e, e, e], // 선체 하부
          [e, e, e, c5, c5, c5, c5, c5, c5, c5, c5, c5, c5, e, e, e, e, e],
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
