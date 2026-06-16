import 'dart:math';
import 'package:flutter/material.dart';
import '../bouncing_wrapper.dart';
import '../slot_machine.dart';
import '../pixel_fish.dart';
import '../pixel_seaweed.dart';
import '../pixel_emoji.dart';

class ShopScreen extends StatefulWidget {
  final int coins;
  final List<Map<String, dynamic>> ownedFishes;
  final List<Map<String, dynamic>> ownedSeaweeds;
  final void Function(Map<String, dynamic> fish) onAddFish;
  final void Function(Map<String, dynamic> seaweed) onAddSeaweed;
  final void Function(int cost, int amount) onBuyFeed;
  final void Function(int cost) onSpendCoin;
  final VoidCallback onNavigateToAquarium;

  const ShopScreen({
    super.key,
    required this.coins,
    required this.ownedFishes,
    required this.ownedSeaweeds,
    required this.onAddFish,
    required this.onAddSeaweed,
    required this.onBuyFeed,
    required this.onSpendCoin,
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

  // 공통 안내 팝업창
  void _showNoticeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '알림',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 슬롯머신이 끝나면 실행될 팝업창 로직
  void _showGachaResult(List<Map<String, dynamic>> drawnItems) {
    final bool isFish = _gachaMode == 'fish';
    final list = isFish ? widget.ownedFishes : widget.ownedSeaweeds;

    List<Map<String, dynamic>> processedResults = [];
    bool hasNew = false;

    for (var item in drawnItems) {
      final isDuplicate = list.any(
        (existing) => existing['type'] == item['type'],
      );
      processedResults.add({'item': item, 'isNew': !isDuplicate});

      if (!isDuplicate) {
        if (isFish) {
          widget.onAddFish(item);
        } else {
          widget.onAddSeaweed(item);
        }
        hasNew = true;
      }
    }

    if (hasNew) {
      _triggerFireworks(); // 🌟 새로운 아이템이 하나라도 있으면 폭죽 팡!
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showResultDialog(processedResults, isFish);
      });
    } else {
      _showResultDialog(processedResults, isFish);
    }
  }

  // 결과 다이얼로그 띄우기
  void _showResultDialog(List<Map<String, dynamic>> results, bool isFish) {
    final bool isSingle = results.length == 1;
    final bool hasAnyNew = results.any((r) => r['isNew'] == true);

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
                            hasAnyNew ? 'party' : 'sweat',
                            size: 24,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: isSingle
                            ? (hasAnyNew
                                  ? '야생의 ${isFish ? '물고기' : '수초'}가 나타났다!'
                                  : '이미 있는 ${isFish ? '물고기' : '수초'}예요!')
                            : (hasAnyNew
                                  ? '새로운 친구들을 획득했다!'
                                  : '모두 이미 있는 친구들이네요..'),
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
                if (isSingle)
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
                              type:
                                  results[0]['item']['type']?.toString() ??
                                  'puffer',
                              isAnimated: false,
                            )
                          : PixelSeaweed(
                              type:
                                  results[0]['item']['type']?.toString() ??
                                  'green_algae',
                              isAnimated: false,
                            ),
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: results.map((r) {
                          final item = r['item'];
                          final isNew = r['isNew'] as bool;
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isNew
                                  ? Colors.lightBlueAccent.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.grey[200],
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isFish
                                    ? PixelFish(
                                        type: item['type'],
                                        isAnimated: false,
                                      )
                                    : PixelSeaweed(
                                        type: item['type'],
                                        isAnimated: false,
                                      ),
                                const SizedBox(height: 4),
                                Text(
                                  isNew ? 'NEW' : '중복',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: isNew
                                        ? Colors.redAccent
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  isSingle
                      ? (hasAnyNew
                            ? '[${results[0]['item']['name']}] 가 당첨되었습니다!\n보관함에서 확인해보세요.'
                            : '[${results[0]['item']['name']}] 은(는) 이미 보관함에 있습니다!\n아쉽지만 다음 기회를 노려보세요.')
                      : (hasAnyNew
                            ? '새로운 ${isFish ? '물고기' : '수초'}를 획득했습니다!\n보관함에서 확인해보세요.'
                            : '전부 이미 보유 중인 ${isFish ? '물고기' : '수초'}입니다.\n아쉽지만 다음 기회를 노려보세요.'),
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
                    if (hasAnyNew) ...[
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

  // --- 먹이 상점 화면 UI ---
  Widget _buildFeedShop() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '먹이 상점',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const PixelEmoji('meat', size: 64),
          const SizedBox(height: 40),
          _buildBuyFeedButton('일반 먹이 10개', 1, 10),
        ],
      ),
    );
  }

  Widget _buildBuyFeedButton(String title, int cost, int amount) {
    return BouncingWrapper(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 4),
            borderRadius: BorderRadius.zero,
          ),
        ),
        onPressed: () => _confirmBuyFeed(title, cost, amount),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            const PixelEmoji('coin', size: 16),
            const SizedBox(width: 4),
            Text(
              '$cost',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBuyFeed(String title, int cost, int amount) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '구매 확인',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '$title\n정말 $cost코인으로 구매하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.coins >= cost) {
                            widget.onBuyFeed(cost, amount);
                            _showNoticeDialog('먹이 구매 완료! 🍗');
                          } else {
                            _showNoticeDialog('코인이 부족합니다! 🪙');
                          }
                        },
                        child: const Text(
                          '구매',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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
                            Expanded(
                              child: _buildShopItem(
                                '먹이 상점',
                                const PixelEmoji('meat', size: 36),
                                Colors.redAccent,
                                () => setState(() => _gachaMode = 'feed'),
                              ),
                            ),
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
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              offset: _gachaMode != 'none'
                  ? Offset.zero
                  : const Offset(1.0, 0.0), // 💡 오른쪽에서 슬라이드로 등장
              curve: Curves.easeInOutCubic,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFFFF0F5),
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: [
                        if (_gachaMode == 'fish' || _gachaMode == 'seaweed')
                          SlotMachine(
                            gachaType: _gachaMode,
                            onDrawDone: _showGachaResult,
                            onSpinStart: (cost) {
                              if (widget.coins >= cost) {
                                widget.onSpendCoin(cost);
                                return true;
                              } else {
                                _showNoticeDialog('코인이 부족합니다! 🪙');
                                return false;
                              }
                            },
                          ),
                        if (_gachaMode == 'feed') _buildFeedShop(),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: BouncingWrapper(
                              showShadow: true,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _gachaMode = 'none'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Text(
                                    '< 뒤로',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
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
