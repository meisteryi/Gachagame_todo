import 'package:flutter/material.dart';
import 'theme_manager.dart';

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
      'calendar': [
        // 📅 달력
        '.s.ss.s.',
        'rrrrrrrr',
        'wwwwwwww',
        'wkwkkwkw',
        'wwwwwwww',
        'wkwkkwkw',
        'wwwwwwww',
        '........',
      ],
      'routine': [
        // 🔁 루틴(순환 화살표)
        '..kkkk..',
        '.k....k.',
        'k...k..k',
        'k..kkk.k',
        'k...k..k',
        'k......k',
        '.k....k.',
        '..kkkk..',
      ],
      'plus': [
        // ➕ 플러스(할 일 추가)
        '........',
        '...kk...',
        '...kk...',
        '.kkkkkk.',
        '.kkkkkk.',
        '...kk...',
        '...kk...',
        '........',
      ],
      'shapes': [
        // 🔺 카테고리 도형 (네모, 동그라미, 세모)
        '.rr...b.',
        '.rr..bbb',
        '.....bbb',
        '......b.',
        '...g....',
        '..ggg...',
        '.ggggg..',
        '........',
      ],
      'mood_great': [
        // 🥰 기분 최고 (머리 옆에 하트가 떠 있는 웃는 표정)
        'r.r.yyy.',
        'rrryyyyy',
        '.r.ykyky',
        '...yyyyy',
        '...ykyky',
        '...yykky',
        '....yyy.',
        '........',
      ],
      'mood_good': [
        // 😄 기분 좋음
        '..yyyy..',
        '.yyyyyy.',
        'ykyykyyy',
        'yyyyyyyy',
        'ykyykyyy',
        'yykkyyyy',
        '.yyyyyy.',
        '........',
      ],
      'mood_normal': [
        // 😐 기분 보통
        '..yyyy..',
        '.yyyyyy.',
        'ykyykyyy',
        'yyyyyyyy',
        'ykkkkyyy',
        'yyyyyyyy',
        '.yyyyyy.',
        '........',
      ],
      'mood_bad': [
        // ☹️ 기분 나쁨
        '..yyyy..',
        '.yyyyyy.',
        'ykyykyyy',
        'yyyyyyyy',
        'yykkyyyy',
        'ykyykyyy',
        '.yyyyyy.',
        '........',
      ],
      'pencil': [
        // ✏️ 연일 도트 이모지 (8x8)
        '......yy',
        '.....yoy',
        '....yoy.',
        '...yoy..',
        '..yoy...',
        '.yky....',
        'kk......',
        '........',
      ],
      'check': [
        // ✔️ 체크 도트 이모지 (8x8)
        '.......g',
        '......gg',
        '.....gg.',
        'g...gg..',
        'gg.gg...',
        'gggg....',
        '.gg.....',
        '........',
      ],
      'chart': [
        // 📊 바 차트 (통계)
        '......b.',
        '......b.',
        '....g.b.',
        '....g.b.',
        '..r.g.b.',
        '..r.g.b.',
        '..r.g.b.',
        '........',
      ],
      'gear': [
        // ⚙️ 톱니바퀴 (설정)
        '..s..s..',
        '.ssssss.',
        's.ssss.s',
        '.ss..ss.',
        '.ss..ss.',
        's.ssss.s',
        '.ssssss.',
        '..s..s..',
      ],
    };

    // 💡 픽셀 색상 팔레트
    final Map<String, Color> colors = AppTheme.emojiColors;

    final List<String> data = emojiData[name] ?? emojiData['coin']!;
    final double pw = size.width / 8;
    final double ph = size.height / 8;
    final paint = Paint();
    final outlinePaint = Paint()..color = AppTheme.borderColor;

    // 💡 1px 실선이 아닌, 영양제와 완벽하게 일치하는 픽셀 단위의 두꺼운 레트로 외곽선을 그립니다.
    final outlineOffsets = [
      Offset(-pw, 0),
      Offset(pw, 0),
      Offset(0, -ph),
      Offset(0, ph),
    ];

    // 1. 얇은 테두리(외곽선) 그리기 (플러스 아이콘은 외곽선 제외하여 얇고 선명하게 유지)
    if (name != 'plus') {
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final char = data[y][x];
          if (char != '.') {
            for (var offset in outlineOffsets) {
              canvas.drawRect(
                Rect.fromLTWH(x * pw + offset.dx, y * ph + offset.dy, pw, ph),
                outlinePaint,
              );
            }
          }
        }
      }
    }

    // 2. 내부 픽셀 그리기
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
