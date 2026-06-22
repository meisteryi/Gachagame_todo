import 'dart:math';
import 'package:flutter/material.dart';

// --- 귀여운 2D 도트 물고기를 그리는 위젯 ---
class PixelFish extends StatefulWidget {
  final String type;
  final bool isAnimated;
  final int level;

  const PixelFish({
    super.key,
    this.type = 'puffer',
    this.isAnimated = true,
    this.level = 1,
  });

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
    final int lv = widget.level.clamp(1, 5);
    final double scaleMultiplier = 1.0 + (lv - 1) * 0.125;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleMultiplier,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(60, 40), // 전체 물고기의 크기
            painter: PixelFishPainter(
              widget.type,
              _controller.value,
              widget.level,
            ),
          ),
        );
      },
    );
  }
}

class PixelFishPainter extends CustomPainter {
  final String type;
  final double time;
  final int level;
  PixelFishPainter(this.type, this.time, this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const int e = 0; // 투명 (배경)
    const int c1 = 1; // 주색
    const int c2 = 2; // 보조색
    const int w = 3; // 흰색
    const int b = 4; // 검은색
    const int a = 5; // 물줄기

    Color color1 = const Color(0xFFD3A068);
    Color color2 = Colors.transparent;
    List<List<int>> pixels;

    if (type == 'goldfish') {
      color1 = const Color(0xFFCF8ACB);
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
      color1 = const Color(0xFF4B80CA);
      color2 = const Color(0xFFB8B5B9);
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
      color1 = const Color(0xFF646365);
      color2 = const Color(0xFFF2F0E5);
      pixels = [
        [e, e, e, e, e, e, c1, c1, e, e, e, e, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [c1, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [c1, c1, c1, c1, c1, c1, c1, c1, w, b, c1, c1, c1, e],
        [e, c1, c1, c1, c1, c1, c2, c2, c2, w, b, w, e, e],
        [c1, c1, e, c1, c1, e, c2, c2, c2, c2, c2, e, e, e],
        [e, e, e, e, e, e, e, c2, c2, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'whale') {
      color1 = const Color(0xFF43436A);
      color2 = const Color(0xFF68C2D3);
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
      color1 = const Color(0xFFCF8ACB);
      color2 = const Color(0xFF68C2D3);
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
      color1 = const Color(0xFFD3A068); // 주황색 몸통
      color2 = const Color(0xFFF2F0E5); // 흰 줄무늬
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
      color1 = const Color(0xFF68C2D3); // 작고 푸른 몸통
      color2 = const Color(0xFFCF8ACB); // 풍성한 보라색 꼬리
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
      color1 = const Color(0xFFE5CEB4); // 귀여운 분홍색 몸통
      color2 = const Color(0xFFCF8ACB); // 아가미 및 꼬리
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
      color1 = const Color(0xFF868188); // 은빛 몸통
      color2 = const Color(0xFF646365); // 진한 지느러미
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
      color1 = const Color(0xFFD3A068); // 붉은 새우 등
      color2 = const Color(0xFFE5CEB4); // 연한 새우 배
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
      color1 = const Color(0xFFD3A068); // 노란 몸통
      color2 = const Color(0xFFA77B5B); // 주황색 갈기
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
      color1 = const Color(0xFF8AB060); // 초록 피부
      color2 = const Color(0xFF212123); // 갈색 등딱지
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
      color1 = const Color(0xFFE5CEB4); // 분홍빛 우산
      color2 = const Color(0xFF5F556A); // 보라빛 촉수
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
      color1 = const Color(0xFF868188); // 푸른 회색 등
      color2 = const Color(0xFFB8B5B9); // 배
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
    } else if (type == 'carp') {
      color1 = const Color(0xFFF2F0E5);
      color2 = const Color(0xFFCF8ACB);
      pixels = [
        [e, e, e, e, e, c2, c2, e, e, e, e, e, e, e],
        [e, e, e, e, c1, c1, c2, c2, c1, e, e, e, e, e],
        [e, e, e, c1, c1, c2, c1, c1, c1, c1, e, e, e, e],
        [c2, e, c1, c1, c2, c2, c1, c1, c1, c1, c1, e, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, w, w, c1, c1, e, e],
        [c2, e, c1, c1, c1, c1, c1, c1, w, b, c1, c1, e, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'crab') {
      color1 = const Color(0xFFE5CEB4);
      color2 = const Color(0xFFCF8ACB);
      pixels = [
        [e, c2, c2, e, e, e, e, e, e, e, e, c2, c2, e],
        [c2, c2, c2, c2, e, b, e, e, b, e, c2, c2, c2, c2],
        [c2, e, e, c2, e, w, c1, c1, w, e, c2, e, e, c2],
        [e, c2, c2, c2, c1, c1, c1, c1, c1, c1, c2, c2, c2, e],
        [e, e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e],
        [e, e, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, c2, e, c2, e, c2, e, e, c2, e, c2, e, c2, e],
        [c2, e, c2, e, c2, e, e, e, e, c2, e, c2, e, c2],
      ];
    } else if (type == 'whale_shark') {
      color1 = const Color(0xFF646365); // 진한 남색
      color2 = const Color(0xFFF2F0E5);
      pixels = [
        [e, e, e, e, e, e, c1, c1, e, e, e, e, e, e],
        [e, e, e, e, e, c1, c1, c1, c1, e, e, e, e, e],
        [e, e, e, c1, c1, c2, c1, c2, c1, c2, c1, c1, c1, e],
        [c1, e, c1, c1, c2, c1, c2, c1, c2, c1, w, b, c1, c1],
        [c1, c1, c1, c1, c1, c2, c1, c2, c1, c2, w, w, e, e],
        [e, c1, c1, c1, c2, c1, c2, c1, c2, c1, c1, c1, c1, c1],
        [e, e, e, c1, c1, e, e, e, c1, c1, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'electric_eel') {
      color1 = const Color(0xFF646365); // 어두운 블루그레이
      color2 = const Color(0xFFEDE19E);
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, c1, c1, c1, c1, c1, c1, c1, c1, e, e, e, e],
        [c1, c1, c1, c2, c1, c2, c1, c2, c1, w, b, c1, e, e],
        [c2, c1, c1, c1, c2, c1, c2, c1, c2, c1, c1, c1, e, e],
        [e, c2, c2, c2, c2, c2, c2, c2, c2, c2, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else if (type == 'salmon') {
      color1 = const Color(0xFFE5CEB4); // 살몬 핑크색
      color2 = const Color(0xFFB8B5B9); // 은색 실선
      pixels = [
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
        [e, e, e, e, e, c2, c2, c2, e, e, e, e, e, e],
        [e, e, c2, c2, c1, c1, c1, c1, c1, c1, c2, e, e, e],
        [c2, c1, c1, c2, c1, c2, c1, c2, c1, w, b, c1, e, e],
        [c2, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, c1, e, e],
        [e, c2, c2, e, e, c1, c1, c1, c1, c1, c2, e, e, e],
        [e, e, e, e, e, e, e, c2, c2, e, e, e, e, e],
        [e, e, e, e, e, e, e, e, e, e, e, e, e, e],
      ];
    } else {
      // puffer (default)
      color1 = const Color(0xFFD3A068);
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

    if (level >= 5) {
      if (type == 'goldfish') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFFD3A068);
      } else if (type == 'mackerel') {
        color1 = const Color(0xFF68C2D3);
        color2 = const Color(0xFFCF8ACB);
      } else if (type == 'shark') {
        color1 = const Color(0xFF212123);
        color2 = const Color(0xFFF2F0E5);
      } else if (type == 'whale') {
        color1 = const Color(0xFF212123);
        color2 = const Color(0xFFCF8ACB);
      } else if (type == 'betta') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFFCF8ACB);
      } else if (type == 'nemo') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFF212123);
      } else if (type == 'guppy') {
        color1 = const Color(0xFFCF8ACB);
        color2 = const Color(0xFFEDE19E);
      } else if (type == 'axolotl') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFFCF8ACB);
      } else if (type == 'tuna') {
        color1 = const Color(0xFFF2F0E5);
        color2 = const Color(0xFF68C2D3);
      } else if (type == 'shrimp') {
        color1 = const Color(0xFFCF8ACB);
        color2 = const Color(0xFF4B80CA);
      } else if (type == 'seahorse') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFF4B80CA);
      } else if (type == 'turtle') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFFD3A068);
      } else if (type == 'jellyfish') {
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFF68C2D3);
      } else if (type == 'stingray') {
        color1 = const Color(0xFF4B80CA);
        color2 = const Color(0xFF68C2D3);
      } else if (type == 'carp') {
        color1 = const Color(0xFFD3A068);
        color2 = const Color(0xFF80493A);
      } else if (type == 'crab') {
        color1 = const Color(0xFFB45252);
        color2 = const Color(0xFFD3A068);
      } else if (type == 'whale_shark') {
        color1 = const Color(0xFF212123);
        color2 = const Color(0xFF68C2D3);
      } else if (type == 'electric_eel') {
        color1 = const Color(0xFF212123);
        color2 = const Color(0xFF68C2D3);
      } else if (type == 'salmon') {
        color1 = const Color(0xFFD3A068);
        color2 = const Color(0xFFF2F0E5);
      } else {
        // puffer (default)
        color1 = const Color(0xFFEDE19E);
        color2 = const Color(0xFFD3A068);
      }
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
          if (type == 'electric_eel') {
            // 전기뱀장어 전류 흐르는 반짝임 효과
            final pulse = (sin(time * pi * 8) + 1.0) / 2.0;
            paint.color = Color.lerp(color2, Colors.white, pulse)!;
          } else {
            paint.color = color2;
          }
        } else if (pixels[y][x] == w) {
          paint.color = const Color(0xFFF2F0E5);
        } else if (pixels[y][x] == b) {
          paint.color = const Color(0xFF212123);
        } else if (pixels[y][x] == a) {
          paint.color = const Color(0xFF68C2D3);
        }

        double dx = 0.0;
        double dy = 0.0;

        if (type == 'jellyfish') {
          // 🪼 해파리: 촉수 부분(y >= 5)이 아래로 갈수록 좌우로 하늘하늘 흔들리며, 상단 우산(y < 5)은 위아래로 수축/이완
          if (y >= 5) {
            dx = sin(time * pi * 4 - y * 0.8) * (y - 4) * 0.2;
          } else {
            dy = -sin(time * pi * 2) * 0.15;
          }
        } else if (type == 'crab') {
          // 🦀 꽃게: 집게(x <= 3 또는 x >= 8, y <= 2)가 번갈아 움직이고 다리(y == 6)가 바쁘게 움직임
          if (y <= 2 && x <= 3) {
            dy = sin(time * pi * 4) * 0.4;
          } else if (y <= 2 && x >= 8) {
            dy = -sin(time * pi * 4) * 0.4;
          } else if (y == 6) {
            dx = sin(time * pi * 6 + x) * 0.4;
          }
        } else if (type == 'stingray') {
          // 🪽 가오리: 날개 플랩 모션 (양 끝 y <= 2 또는 y >= 5 부분이 우아하게 위아래로 펄럭임)
          if (y <= 2) {
            dy = sin(time * pi * 2.5 - x * 0.3) * (3 - y) * 0.3;
          } else if (y >= 5) {
            dy = -sin(time * pi * 2.5 - x * 0.3) * (y - 4) * 0.3;
          }
        } else if (type == 'electric_eel') {
          // ⚡ 전기뱀장어: S자로 몸 전체가 부드럽게 흔들림
          dy = sin(time * pi * 3 - x * 0.5) * 0.7;
        } else if (type == 'seahorse') {
          // 🐴 해마: 수직 기립 상태에서 뒷 지느러미(x <= 6, y >= 3 && y <= 5)를 매우 빠르게 흔들고 몸은 둥실둥실
          if (x <= 6 && y >= 3 && y <= 5) {
            dx = sin(time * pi * 12) * 0.8;
          } else {
            dy = sin(time * pi * 2) * 0.2;
          }
        } else if (type == 'turtle') {
          // 🐢 거북이: 다리(x <= 4 또는 x >= 9, y >= 5)를 패들링(둥글게 젓기)
          if ((x <= 4 || x >= 9) && y >= 5) {
            dx = sin(time * pi * 2.5) * 0.6;
            dy = cos(time * pi * 2.5) * 0.3;
          }
        } else if (type == 'puffer') {
          // 🐡 복어: 수축 팽창 모션을 제거하고 일반 물고기처럼 자연스러운 꼬리 치기 모션 적용
          if (x < 6) {
            dy = sin(time * pi * 2 - x * 0.4) * (6 - x) * 0.15;
          }
        } else if (type == 'whale' || type == 'whale_shark') {
          // 🐋 대형 어류: 대형 크기에 어울리게 꼬리를 느리고 묵직하게 흔들림
          if (x < 6) {
            dy = sin(time * pi - x * 0.3) * (6 - x) * 0.12;
          }
        } else {
          // 🐟 일반 물고기 (금붕어, 고등어, 상어, 베타, 니모, 구피, 아홀로틀, 참치, 새우, 비단잉어, 연어 등)
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
      oldDelegate.type != type ||
      oldDelegate.time != time ||
      oldDelegate.level != level;
}
