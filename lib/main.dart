import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/aquarium_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/mission_screen.dart';
import 'pixel_fish.dart';
import 'pixel_seaweed.dart';
import 'bouncing_wrapper.dart';
import 'pixel_emoji.dart';
import 'slot_machine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 💡 앱 시작 전 저장소 통신 채널을 완벽하게 초기화
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
        // 💡 웹에서만 애플 기본 폰트와 이모지(🍎)를 강제 지정하고, 앱(시뮬레이터)에서는 예쁜 기본값 유지!
        fontFamily: kIsWeb ? '-apple-system' : null,
        fontFamilyFallback: kIsWeb
            ? const [
                'BlinkMacSystemFont',
                'Apple Color Emoji',
                'Segoe UI Emoji',
              ]
            : null,
      ),
      // 💡 웹/PC 환경에서 화면이 너무 넓게 퍼지지 않도록 모바일 비율(최대 너비 450px)로 고정!
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: child,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _hasNavigated = false; // 💡 중복 이동 방지 플래그

  @override
  void initState() {
    super.initState();
    // 💡 약 1.2초 대기 후 메인 화면으로 전환하는 타이머 시작
    _timer = Timer(const Duration(milliseconds: 1200), _navigateToMain);
  }

  void _navigateToMain() {
    if (_hasNavigated) return; // 이미 넘어갔다면 실행 취소

    if (mounted) {
      _hasNavigated = true; // 이동 처리 상태 저장
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 💡 화면이 파괴될 때 타이머도 안전하게 취소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81D4FA), // 시원한 물색 배경
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _timer?.cancel(); // 💡 화면을 탭하면 즉시 메인 화면으로 이동
          _navigateToMain();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 2.5,
                child: const PixelFish(type: 'puffer'), // 기본 도트 복어
              ),
              const SizedBox(height: 60),
              const Text(
                'Gacha TODO!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, offset: Offset(3, 3))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1; // 💡 앱의 초기 화면을 수조(0)에서 '할 일(1)' 탭으로 변경

  final List<Map<String, dynamic>> _ownedFishes = [];
  final List<Map<String, dynamic>> _ownedSeaweeds = []; // 💡 수초 보관 리스트
  String _swimmingFishType = 'puffer'; // 수조에서 헤엄치는 기본 물고기
  List<Map<String, dynamic>> _plantedSeaweeds = []; // 💡 수조에 심어진 여러 수초들의 위치 정보
  int _coins = 0; // 💡 코인 재화 추가
  int _feedCount = 10; // 💡 기본 먹이 개수 (테스트용 10개)
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // 💡 초기 화면을 '할 일'로 변경

  @override
  void initState() {
    super.initState();
    _loadMainData(); // 앱 시작 시 보관함 데이터 불러오기
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- 💡 기기 저장소(SharedPreferences) 연동 로직 ---
  Future<void> _loadMainData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? fishesStr = prefs.getString('ownedFishes');
      if (fishesStr != null) {
        final List<dynamic> decoded = jsonDecode(fishesStr);
        setState(() {
          _ownedFishes.clear();
          for (var item in decoded) {
            _ownedFishes.add(Map<String, dynamic>.from(item));
          }
        });
      } else {
        // 앱 최초 실행 시 기본 물고기 지급
        setState(() {
          _ownedFishes.add({'type': 'puffer', 'name': '도트 복어'});
        });
      }

      // 수초 데이터 불러오기
      final String? seaweedsStr = prefs.getString('ownedSeaweeds');
      if (seaweedsStr != null) {
        final List<dynamic> decodedSeaweeds = jsonDecode(seaweedsStr);
        setState(() {
          _ownedSeaweeds.clear();
          for (var item in decodedSeaweeds) {
            _ownedSeaweeds.add(Map<String, dynamic>.from(item));
          }
        });
      }
      final String? plantedSeaweedsStr = prefs.getString('plantedSeaweeds');
      if (plantedSeaweedsStr != null) {
        final List<dynamic> decoded = jsonDecode(plantedSeaweedsStr);
        _plantedSeaweeds = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        // 기존 단일 수초 데이터 호환성 유지 및 마이그레이션
        final String? oldSeaweed = prefs.getString('plantedSeaweed');
        if (oldSeaweed != null) {
          _plantedSeaweeds.add({'type': oldSeaweed, 'x': 140.0});
          prefs.remove('plantedSeaweed');
        }
      }
      setState(() {
        _swimmingFishType = prefs.getString('swimmingFish') ?? 'puffer';
        _coins = prefs.getInt('coins') ?? 0; // 코인 로드
        _feedCount = prefs.getInt('feedCount') ?? 10; // 먹이 로드
      });
    } catch (e) {
      debugPrint('메인 데이터 로드 에러: $e');
    }
  }

  Future<void> _saveMainData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ownedFishes', jsonEncode(_ownedFishes));
    await prefs.setString('ownedSeaweeds', jsonEncode(_ownedSeaweeds));
    await prefs.setString('swimmingFish', _swimmingFishType);
    await prefs.setString('plantedSeaweeds', jsonEncode(_plantedSeaweeds));
    await prefs.setInt('coins', _coins); // 코인 저장
    await prefs.setInt('feedCount', _feedCount); // 먹이 저장
  }

  // 탭 변경 시 상태를 업데이트하여 화면을 다시 그리도록 함
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  // 상점 탭에서 새로운 물고기를 뽑았을 때 호출되는 함수
  void _onAddFish(Map<String, dynamic> drawnFish) {
    setState(() {
      _ownedFishes.add(drawnFish);
    });
    _saveMainData();
  }

  void _onAddSeaweed(Map<String, dynamic> drawnSeaweed) {
    setState(() {
      _ownedSeaweeds.add(drawnSeaweed);
    });
    _saveMainData();
  }

  // 상점 탭에서 보관함으로 이동할 때 호출되는 함수
  void _navigateToAquariumAndShowStorage() {
    setState(() {
      _selectedIndex = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _showStorage();
    });
  }

  // 통합 보관함(물고기 & 수초) 열기
  void _showStorage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 화면 비율에 따라 높이를 조정할 수 있게 허용
      backgroundColor: Colors.transparent, // 둥근 모서리 디자인을 위해 투명 처리
      builder: (context) {
        // SafeArea 추가: 아이폰 하단 홈 바에 UI가 가려지지 않도록 보호
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            height:
                MediaQuery.of(context).size.height *
                0.6, // 스크롤을 위해 기기 높이의 60% 사용
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        PixelEmoji('box', size: 24),
                        SizedBox(width: 8),
                        Text(
                          '내 보관함',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 물고기 보관함 영역 ---
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              PixelEmoji('fish', size: 16),
                              SizedBox(width: 8),
                              Text(
                                '내 물고기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ownedFishes.isEmpty
                            ? const Text('아직 뽑은 물고기가 없어요!')
                            : GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(), // 스크롤은 부모가 대신함
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.25,
                                    ),
                                itemCount: _ownedFishes.length,
                                itemBuilder: (context, index) {
                                  final fish = _ownedFishes[index];
                                  return BouncingWrapper(
                                    child: SizedBox.expand(
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color:
                                                _swimmingFishType ==
                                                    fish['type']
                                                ? Colors.redAccent
                                                : Colors.black,
                                            width:
                                                _swimmingFishType ==
                                                    fish['type']
                                                ? 4
                                                : 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _swimmingFishType =
                                                  fish['type']?.toString() ??
                                                  'puffer';
                                              _selectedIndex = 0;
                                            });
                                            _saveMainData();
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Transform.scale(
                                                scale: 1.2,
                                                child: PixelFish(
                                                  type:
                                                      fish['type']
                                                          ?.toString() ??
                                                      'puffer',
                                                  isAnimated:
                                                      false, // 💡 보관함에서는 가만히 있도록 설정
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                fish['name']?.toString() ?? '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 24),

                        // --- 수초 보관함 영역 ---
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              PixelEmoji('seaweed', size: 16),
                              SizedBox(width: 8),
                              Text(
                                '내 수초',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ownedSeaweeds.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Text(
                                  '아직 뽑은 수초가 없어요!\n가챠 샵에서 수초를 뽑아보세요.',
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 12,
                                      childAspectRatio:
                                          1.0, // 수초는 세로가 기므로 정방형으로 비율 조정
                                    ),
                                itemCount: _ownedSeaweeds.length,
                                itemBuilder: (context, index) {
                                  final seaweed = _ownedSeaweeds[index];
                                  return BouncingWrapper(
                                    child: SizedBox.expand(
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color:
                                                _plantedSeaweeds.any(
                                                  (s) =>
                                                      s['type'] ==
                                                      seaweed['type'],
                                                )
                                                ? Colors.greenAccent
                                                : Colors.black,
                                            width:
                                                _plantedSeaweeds.any(
                                                  (s) =>
                                                      s['type'] ==
                                                      seaweed['type'],
                                                )
                                                ? 4
                                                : 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _plantedSeaweeds.add({
                                                'type':
                                                    seaweed['type']
                                                        ?.toString() ??
                                                    'green_algae',
                                                'x':
                                                    140.0 +
                                                    (Random().nextDouble() *
                                                            40 -
                                                        20), // 💡 추가 시 겹치지 않게 위치 살짝 분산
                                              });
                                              _selectedIndex = 0;
                                            });
                                            _saveMainData();
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                            Navigator.of(context).pop();
                                          },
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Transform.scale(
                                                scale: 1.1,
                                                child: PixelSeaweed(
                                                  type:
                                                      seaweed['type']
                                                          ?.toString() ??
                                                      'green_algae',
                                                  isAnimated:
                                                      false, // 💡 보관함에서는 가만히 있도록 설정
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                seaweed['name']?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 20),
                      ],
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

  // 🎮 픽셀 감성 하단 네비게이션 탭 아이템 빌더
  Widget _buildPixelBottomNavItem(int index, String emoji, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: isSelected ? Colors.yellowAccent : Colors.grey[300],
          child: SafeArea(
            top: false, // 💡 하단 여백만 적용하여 배경색이 화면 끝까지 채워지도록 설정
            child: Container(
              height: 56, // 💡 탭 바의 두께를 살짝 줄여서 슬림하게
              padding: const EdgeInsets.only(
                top: 6,
              ), // 💡 내용물을 위에서 살짝 눌러서 아래로 안착시킴
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: isSelected ? 1.0 : 0.4,
                    child: PixelEmoji(emoji, size: isSelected ? 24 : 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isSelected ? 13 : 11,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48, // 상단바 두께 축소 (기본값 56)
        title: const Text(
          'Gacha TODO!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // 💡 탭에 따라 우측 상단바 UI를 다르게 표시
        actions: [
          if (_selectedIndex == 0) // 내 수조 탭: 남은 먹이 개수 표시
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Row(
                children: [
                  const PixelEmoji('meat', size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_feedCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedIndex >= 2) // 미션 탭이나 상점 탭일 때는 코인/먹이 표시
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    children: [
                      const PixelEmoji('meat', size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_feedCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    children: [
                      const PixelEmoji('coin', size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // 스와이프 대신 하단 바 탭으로만 이동하도록 고정
        children: [
          // 1. 내 수조 탭 (전체 화면)
          AquariumScreen(
            swimmingFishType: _swimmingFishType,
            plantedSeaweeds: _plantedSeaweeds,
            feedCount: _feedCount,
            onFeed: () {
              setState(() => _feedCount--);
              _saveMainData(); // 먹이 소모 시 저장
            },
            onUpdateSeaweeds: (newList) {
              setState(() => _plantedSeaweeds = newList);
              _saveMainData(); // 편집 위치 실시간 저장
            },
            onShowStorage: _showStorage,
          ),
          // 2. 할 일 탭 (전체 화면)
          TodoScreen(
            onSecretCommand: () {
              setState(() => _coins += 1000);
              _saveMainData();
            },
            onUnlockAllCommand: () {
              setState(() {
                _ownedFishes.clear();
                _ownedFishes.add({
                  'type': 'puffer',
                  'name': '도트 복어',
                }); // 기본 복어 유지
                _ownedFishes.addAll(
                  SlotMachine.fishList.map((e) => Map<String, dynamic>.from(e)),
                );
                _ownedSeaweeds.clear();
                _ownedSeaweeds.addAll(
                  SlotMachine.seaweedList.map(
                    (e) => Map<String, dynamic>.from(e),
                  ),
                );
              });
              _saveMainData();
            },
          ),
          // 3. 미션 탭 (코인 획득)
          MissionScreen(
            isActive: _selectedIndex == 2,
            onAddCoin: (amount) {
              setState(() => _coins += amount);
              _saveMainData();
            },
          ),
          // 4. 상점 탭 (상점 메인 메뉴 또는 가챠 기계 + 폭죽 오버레이)
          ShopScreen(
            coins: _coins,
            ownedFishes: _ownedFishes,
            ownedSeaweeds: _ownedSeaweeds,
            onAddFish: _onAddFish,
            onAddSeaweed: _onAddSeaweed,
            onBuyFeed: (cost, amount) {
              setState(() {
                _coins -= cost;
                _feedCount += amount;
              });
              _saveMainData();
            },
            onSpendCoin: (cost) {
              setState(() {
                _coins -= cost;
              });
              _saveMainData();
            },
            onNavigateToAquarium: _navigateToAquariumAndShowStorage,
          ),
        ],
      ),
      // 3. 픽셀 스타일 하단 네비게이션 바
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black, width: 2),
          ), // 💡 상단 테두리 얇게 수정
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // 💡 아이템들이 세로로 꽉 차도록 늘림
            children: [
              _buildPixelBottomNavItem(0, 'fish', '내 수조'),
              _buildPixelBottomNavItem(1, 'memo', '할 일'),
              _buildPixelBottomNavItem(2, 'trophy', '미션'),
              _buildPixelBottomNavItem(3, 'coin', '상점'),
            ],
          ),
        ),
      ),
    );
  }
}
