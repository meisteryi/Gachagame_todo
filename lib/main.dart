import 'dart:math';
import 'package:flutter/material.dart';
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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  AnimationController? _fishController;

  // 할 일 데이터 상태 관리 (임시 데이터)
  final List<Map<String, dynamic>> _todoList = [
    {'task': '대충 세운 계획 1', 'isDone': false},
    {'task': '대충 세운 계획 2', 'isDone': false},
    {'task': '대충 세운 계획 3', 'isDone': false},
  ];

  final List<Map<String, dynamic>> _ownedFishes = [];
  String _swimmingFishType = 'puffer'; // 수조에서 헤엄치는 기본 물고기

  @override
  void initState() {
    super.initState();
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(); // 15초 주기로 5가지 모션을 수행하며 무한 반복
  }

  @override
  void dispose() {
    _fishController?.dispose();
    super.dispose();
  }

  // 탭 변경 시 상태를 업데이트하여 화면을 다시 그리도록 함
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 체크박스 클릭 시 상태 업데이트
  void _toggleTodo(int index, bool? value) {
    setState(() {
      _todoList[index]['isDone'] = value ?? false;
    });
  }

  // 슬롯머신이 끝나면 실행될 팝업창
  void _showGachaResult(Map<String, dynamic> drawnFish) {
    // 1. 중복 여부 확인
    final bool isDuplicate = _ownedFishes.any(
      (fish) => fish['type'] == drawnFish['type'],
    );

    // 2. 중복이 아닐 때만 보관함에 추가
    if (!isDuplicate) {
      setState(() {
        _ownedFishes.add(drawnFish);
      });
    }

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
                child: PixelFish(type: drawnFish['type']),
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
                  _showFishStorage(); // 보관함 열기
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
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
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
                            clipBehavior:
                                Clip.antiAlias, // 버튼 클릭 시 물결 효과가 네모를 안 넘어가게 잘라줌
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _swimmingFishType =
                                      fish['type']; // 1. 수조 물고기 변경
                                  _selectedIndex = 0; // 2. 수조 탭으로 이동
                                });
                                Navigator.of(context).pop(); // 3. 보관함 닫기
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: PixelFish(type: fish['type']),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    fish['name'],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15), // 어항 속 물 느낌
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white54, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        26,
                      ), // 테두리 밖으로 물고기가 나가지 않게 자름
                      child: Stack(
                        children: [
                          // 어항 유리 반사광 장식 (디테일)
                          Positioned(
                            top: 15,
                            left: 20,
                            width: 60,
                            height: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // 어항 바닥 모래 장식
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 30,
                            child: Container(
                              color: Colors.brown.withValues(alpha: 0.4),
                            ),
                          ),
                          // 헤엄치는 2D 도트 물고기 (5가지 모션 적용)
                          if (_fishController != null)
                            AnimatedBuilder(
                              animation: _fishController!,
                              builder: (context, child) {
                                final v = _fishController!.value;
                                final double w =
                                    320.0 - 60.0; // 어항 가로 - 물고기 가로 길이
                                final double h =
                                    320.0 - 40.0 - 30.0; // 어항 세로 - 물고기 - 모래
                                double x = 0;
                                double y = 0;
                                bool flipX = false;

                                if (v < 0.2) {
                                  // 모션 1: 느긋하게 파도치며 전진
                                  final t = v * 5;
                                  x = w * t;
                                  y = h / 2 + sin(t * pi * 4) * 30;
                                  flipX = false;
                                } else if (v < 0.4) {
                                  // 모션 2: 위로 솟아오르며 파닥파닥 도망치기
                                  final t = (v - 0.2) * 5;
                                  x = w - (w * t);
                                  y =
                                      h / 2 -
                                      (h / 4 * t) +
                                      sin(t * pi * 10) * 8;
                                  flipX = true;
                                } else if (v < 0.6) {
                                  // 모션 3: 크게 빙글 루프(회전) 돌며 전진하기
                                  final t = (v - 0.4) * 5;
                                  x = (w / 2) * t + sin(t * pi * 2) * 40;
                                  y =
                                      h / 4 +
                                      (h / 4) * t +
                                      (1 - cos(t * pi * 2)) * 40;
                                  flipX =
                                      cos(t * pi * 2) < -0.5; // 거꾸로 돌 때 방향 반전
                                } else if (v < 0.8) {
                                  // 모션 4: 바닥을 향해 지그재그로 통통 튀며 전진
                                  final t = (v - 0.6) * 5;
                                  x = (w / 2) + (w / 2) * t;
                                  final frac = t * 6 % 1;
                                  y =
                                      h / 2 +
                                      (frac < 0.5 ? frac * 2 : (1 - frac) * 2) *
                                          35;
                                  flipX = false;
                                } else {
                                  // 모션 5: 바닥을 훑고 부드럽게 위로 올라오며 복귀
                                  final t = (v - 0.8) * 5;
                                  x = w - (w * t);
                                  y =
                                      h / 2 +
                                      50 * sin(t * pi) +
                                      sin(t * pi * 4) * 15;
                                  flipX = true;
                                }

                                return Positioned(
                                  left: x,
                                  top: y,
                                  child: Transform.scale(
                                    scaleX: flipX ? -1 : 1, // 방향에 맞게 좌우 반전
                                    alignment: Alignment.center,
                                    child: child!,
                                  ),
                                );
                              },
                              child: PixelFish(type: _swimmingFishType),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: _showFishStorage,
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('보관함'),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          // 2. 할 일 탭 (전체 화면)
          Container(
            color: Colors.white,
            width: double.infinity, // 가로 너비를 화면에 꽉 채우도록 보장
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '오늘의 할 일',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _todoList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Checkbox(
                          value: _todoList[index]['isDone'],
                          onChanged: (bool? value) => _toggleTodo(index, value),
                        ),
                        title: Text(
                          _todoList[index]['task'],
                          style: TextStyle(
                            // 체크되면 회색 및 취소선 처리
                            decoration: _todoList[index]['isDone']
                                ? TextDecoration.lineThrough
                                : null,
                            color: _todoList[index]['isDone']
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 3. 가챠 샵 탭 (전체 화면)
          Container(
            color: const Color(0xFFFFF0F5), // 연한 핑크색 배경
            width: double.infinity,
            height: double.infinity,
            // 방금 만든 슬롯머신 위젯을 연결합니다!
            child: SlotMachine(onDrawDone: _showGachaResult),
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
