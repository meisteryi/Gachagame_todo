import 'dart:math';
import 'package:flutter/material.dart';
import '../bouncing_wrapper.dart';
import '../slot_machine.dart';
import '../pixel_fish.dart';
import '../pixel_seaweed.dart';
import '../pixel_emoji.dart';

class ShopScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ownedFishes;
  final List<Map<String, dynamic>> ownedSeaweeds;
  final void Function(Map<String, dynamic> fish) onAddFish;
  final void Function(Map<String, dynamic> seaweed) onAddSeaweed;
  final VoidCallback onNavigateToAquarium;

  const ShopScreen({
    super.key,
    required this.ownedFishes,
    required this.ownedSeaweeds,
    required this.onAddFish,
    required this.onAddSeaweed,
    required this.onNavigateToAquarium,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  String _gachaMode = 'none'; // 'none', 'fish', 'seaweed'

  // 폭죽 애니메이션 컨트롤러 및 파티클 리스트
  AnimationController? _fireworksController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _fireworksController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..addListener(() {
          setState(() {}); // 폭죽이 터지는 동안 매 프레임 화면 갱신
        });
  }

  @override
  void dispose() {
    _fireworksController?.dispose();
    super.dispose();
  }

  // 폭죽 파티클 생성 및 애니메이션 시작
  void _triggerFireworks() {
    final random = Random();
    _particles.clear();
    final colors = [
      Colors.redAccent,
      Colors.yellowAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
    ];

    for (int j = 0; j < 3; j++) {
      final offsetX = (random.nextDouble() - 0.5) * 200;
      final offsetY = (random.nextDouble() - 0.5) * 200 - 50;

      for (int i = 0; i < 40; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = random.nextDouble() * 200 + 50;
        _particles.add(
          Particle(
            startX: offsetX,
            startY: offsetY,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            color: colors[random.nextInt(colors.length)],
          ),
        );
      }
    }
    _fireworksController?.forward(from: 0);
  }

  // 슬롯머신이 끝나면 실행될 팝업창 로직
  void _showGachaResult(Map<String, dynamic> drawnItem) {
    final bool isFish = _gachaMode == 'fish';
    final list = isFish ? widget.ownedFishes : widget.ownedSeaweeds;

    final bool isDuplicate = list.any(
      (item) => item['type'] == drawnItem['type'],
    );

    if (!isDuplicate) {
      if (isFish) {
        widget.onAddFish(drawnItem);
      } else {
        widget.onAddSeaweed(drawnItem);
      }
      _triggerFireworks(); // 🌟 도트 폭죽 팡!

      // 폭죽을 잠시 감상할 수 있도록 팝업창을 1.2초 늦게 띄움
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showResultDialog(drawnItem, isDuplicate, isFish);
      });
    } else {
      // 중복일 경우는 지체 없이 바로 팝업창 띄움
      _showResultDialog(drawnItem, isDuplicate, isFish);
    }
  }

  // 결과 다이얼로그 띄우기
  void _showResultDialog(
    Map<String, dynamic> drawnItem,
    bool isDuplicate,
    bool isFish,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(6, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: PixelEmoji(
                            isDuplicate ? 'sweat' : 'party',
                            size: 24,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: isDuplicate
                            ? '이미 있는 ${isFish ? '물고기' : '수초'}예요!'
                            : '야생의 ${isFish ? '물고기' : '수초'}가 나타났다!',
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Transform.scale(
                    scale: 1.5,
                    child: isFish
                        ? PixelFish(
                            type: drawnItem['type']?.toString() ?? 'puffer',
                          )
                        : PixelSeaweed(
                            type:
                                drawnItem['type']?.toString() ?? 'green_algae',
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isDuplicate
                      ? '[${drawnItem['name']}] 은(는) 이미 보관함에 있습니다!\n아쉽지만 다음 기회를 노려보세요.'
                      : '[${drawnItem['name']}] 가 당첨되었습니다!\n보관함에서 ${isFish ? '물고기' : '수초'}를 선택해 수조에 넣어보세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: BouncingWrapper(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black, width: 3),
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              '닫기',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isDuplicate) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: BouncingWrapper(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.black,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(
                                  () => _gachaMode = 'none',
                                ); // 가챠 화면 초기화
                                widget
                                    .onNavigateToAquarium(); // 메인 화면에 수조 탭으로 이동 요청
                              },
                              child: const Text(
                                '보관함 가기',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 상점 6분할 개별 버튼
  Widget _buildShopItem(
    String title,
    Widget icon,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return BouncingWrapper(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 잠긴 상점 버튼
  Widget _buildEmptyShopItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[400]!, width: 4),
      ),
      child: const Center(
        child: Icon(Icons.lock, color: Colors.grey, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- 1. 상점 메인 화면 (배경에 항상 고정) ---
        Container(
          color: const Color(0xFFFFF0F5),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 50),
              Stack(
                children: [
                  Text(
                    'ITEM SHOP',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 6
                        ..color = Colors.black,
                    ),
                  ),
                  const Text(
                    'ITEM SHOP',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.yellowAccent,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(4, 4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildShopItem(
                                '물고기 뽑기',
                                const PixelEmoji('fish', size: 36),
                                Colors.orangeAccent,
                                () => setState(() => _gachaMode = 'fish'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildShopItem(
                                '수초 뽑기',
                                const PixelEmoji('seaweed', size: 36),
                                Colors.greenAccent,
                                () => setState(() => _gachaMode = 'seaweed'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildEmptyShopItem()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEmptyShopItem()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildEmptyShopItem()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEmptyShopItem()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // --- 2. 가챠 화면 오버레이 (버튼 위치에서 확실하게 튀어나오고 들어감) ---
        IgnorePointer(
          ignoring: _gachaMode == 'none',
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350), // 애니메이션 속도 경쾌하게 조절
            opacity: _gachaMode != 'none' ? 1.0 : 0.0,
            curve: Curves.easeInOutCubic,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 350),
              scale: _gachaMode != 'none' ? 1.0 : 0.15,
              alignment: _gachaMode == 'fish'
                  ? const Alignment(-0.5, -0.3)
                  : const Alignment(0.5, -0.3), // 💡 선택한 가챠 종류에 따라 튀어나오는 위치 변경
              curve: Curves.easeInOutCubic,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFFFF0F5),
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: [
                        if (_gachaMode != 'none')
                          SlotMachine(
                            gachaType: _gachaMode,
                            onDrawDone: _showGachaResult,
                          ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: BouncingWrapper(
                              showShadow: false,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 28,
                                ),
                                onPressed: () =>
                                    setState(() => _gachaMode = 'none'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_fireworksController?.isAnimating == true)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: PixelFireworksPainter(
                            _fireworksController!.value,
                            _particles,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 🌟 2D 도트 폭죽 효과를 위한 파티클 및 페인터 🌟 ---
class Particle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final Color color;

  Particle({
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.color,
  });
}

class PixelFireworksPainter extends CustomPainter {
  final double progress;
  final List<Particle> particles;

  PixelFireworksPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    for (var p in particles) {
      double currentX = center.dx + p.startX + (p.vx * progress * 1.5);
      double currentY =
          center.dy +
          p.startY +
          (p.vy * progress * 1.5) +
          (250 * progress * progress);

      paint.color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(currentX, currentY),
          width: 8,
          height: 8,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PixelFireworksPainter oldDelegate) => true;
}
