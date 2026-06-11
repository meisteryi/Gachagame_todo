import 'package:flutter/material.dart';

// --- 귀여운 2D 도트 물고기를 그리는 위젯 ---
class PixelFish extends StatelessWidget {
  final String type;

  const PixelFish({super.key, this.type = 'puffer'});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 40), // 전체 물고기의 크기
      painter: PixelFishPainter(type),
    );
  }
}

class PixelFishPainter extends CustomPainter {
  final String type;
  PixelFishPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const int e = 0; // 투명 (배경)
    const int c1 = 1; // 주색
    const int c2 = 2; // 보조색
    const int w = 3; // 흰색
    const int b = 4; // 검은색
    const int a = 5; // 물줄기

    Color color1 = Colors.orangeAccent;
    Color color2 = Colors.transparent;
    List<List<int>> pixels;

    if (type == 'goldfish') {
      color1 = Colors.redAccent;
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, c1, c1, c1, e, e, e, e, e, e],
        [e, e, e, e, c1, c1, c1, c1, c1, e, e, e, e, e],
        [c1, e, e, c1, c1, c1, c1, c1, c1, c1, e, e, e, e],
        [c1, c1, e, c1, c1, c1, c1, w, w, c1, c1, e, e, e],
        [c1, e, e, c1, c1, c1, c1, w, b, c1, c1, e, e, e],
        [e, e, e, e, c1, c1, e, c1, c1, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'mackerel') {
      color1 = Colors.blue;
      color2 = Colors.grey[300]!;
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, c1, c1, e, e, e],
        [c1, c1, e, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [c2, c2, c2, c2, c2, c2, c2, c2, c2, w, b, c2, e, e],
        [e, c2, c2, c2, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'shark') {
      color1 = Colors.blueGrey[700]!;
      color2 = Colors.grey[300]!;
      pixels = [
        [e, e, e, e, e, e, e, e, c1, c1, e, e, e, e],
        [e, e, e, e, e, e, e, c1, c1, c1, e, e, e, e],
        [e, e, e, e, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [c1, c1, e, c1, c1, c1, c1, c1, c1, w, b, c1, e, e],
        [c1, c1, c1, c1, c1, c1, c1, c1, c1, w, w, c1, c1, e],
        [c1, c1, e, c1, c1, e, e, e, e, c1, c1, c1, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'whale') {
      color1 = Colors.indigo[600]!;
      color2 = Colors.lightBlue[200]!;
      pixels = [
        [e, e, e, e, e, e, e, e, a, e, a, e, e, e],
        [e, e, e, e, e, e, e, e, e, a, e, e, e, e],
        [e, e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [c1, c1, e, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e],
        [c1, c1, c1, c1, c1, c1, c1, c1, c1, w, b, c1, c1, e],
        [e, c1, c1, c1, c2, c2, c2, c2, c2, w, w, c2, c2, e],
        [e, e, e, e, e, c2, c2, c2, c2, c2, c2, c2, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'betta') {
      color1 = Colors.pinkAccent; // 화려한 몸통
      color2 = Colors.cyanAccent; // 펄럭이는 지느러미
      pixels = [
        [e, e, e, e, c2, c2, c2, c2, c2, c2, e, e, e, e],
        [e, e, c2, c2, c2, c1, c1, c1, c1, c2, e, e, e, e],
        [e, c2, c2, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [c2, c2, c1, c1, c1, c1, c1, c1, c1, w, b, c1, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, c2, c2, c1, c1, c1, c1, c2, c2, c2, e, e, e, e],
        [e, e, c2, c2, c2, c2, c2, c2, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'nemo') {
      color1 = Colors.deepOrange; // 주황색 몸통
      color2 = Colors.white; // 흰 줄무늬
      pixels = [
        [e, e, e, e, e, e, e, c1, c1, c1, e, e, e, e],
        [e, e, e, e, e, e, c1, c1, c1, c1, c1, e, e, e],
        [e, e, c1, c1, c1, c1, c1, c2, c2, c1, c1, c1, e, e],
        [e, c1, c1, c1, c1, c1, c1, c2, c2, c1, w, b, c1, e],
        [c1, c1, c1, c1, c1, c1, c1, c2, c2, c1, c1, c1, c1, e],
        [e, c1, c1, c1, c1, c1, c1, c2, c2, c1, c1, c1, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'guppy') {
      color1 = Colors.cyanAccent; // 작고 푸른 몸통
      color2 = Colors.purpleAccent; // 풍성한 보라색 꼬리
      pixels = [
        [e, c2, c2, c2, e, e, e, e, e, e, e, e, e, e],
        [c2, c2, c2, c2, c2, e, e, e, e, e, e, e, e, e],
        [c2, c2, c2, c2, c2, c1, c1, c1, c1, e, e, e, e, e],
        [c2, c2, c2, c2, c2, c1, c1, c1, w, b, e, e, e, e],
        [c2, c2, c2, c2, c1, c1, c1, c1, c1, c1, e, e, e, e],
        [e, c2, c2, c2, e, e, c1, c1, e, e, e, e, e, e],
        [e, e, c2, c2, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else {
      // puffer (default)
      color1 = Colors.orangeAccent;
      pixels = [
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [c1, c1, e, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [c1, c1, c1, c1, c1, c1, c1, w, w, c1, c1, c1, e, e],
        [c1, c1, c1, c1, c1, c1, c1, w, b, c1, c1, c1, e, e],
        [c1, c1, e, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
      ];
    }

    final pixelWidth = size.width / pixels[0].length;
    final pixelHeight = size.height / pixels.length;

    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        if (pixels[y][x] == e) continue;

        if (pixels[y][x] == c1) {
          paint.color = color1;
        } else if (pixels[y][x] == c2) {
          paint.color = color2;
        } else if (pixels[y][x] == w) {
          paint.color = Colors.white;
        } else if (pixels[y][x] == b) {
          paint.color = Colors.black;
        } else if (pixels[y][x] == a) {
          paint.color = Colors.lightBlueAccent;
        }

        // 배열에 맞춰 각 픽셀(사각형)을 캔버스에 그립니다.
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
