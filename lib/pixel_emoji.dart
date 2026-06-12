import 'package:flutter/material.dart';

// --- 모든 기기에서 동일하게 보이는 수제 도트 이모지 ---
class PixelEmoji extends StatelessWidget {
  final String name;
  final double size;

  const PixelEmoji(this.name, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelEmojiPainter(name),
    );
  }
}

class _PixelEmojiPainter extends CustomPainter {
  final String name;
  _PixelEmojiPainter(this.name);

  @override
  void paint(Canvas canvas, Size size) {
    // 💡 8x8 픽셀 배열 (각 알파벳이 색상을 의미함)
    final Map<String, List<String>> emojiData = {
      'coin': [
        // 🪙 코인
        '..yyyy..',
        '.ywyyyy.',
        '.woooyy.',
        '.yoooyy.',
        '.yooooy.',
        '.yyoooy.',
        '..yyyy..',
        '........',
      ],
      'box': [
        // 📦 보관함
        '........',
        '.mmmmmm.',
        'mddddddm',
        'mmmmmmmm',
        'mdmmmmdm',
        'mdmmmmdm',
        'mmmmmmmm',
        '.mmmmmm.',
      ],
      'meat': [
        // 🍗 고기(먹이)
        '......ww',
        '.....www',
        '.....mw.',
        '...rmm..',
        '..rrmm..',
        '.rrrrm..',
        'rrrrr...',
        'rr......',
      ],
      'fish': [
        // 🐟 물고기
        '........',
        '........',
        '..bb....',
        'bcccbbbb',
        'bbccckwb',
        '.bbcccb.',
        '...bbb..',
        '........',
      ],
      'seaweed': [
        // 🌱 수초
        '......l.',
        '.....ll.',
        '....gl..',
        '.ll.g...',
        '..llg...',
        '...lg...',
        '....g...',
        '....g...',
      ],
      'memo': [
        // 📝 메모(할 일)
        '..wwww..',
        '..wssw..',
        '..wwwwpp',
        '..wsswdp',
        '..wwwwpp',
        '..wsww..',
        '..wwww..',
        '........',
      ],
      'bell': [
        // 🔔 알림 종
        '....yy..',
        '...yyyy.',
        '...yyyy.',
        '..yyyyyy',
        '..yooooy',
        '.yyyyyyyy',
        '...dddd.',
        '........',
      ],
      'tag': [
        // 🏷️ 카테고리 태그
        '...r....',
        '....r...',
        '...ttt..',
        '..ttdtt.',
        '..ttttt.',
        '...ttt..',
        '....t...',
        '........',
      ],
      'trophy': [
        // 🏆 트로피
        'yyyyyyyy',
        '.yyyyyy.',
        '..yyyy..',
        '...oo...',
        '...yy...',
        '..yyyy..',
        '.yyyyyy.',
        'oooooooo',
      ],
      'sweat': [
        // 😅 당황한 땀
        '..yyyy..',
        '.yyyyyy.',
        'ykyykyy.',
        'yyyyyyyc',
        'ykkkkyyc',
        'yyyyyyy.',
        '.yyyyy..',
        '........',
      ],
      'party': [
        // 🎉 폭죽
        '...b.y..',
        '..g...r.',
        '....y...',
        '...rr...',
        '..rrr...',
        '.rrr....',
        'rrr.....',
        'r.......',
      ],
    };

    // 💡 픽셀 색상 팔레트
    final Map<String, Color> colors = {
      '.': Colors.transparent,
      'y': Colors.yellowAccent,
      'w': Colors.white,
      'o': Colors.orangeAccent,
      'b': Colors.blueAccent,
      'c': Colors.lightBlueAccent,
      'd': Colors.brown[800]!,
      'm': Colors.brown[400]!,
      'r': Colors.redAccent,
      'g': Colors.green,
      'l': Colors.lightGreen,
      'p': Colors.yellow[700]!,
      'k': Colors.black,
      't': Colors.orange[200]!,
      's': Colors.grey,
    };

    final List<String> data = emojiData[name] ?? emojiData['coin']!;
    final double pw = size.width / 8;
    final double ph = size.height / 8;
    final paint = Paint();

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final char = data[y][x];
        if (char != '.') {
          paint.color = colors[char]!;
          canvas.drawRect(Rect.fromLTWH(x * pw, y * ph, pw, ph), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
