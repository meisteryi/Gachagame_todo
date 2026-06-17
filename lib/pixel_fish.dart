import 'dart:math';
import 'package:flutter/material.dart';

// --- 귀여운 2D 도트 물고기를 그리는 위젯 ---
class PixelFish extends StatefulWidget {
  final String type;
  final bool isAnimated;

  const PixelFish({super.key, this.type = 'puffer', this.isAnimated = true});

  @override
  State<PixelFish> createState() => _PixelFishState();
}

class _PixelFishState extends State<PixelFish>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 꼬리치는 속도
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
          size: const Size(60, 40), // 전체 물고기의 크기
          painter: PixelFishPainter(widget.type, _controller.value),
        );
      },
    );
  }
}

class PixelFishPainter extends CustomPainter {
  final String type;
  final double time;
  PixelFishPainter(this.type, this.time);

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
    } else if (type == 'axolotl') {
      color1 = Colors.pink[200]!; // 귀여운 분홍색 몸통
      color2 = Colors.pinkAccent; // 아가미 및 꼬리
      pixels = [
        [e, e, e, e, e, e, e, c2, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, c2, c1, c1, e, e, e, e],
        [e, e, e, e, e, e, c2, c1, c1, c1, c1, e, e, e],
        [e, c2, c2, e, c1, c1, c1, c1, c1, w, b, c1, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, c2, c2, e, c1, c1, c1, c1, c1, c1, e, e, e, e],
        [e, e, e, e, e, c1, e, c2, c1, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'tuna') {
      color1 = Colors.blueGrey[300]!; // 은빛 몸통
      color2 = Colors.indigo[800]!; // 진한 지느러미
      pixels = [
        [e, e, e, e, e, e, c2, c2, c2, e, e, e, e, e],
        [e, e, e, e, e, e, e, c2, c2, e, e, e, e, e],
        [e, c2, c2, e, e, c1, c1, c1, c1, c1, c2, e, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, c1, w, b, c1, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, c2, c2, e, e, c1, c1, c1, c1, c1, c2, e, e, e],
        [e, e, e, e, e, e, e, c2, c2, e, e, e, e, e],
        [e, e, e, e, e, e, c2, c2, c2, e, e, e, e, e],
      ];
    } else if (type == 'shrimp') {
      color1 = Colors.deepOrangeAccent; // 붉은 새우 등
      color2 = Colors.orange[200]!; // 연한 새우 배
      pixels = [
        [e, e, e, e, e, e, e, e, e, c1, c1, e, e, e],
        [e, e, e, e, c1, c1, c1, e, c1, w, b, e, e, e],
        [e, e, e, c1, c2, c2, c2, c1, c1, c1, c1, e, e, e],
        [e, e, c1, c2, c2, c1, c1, c1, c1, e, e, e, e, e],
        [e, c1, c1, c2, c1, e, c1, e, c1, e, e, e, e, e],
        [c1, c1, c1, e, e, c2, e, c2, e, e, e, e, e, e],
        [c1, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'seahorse') {
      color1 = Colors.amber; // 노란 몸통
      color2 = Colors.orange; // 주황색 갈기
      pixels = [
        [e, e, e, e, e, e, e, e, c2, c1, c1, c2, e, e],
        [e, e, e, e, e, e, e, c2, c1, w, b, c1, e, e],
        [e, e, e, e, e, e, e, c2, c1, c1, c1, c1, c1, e],
        [e, e, e, e, e, e, e, e, c1, c1, e, e, e, e],
        [e, e, e, e, e, e, c2, c1, c1, c1, e, e, e, e],
        [e, e, e, e, e, c2, c1, c1, c1, c2, e, e, e, e],
        [e, e, c1, c1, c1, c1, c1, c1, e, e, e, e, e, e],
        [e, e, e, c1, c1, c1, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'turtle') {
      color1 = Colors.green; // 초록 피부
      color2 = Colors.brown[700]!; // 갈색 등딱지
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, c2, c2, c2, c2, c2, e, e, e, e, e],
        [e, e, e, c2, c2, c2, c2, c2, c2, c2, e, e, e, e],
        [e, e, c2, c2, c2, c2, c2, c2, c2, c2, c1, c1, e, e],
        [e, c1, c1, c2, c2, c2, c2, c2, c2, c1, w, b, c1, e],
        [e, e, e, c1, c1, e, e, e, c1, c1, c1, c1, c1, e],
        [e, e, e, c1, e, e, e, e, e, c1, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'jellyfish') {
      color1 = Colors.pinkAccent[100]!; // 분홍빛 우산
      color2 = Colors.purpleAccent[100]!; // 보라빛 촉수
      pixels = [
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, e, c1, c1, c1, c1, c1, c1, e, e, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [e, e, e, c1, c1, w, b, c1, w, b, c1, c1, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [e, e, e, c2, e, c2, e, e, c2, e, c2, e, e, e],
        [e, e, c2, e, e, c2, e, e, c2, e, e, c2, e, e],
        [e, e, e, c2, e, e, c2, c2, e, e, c2, e, e, e],
      ];
    } else if (type == 'stingray') {
      color1 = Colors.blueGrey; // 푸른 회색 등
      color2 = Colors.grey[400]!; // 배
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, c1, c1, e, e, e, e, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, w, b, e, e],
        [c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, w, b, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, e, e, e, c1, c1, e, e, e, e, e, e],
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
        if (pixels[y][x] == e) {
          continue;
        }

        if (pixels[y][x] == c1) {
          paint.color = color1;
        } else if (pixels[y][x] == c2) {
          paint.color = color2;
        } else if (pixels[y][x] == w) {
          paint.color = Colors.white;
        } else if (pixels[y][x] == b) {
          paint.color = const Color(0xFF333333);
        } else if (pixels[y][x] == a) {
          paint.color = Colors.lightBlueAccent;
        }

        double dx = 0.0;
        double dy = 0.0;

        if (type == 'jellyfish') {
          // 🪼 해파리: 촉수 부분(y >= 5)이 아래로 갈수록 좌우로 하늘하늘 흔들리도록 적용
          if (y >= 5) {
            dx = sin(time * pi * 4 - y * 0.8) * (y - 4) * 0.2;
          }
        } else {
          // 🐟 일반 물고기: 왼쪽 꼬리 부분(x < 6)일수록 위아래로 더 크게 움직임
          if (x < 6) {
            dy = sin(time * pi * 2 - x * 0.4) * (6 - x) * 0.15;
          }
        }

        // 배열에 맞춰 각 픽셀(사각형)을 캔버스에 그립니다.
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth + (dx * pixelWidth),
            y * pixelHeight + (dy * pixelHeight),
            pixelWidth,
            pixelHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelFishPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.time != time;
}
