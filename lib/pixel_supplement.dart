import 'package:flutter/material.dart';

// --- 귀여운 2D 도트 영양제(알약) 캡슐을 그리는 위젯 ---
class PixelSupplement extends StatelessWidget {
  final double size;

  const PixelSupplement({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PixelSupplementPainter()),
    );
  }
}

class PixelSupplementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const int e = 0; // 투명
    const int b = 1; // 테두리 (진한 회색)
    const int r = 2; // 캡슐 윗부분 (핑크색)
    const int w = 3; // 캡슐 아랫부분 (흰색)
    const int s = 4; // 광택 (반투명 흰색)

    // 45도 기울어진 8x8 픽셀 캡슐 디자인
    final List<List<int>> pixels = [
      [e, e, e, e, e, b, b, e],
      [e, e, e, e, b, s, r, b],
      [e, e, e, b, r, r, r, b],
      [e, e, b, r, r, r, b, e],
      [e, b, w, w, w, b, e, e],
      [b, s, w, w, b, e, e, e],
      [b, w, s, b, e, e, e, e],
      [e, b, b, e, e, e, e, e],
    ];

    final double pixelWidth = size.width / pixels[0].length;
    final double pixelHeight = size.height / pixels.length;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == e) {
          continue;
        }

        if (pixels[y][x] == b) {
          paint.color = const Color(0xFF212123);
        } else if (pixels[y][x] == r) {
          paint.color = const Color(0xFFCF8ACB);
        } else if (pixels[y][x] == w) {
          paint.color = const Color(0xFFF2F0E5);
        } else if (pixels[y][x] == s) {
          paint.color = const Color(0xFFF2F0E5).withValues(alpha: 0.7);
        }

        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
