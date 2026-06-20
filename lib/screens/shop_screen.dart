import 'dart:math';
import 'package:flutter/material.dart';
import '../bouncing_wrapper.dart';
import '../slot_machine.dart';
import '../pixel_fish.dart';
import '../pixel_seaweed.dart';
import '../pixel_decoration.dart';
import '../pixel_emoji.dart';
import '../pixel_supplement.dart';
import '../translations.dart';

class ShopScreen extends StatefulWidget {
  final int coins;
  final List<Map<String, dynamic>> ownedFishes;
  final List<Map<String, dynamic>> ownedSeaweeds;
  final void Function(Map<String, dynamic> fish) onAddFish;
  final void Function(Map<String, dynamic> seaweed) onAddSeaweed;
  final void Function(Map<String, dynamic> deco) onAddDeco;
  final void Function(String type, int cost, int amount) onBuyItem;
  final void Function(int cost) onSpendCoin;
  final VoidCallback onNavigateToAquarium;

  const ShopScreen({
    super.key,
    required this.coins,
    required this.ownedFishes,
    required this.ownedSeaweeds,
    required this.onAddFish,
    required this.onAddSeaweed,
    required this.onAddDeco,
    required this.onBuyItem,
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
      const Color(0xFFFFB7B2),
      const Color(0xFFFFF3B0),
      const Color(0xFFB4D8E7),
      const Color(0xFFA8E6CF),
      const Color(0xFFFFC6D3),
      const Color(0xFFFFDAB9),
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
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '알림'.tr,
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
                  child: RetroGradientButton(
                    color: Colors.grey[300]!,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '닫기'.tr,
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

    String titleKey = isSingle
        ? (hasAnyNew
              ? (isFish ? '야생의 물고기가 나타났다!' : '야생의 수초가 나타났다!')
              : (isFish ? '이미 있는 물고기예요!' : '이미 있는 수초예요!'))
        : (hasAnyNew ? '새로운 친구들을 획득했다!' : '모두 이미 있는 친구들이네요..');

    String msgKey = isSingle
        ? (hasAnyNew
              ? '[%s] 가 당첨되었습니다!\n보관함에서 확인해보세요.'
              : '[%s] 은(는) 이미 보관함에 있습니다!\n아쉽지만 다음 기회를 노려보세요.')
        : (hasAnyNew
              ? '새로운 %s를 획득했습니다!\n보관함에서 확인해보세요.'
              : '전부 이미 보유 중인 %s입니다.\n아쉽지만 다음 기회를 노려보세요.');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(3, 3)),
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
                        text: titleKey.tr, // 💡 제목 번역
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
                      borderRadius: BorderRadius.circular(4),
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
                              borderRadius: BorderRadius.circular(4),
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
                                  isNew ? 'NEW' : '중복'.tr, // 💡 중복 텍스트 번역
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: isNew
                                        ? const Color(0xFFFFB7B2)
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
                  msgKey.trArgs([
                    isSingle
                        ? (results[0]['item']['name']?.toString() ?? '')
                              .tr // 💡 번역된 이름 주입
                        : (isFish ? '물고기'.tr : '수초'.tr),
                  ]),
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
                          child: RetroGradientButton(
                            color: Colors.grey[300]!,
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '닫기'.tr,
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
                            child: RetroGradientButton(
                              color: const Color(0xFFFFB7B2),
                              foregroundColor: Colors.white,
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(
                                  () => _gachaMode = 'none',
                                ); // 가챠 화면 초기화
                                widget
                                    .onNavigateToAquarium(); // 메인 화면에 수조 탭으로 이동 요청
                              },
                              child: Text(
                                '보관함 가기'.tr,
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
  // --- 장식물 상점 ---
  Widget _buildDecoShop() {
    final decos = [
      {'type': 'ammonite',      'name': '\uc554\ubaa8\ub098\uc774\ud2b8 \ud654\uc11d',  'color': const Color(0xFFBF8C3A)},
      {'type': 'basalt',        'name': '\ud070 \ud604\ubb34\uc554',      'color': const Color(0xFF606060)},
      {'type': 'spongebob_house','name': '\uc2a4\ud3f0\uc9c0\ubc25 \uc9d1',   'color': const Color(0xFFD4841A)},
      {'type': 'sunken_ship',   'name': '\uce68\ubab0\ud55c \ubc30 \uc783\ud574', 'color': const Color(0xFF8B6340)},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Text(
              '\uc7a5\uc2dd\ubb3c \uc0c1\uc810',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              '\uc218\uc870\ub97c \ub354 \uc544\ub984\ub2f5\uac8c \uaf43\ubc14\uacc4\uc694!',
              style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...decos.map((deco) {
              final Color col = deco['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BouncingWrapper(
                  child: RetroGradientButton(
                    color: col,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    borderRadius: BorderRadius.circular(6),
                    borderWidth: 2,
                    onPressed: () => _confirmBuyDeco(
                      deco['name'] as String,
                      deco['type'] as String,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Center(
                            child: PixelDecoration(
                              type: deco['type'] as String,
                              isAnimated: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deco['name'] as String,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const PixelEmoji('coin', size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '5',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmBuyDeco(String name, String type) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Color(0xFF333333), offset: Offset(3, 3))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\uad6c\ub9e4 \ud655\uc778', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                '$name\n\ucf54\uc778 5\uac1c\ub97c \uc0ac\uc6a9\ud558\uc2dc\uaca0\uc2b5\ub2c8\uae4c?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: RetroGradientButton(
                    color: Colors.grey[300]!,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('\ucde8\uc18c', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RetroGradientButton(
                    color: const Color(0xFFD4C4A0),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.coins >= 5) {
                        widget.onSpendCoin(5);
                        widget.onAddDeco({'type': type, 'name': name});
                        _showNoticeDialog('\uad6c\ub9e4 \uc644\ub8cc! \ub0b4 \ubcf4\uad00\ud568\uc5d0 \ucd94\uac00\ub418\uc5c8\uc2b5\ub2c8\ub2e4 \ud83c\udf89');
                      } else {
                        _showNoticeDialog('\ucf54\uc778\uc774 \ubd80\uc871\ud569\ub2c8\ub2e4! \ud83e\ude99');
                      }
                    },
                    child: const Text('\uad6c\ub9e4', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedShop() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '먹이 및 영양제 상점'.tr,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelEmoji('meat', size: 56),
              SizedBox(width: 20),
              PixelSupplement(size: 56),
            ],
          ),
          const SizedBox(height: 40),
          _buildBuyItemButton(
            '일반 먹이 5개'.tr,
            'feed',
            1,
            5,
            const Color(0xFFFFDAB9),
            const PixelEmoji('meat', size: 16),
          ),
          const SizedBox(height: 16),
          _buildBuyItemButton(
            '영양제 1개'.tr,
            'supplement',
            1,
            1,
            const Color(0xFFA8E6CF),
            const PixelSupplement(size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyItemButton(
    String title,
    String type,
    int cost,
    int amount,
    Color bgColor,
    Widget icon,
  ) {
    return BouncingWrapper(
      child: RetroGradientButton(
        color: bgColor,
        foregroundColor: type == 'feed' ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: BorderRadius.circular(12),
        borderWidth: 1.5,
        onPressed: () => _confirmBuyItem(title, type, cost, amount),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
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

  void _confirmBuyItem(String title, String type, int cost, int amount) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '구매 확인'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '%s\n정말 %s코인으로 구매하시겠습니까?'.trArgs([
                    title,
                    cost.toString(),
                  ]), // 💡 구매 확인 메시지 번역
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: RetroGradientButton(
                        color: Colors.grey[300]!,
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소'.tr,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RetroGradientButton(
                        color: const Color(0xFFA8E6CF),
                        onPressed: () {
                          Navigator.pop(context);
                          if (widget.coins >= cost) {
                            widget.onBuyItem(type, cost, amount);
                            _showNoticeDialog('구매가 완료되었습니다! 🎉'.tr);
                          } else {
                            _showNoticeDialog('코인이 부족합니다! 🪙'.tr);
                          }
                        },
                        child: Text(
                          '구매'.tr,
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
            gradient: getRetroGradient(bgColor),
            borderRadius: BorderRadius.circular(4),
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
                  shadows: [
                    Shadow(color: Color(0xFF333333), offset: Offset(2, 2)),
                  ],
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
        gradient: getRetroGradient(Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFDF9),
                Color(0xFFF2EBE1),
              ], // 💡 아주 옅은 웜톤 그라데이션
            ),
          ),
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
                        ..strokeWidth = 3
                        ..color = const Color(0xFF333333),
                    ),
                  ),
                  const Text(
                    'ITEM SHOP',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFFFFF3B0),
                      shadows: [
                        Shadow(color: Color(0xFF333333), offset: Offset(2, 2)),
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
                                '물고기 뽑기'.tr,
                                const PixelEmoji('fish', size: 36),
                                const Color(0xFFFFDAB9),
                                () => setState(() => _gachaMode = 'fish'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildShopItem(
                                '수초 뽑기'.tr,
                                const PixelEmoji('seaweed', size: 36),
                                const Color(0xFFA8E6CF),
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
                                '먹이 및\n영양제 상점'.tr,
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PixelEmoji('meat', size: 32),
                                    SizedBox(width: 8),
                                    PixelSupplement(size: 32),
                                  ],
                                ),
                                const Color(0xFFFFB7B2),
                                () => setState(() => _gachaMode = 'feed'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildShopItem(
                                '장식물 상점',
                                const PixelDecoration(type: 'ammonite', isAnimated: false),
                                const Color(0xFFD4C4A0),
                                () => setState(() => _gachaMode = 'deco'),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFDF9),
                          Color(0xFFF2EBE1),
                        ], // 💡 오버레이도 동일한 그라데이션 적용
                      ),
                    ),
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
                        if (_gachaMode == 'deco') _buildDecoShop(),
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
                                    gradient: getRetroGradient(Colors.white),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '< 뒤로'.tr,
                                    style: const TextStyle(
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
