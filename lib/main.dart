import 'package:flutter/material.dart';

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

  // 할 일 데이터 상태 관리 (임시 데이터)
  final List<Map<String, dynamic>> _todoList = [
    {'task': '대충 세운 계획 1', 'isDone': false},
    {'task': '대충 세운 계획 2', 'isDone': false},
    {'task': '대충 세운 계획 3', 'isDone': false},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '가챠 투두 🎲',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 1. 내 수조 탭 (전체 화면)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF81D4FA), Color(0xFF0288D1)],
              ),
            ),
            child: const Center(
              child: Text(
                '🐟 수조 영역 🐠',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ),
          // 2. 할 일 탭 (전체 화면)
          Container(
            color: Colors.white,
            width: double.infinity, // 가로 너비를 화면에 꽉 채우도록 보장
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎰', style: TextStyle(fontSize: 100)),
                  SizedBox(height: 20),
                  Text(
                    '가챠 샵',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('할 일을 완료하고 코인을 모아보세요!'),
                ],
              ),
            ),
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
