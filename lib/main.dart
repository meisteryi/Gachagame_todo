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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _ownedFishes = [];
  String _swimmingFishType = 'puffer'; // 수조에서 헤엄치는 기본 물고기

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
          AquariumScreen(
            swimmingFishType: _swimmingFishType,
            onShowStorage: _showFishStorage,
          ),
          // 2. 할 일 탭 (전체 화면)
          const TodoScreen(),
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
