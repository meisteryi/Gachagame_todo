import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/aquarium_screen.dart';
import 'screens/todo_screen.dart';
import 'pixel_fish.dart';
import 'slot_machine.dart';

void main() {
  runApp(const GachaTodoApp());
}

class GachaTodoApp extends StatelessWidget {
  const GachaTodoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gacha Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _ownedFishes = [];
  String _swimmingFishType = 'puffer'; // 수조에서 헤엄치는 기본 물고기

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

    // 슬롯머신 주변 여러 위치에서 폭죽이 터지도록 3개의 그룹 생성
    for (int j = 0; j < 3; j++) {
      final offsetX = (random.nextDouble() - 0.5) * 200; // 중심 기준 X 분산
      final offsetY = (random.nextDouble() - 0.5) * 200 - 50; // 중심 기준 Y 분산

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
    _fireworksController?.forward(from: 0); // 애니메이션 0부터 재생
  }

  // 탭 변경 시 상태를 업데이트하여 화면을 다시 그리도록 함
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 슬롯머신이 끝나면 실행될 팝업창
  void _showGachaResult(Map<String, dynamic> drawnFish) {
    // 1. 중복 여부 확인
    final bool isDuplicate = _ownedFishes.any(
      (fish) => fish['type'] == drawnFish['type'],
    );

    // 2. 중복이 아닐 때의 로직 처리 (보관함 추가 및 폭죽)
    if (!isDuplicate) {
      setState(() {
        _ownedFishes.add(drawnFish);
      });
      _triggerFireworks(); // 🌟 도트 폭죽 팡!

      // 폭죽을 잠시 감상할 수 있도록 팝업창을 1.2초 늦게 띄움
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showResultDialog(drawnFish, isDuplicate);
      });
    } else {
      // 중복일 경우는 지체 없이 바로 팝업창 띄움
      _showResultDialog(drawnFish, isDuplicate);
    }
  }

  // 결과 다이얼로그 띄우기
  void _showResultDialog(Map<String, dynamic> drawnFish, bool isDuplicate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isDuplicate ? '😅 앗, 이미 있는 물고기예요!' : '🎉 앗! 야생의 물고기가 나타났다!',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Transform.scale(
                scale: 1.5,
                child: PixelFish(
                  type: drawnFish['type']?.toString() ?? 'puffer',
                ),
              ), // 도트 물고기 원본 출력!
              const SizedBox(height: 30),
              Text(
                isDuplicate
                    ? '[${drawnFish['name']}] 은(는) 이미 보관함에 있습니다!\n아쉽지만 다음 기회를 노려보세요.'
                    : '[${drawnFish['name']}] 가 당첨되었습니다!\n보관함에서 물고기를 선택해 수조에 넣어보세요.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 팝업 닫기
              child: const Text('닫기'),
            ),
            if (!isDuplicate) // 중복이 아닐 때만 보관함 이동 버튼 표시
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  setState(() {
                    _selectedIndex = 0; // 1. 내 수조 탭으로 즉시 이동
                  });
                  // 2. 탭 전환이 완료된 후 약간의 딜레이를 두고 보관함(바텀 시트) 열기
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) _showFishStorage();
                  });
                },
                child: const Text('보관함으로 가기'),
              ),
          ],
        );
      },
    );
  }

  // 물고기 보관함 열기
  void _showFishStorage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 화면 비율에 따라 높이를 조정할 수 있게 허용
      builder: (context) {
        // SafeArea 추가: 아이폰 하단 홈 바에 UI가 가려지지 않도록 보호
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            height:
                MediaQuery.of(context).size.height *
                0.5, // 400 고정값 대신 기기 높이의 50% 사용
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🐟 내 물고기 보관함',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ownedFishes.isEmpty
                      ? const Center(
                          child: Text(
                            '아직 뽑은 물고기가 없어요!\n가챠 샵에서 물고기를 뽑아보세요.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: _ownedFishes.length,
                          itemBuilder: (context, index) {
                            final fish = _ownedFishes[index];
                            return Card(
                              elevation: 2,
                              clipBehavior: Clip
                                  .antiAlias, // 버튼 클릭 시 물결 효과가 네모를 안 넘어가게 잘라줌
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _swimmingFishType =
                                        fish['type']?.toString() ??
                                        'puffer'; // 1. 수조 물고기 변경
                                    _selectedIndex = 0; // 2. 수조 탭으로 이동
                                  });
                                  Navigator.of(context).pop(); // 3. 보관함 닫기
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: PixelFish(
                                        type:
                                            fish['type']?.toString() ??
                                            'puffer',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      fish['name']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48, // 상단바 두께 축소 (기본값 56)
        title: const Text(
          '가챠 투두 🎲',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 개발용 보관함 초기화 버튼
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: '보관함 초기화 (개발용)',
            onPressed: () {
              setState(() {
                _ownedFishes.clear();
                _swimmingFishType = 'puffer'; // 수조 물고기도 기본으로 초기화
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('보관함이 초기화되었습니다. (개발용)')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 1. 내 수조 탭 (전체 화면)
          AquariumScreen(
            swimmingFishType: _swimmingFishType,
            onShowStorage: _showFishStorage,
          ),
          // 2. 할 일 탭 (전체 화면)
          const TodoScreen(),
          // 3. 가챠 샵 탭 (전체 화면 + 폭죽 오버레이)
          Stack(
            children: [
              Container(
                color: const Color(0xFFFFF0F5), // 연한 핑크색 배경
                width: double.infinity,
                height: double.infinity,
                child: SlotMachine(onDrawDone: _showGachaResult),
              ),
              // 폭죽 애니메이션이 실행 중일 때만 그리기
              if (_fireworksController?.isAnimating == true)
                Positioned.fill(
                  child: IgnorePointer(
                    // 클릭 이벤트를 슬롯머신으로 통과시킴
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
        ],
      ),
      // 3. 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.sailing), label: '내 수조'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: '할 일'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: '가챠 샵'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
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
      // 시간(progress)에 따른 파티클 위치 계산 및 중력(떨어짐) 효과 적용
      double currentX = center.dx + p.startX + (p.vx * progress * 1.5);
      double currentY =
          center.dy +
          p.startY +
          (p.vy * progress * 1.5) +
          (250 * progress * progress);

      // 시간이 지날수록 점점 투명해지도록 설정
      paint.color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));

      // 도트 느낌을 살리기 위해 정사각형 픽셀 모양(8x8)으로 그림
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
