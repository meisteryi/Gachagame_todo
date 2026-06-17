import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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

class GachaTodoApp extends StatefulWidget {
  const GachaTodoApp({super.key});

  @override
  State<GachaTodoApp> createState() => _GachaTodoAppState();
}

class _GachaTodoAppState extends State<GachaTodoApp> {
  bool _showSplash = true; // 💡 스플래시 화면 표시 여부 상태

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gacha Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB7B2)),
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
      // 💡 Navigator 버그를 원천 차단하기 위해 AnimatedSwitcher를 사용한 직접 상태 전환 방식으로 변경!
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onSkip: () => setState(() => _showSplash = false),
              )
            : const MainScreen(key: ValueKey('main')),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final VoidCallback onSkip;
  const SplashScreen({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB4D8E7), // 귀여운 파스텔 하늘색 배경
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSkip, // 💡 화면 터치 시 상태를 변경하여 부드럽게 MainScreen으로 교체
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 2.5,
                child: const PixelFish(type: 'puffer'), // 기본 도트 복어
              ),
              const SizedBox(height: 60),
              Text(
                'Gacha TODO!',
                style: GoogleFonts.pressStart2p(
                  fontSize: 28,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0xFF333333), offset: Offset(1.5, 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '- 화면을 터치해서 시작 -',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
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
            final fish = Map<String, dynamic>.from(item);
            // 💡 기존 데이터에 레벨/경험치/기분이 없다면 기본값 추가 (마이그레이션)
            fish['level'] ??= 1;
            fish['exp'] ??= 0;
            fish['mood'] ??= '보통';
            _ownedFishes.add(fish);
          }
        });
      } else {
        // 앱 최초 실행 시 기본 물고기 지급
        setState(() {
          _ownedFishes.add(<String, dynamic>{
            'type': 'puffer',
            'name': '도트 복어',
            'level': 1,
            'exp': 0,
            'mood': '보통',
          });
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(1.5, 1.5)),
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
                  child: RetroGradientButton(
                    color: Colors.grey[300]!,
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
      _ownedFishes.add(<String, dynamic>{
        ...drawnFish,
        'level': 1,
        'exp': 0,
        'mood': '좋음', // 💡 새로 뽑은 물고기는 기분이 좋음!
      });
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
      if (mounted) {
        _showStorage();
      }
    });
  }

  // 💡 설정 및 데이터 백업/복구 다이얼로그
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(1.5, 1.5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '게임 설정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RetroGradientButton(
                    color: const Color(0xFFB4D8E7),
                    foregroundColor: Colors.white,
                    onPressed: _saveToCloud,
                    child: const Text(
                      '클라우드에 저장 ☁️',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RetroGradientButton(
                    color: const Color(0xFFA8E6CF),
                    onPressed: _loadFromCloud,
                    child: const Text(
                      '클라우드에서 불러오기 ☁️',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RetroGradientButton(
                    color: Colors.grey[300]!,
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

  // ☁️ 파이어베이스 REST API: 클라우드 저장
  void _saveToCloud() {
    Navigator.pop(context); // 설정 창 닫기
    String userId = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(1.5, 1.5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '클라우드 저장',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => userId = val,
                  decoration: InputDecoration(
                    hintText: '사용할 아이디 (영문/숫자)',
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: RetroGradientButton(
                        color: Colors.grey[300]!,
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RetroGradientButton(
                        color: const Color(0xFFB4D8E7),
                        onPressed: () async {
                          if (userId.trim().isEmpty) return;

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final Map<String, dynamic> allData = {
                              'ownedFishes': prefs.getString('ownedFishes'),
                              'ownedSeaweeds': prefs.getString('ownedSeaweeds'),
                              'swimmingFish': prefs.getString('swimmingFish'),
                              'plantedSeaweeds': prefs.getString(
                                'plantedSeaweeds',
                              ),
                              'coins': prefs.getInt('coins'),
                              'feedCount': prefs.getInt('feedCount'),
                              'todos': prefs.getString('todos'),
                              'categories': prefs.getString('categories'),
                              'mission_data': prefs.getString('mission_data'),
                            };
                            allData.removeWhere((key, value) => value == null);

                            // 🚨 주의: 아래 주소를 본인의 파이어베이스 Realtime DB 주소로 교체하세요!
                            final String dbUrl =
                                "https://gachatodo-23081-default-rtdb.firebaseio.com/users/${userId.trim()}.json";

                            final response = await http.put(
                              Uri.parse(dbUrl),
                              body: jsonEncode(allData),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (response.statusCode == 200 && mounted) {
                              _showNoticeDialog(
                                '데이터가 클라우드에 저장되었습니다! ☁️\n아이디: ${userId.trim()}',
                              );
                            } else if (mounted) {
                              _showNoticeDialog(
                                '저장에 실패했습니다.\n상태 코드: ${response.statusCode}',
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              _showNoticeDialog(
                                '저장 중 오류가 발생했습니다.\n인터넷 연결을 확인해 주세요. 🥲',
                              );
                            }
                          }
                        },
                        child: const Text(
                          '저장',
                          style: TextStyle(fontWeight: FontWeight.w900),
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

  // ☁️ 파이어베이스 REST API: 클라우드 불러오기
  void _loadFromCloud() {
    Navigator.pop(context); // 설정 창 닫기
    String userId = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF333333), offset: Offset(1.5, 1.5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '클라우드 불러오기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => userId = val,
                  decoration: InputDecoration(
                    hintText: '저장했던 아이디 입력',
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: RetroGradientButton(
                        color: Colors.grey[300]!,
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RetroGradientButton(
                        color: Colors.greenAccent,
                        onPressed: () async {
                          if (userId.trim().isEmpty) return;

                          try {
                            // 🚨 주의: 아래 주소를 본인의 파이어베이스 Realtime DB 주소로 교체하세요!
                            final String dbUrl =
                                "https://gachatodo-23081-default-rtdb.firebaseio.com/users/${userId.trim()}.json";

                            final response = await http.get(Uri.parse(dbUrl));

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (response.statusCode == 200 &&
                                response.body != 'null') {
                              final Map<String, dynamic> allData = jsonDecode(
                                response.body,
                              );
                              final prefs =
                                  await SharedPreferences.getInstance();

                              if (allData.containsKey('ownedFishes')) {
                                await prefs.setString(
                                  'ownedFishes',
                                  allData['ownedFishes'],
                                );
                              }
                              if (allData.containsKey('ownedSeaweeds')) {
                                await prefs.setString(
                                  'ownedSeaweeds',
                                  allData['ownedSeaweeds'],
                                );
                              }
                              if (allData.containsKey('swimmingFish')) {
                                await prefs.setString(
                                  'swimmingFish',
                                  allData['swimmingFish'],
                                );
                              }
                              if (allData.containsKey('plantedSeaweeds')) {
                                await prefs.setString(
                                  'plantedSeaweeds',
                                  allData['plantedSeaweeds'],
                                );
                              }
                              if (allData.containsKey('coins')) {
                                await prefs.setInt('coins', allData['coins']);
                              }
                              if (allData.containsKey('feedCount')) {
                                await prefs.setInt(
                                  'feedCount',
                                  allData['feedCount'],
                                );
                              }
                              if (allData.containsKey('todos')) {
                                await prefs.setString(
                                  'todos',
                                  allData['todos'],
                                );
                              }
                              if (allData.containsKey('categories')) {
                                await prefs.setString(
                                  'categories',
                                  allData['categories'],
                                );
                              }
                              if (allData.containsKey('mission_data')) {
                                await prefs.setString(
                                  'mission_data',
                                  allData['mission_data'],
                                );
                              }

                              if (mounted) {
                                _showNoticeDialog(
                                  '클라우드 복구 성공! 🎉\n완벽한 적용을 위해 앱을 완전히 껐다 켜주세요.',
                                );
                              }
                            } else {
                              if (mounted) {
                                _showNoticeDialog(
                                  '해당 아이디의 데이터를 찾을 수 없습니다. 🥲\n(입력한 아이디: ${userId.trim()})',
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              _showNoticeDialog(
                                '불러오기 중 오류가 발생했습니다.\n인터넷 연결을 확인해 주세요. 🥲',
                              );
                            }
                          }
                        },
                        child: const Text(
                          '복구',
                          style: TextStyle(fontWeight: FontWeight.w900),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                                : const Color(0xFF333333),
                                            width:
                                                _swimmingFishType ==
                                                    fish['type']
                                                ? 2
                                                : 1,
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
                                                : const Color(0xFF333333),
                                            width:
                                                _plantedSeaweeds.any(
                                                  (s) =>
                                                      s['type'] ==
                                                      seaweed['type'],
                                                )
                                                ? 2
                                                : 1,
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
          color: isSelected ? const Color(0xFFFFF3B0) : Colors.grey[200],
          padding: const EdgeInsets.only(top: 6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48, // 상단바 두께 축소 (기본값 56)
        leading:
            _selectedIndex ==
                1 // 💡 할 일 탭에서만 톱니바퀴 표시
            ? IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: _showSettingsDialog, // 💡 설정 및 데이터 백업 버튼
                tooltip: '설정',
              )
            : null,
        title: Text(
          'Gacha TODO!',
          style: GoogleFonts.pressStart2p(fontSize: 16),
        ),
        // 💡 탭에 따라 우측 상단바 UI를 다르게 표시
        actions: [
          if (_selectedIndex == 0) // 내 수조 탭: 남은 먹이 개수 표시
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAB9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF333333), width: 1),
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
                        Shadow(color: Color(0xFF333333), offset: Offset(1, 1)),
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
                    color: const Color(0xFFFFDAB9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 1,
                    ),
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
                            Shadow(
                              color: Color(0xFF333333),
                              offset: Offset(1, 1),
                            ),
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
                    color: const Color(0xFFFFD166),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 1,
                    ),
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
                            Shadow(
                              color: Color(0xFF333333),
                              offset: Offset(1, 1),
                            ),
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
            swimmingFish: _ownedFishes.firstWhere(
              (f) => f['type'] == _swimmingFishType,
              orElse: () => <String, dynamic>{
                'type': 'puffer',
                'name': '도트 복어',
                'level': 1,
                'exp': 0,
                'mood': '보통',
              },
            ),
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
                _ownedFishes.add(<String, dynamic>{
                  'type': 'puffer',
                  'name': '도트 복어',
                  'level': 1,
                  'exp': 0,
                  'mood': '보통',
                }); // 기본 복어 유지
                _ownedFishes.addAll(
                  SlotMachine.fishList.map(
                    (e) => <String, dynamic>{
                      ...Map<String, dynamic>.from(e),
                      'level': 1,
                      'exp': 0,
                      'mood': '좋음',
                    },
                  ),
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
            top: BorderSide(color: Color(0xFF333333), width: 1),
          ), // 💡 상단 테두리 얇게 수정
        ),
        child: SafeArea(
          top: false, // 하단 아이폰 홈 바 여백 보호
          child: SizedBox(
            height: 56, // IntrinsicHeight 대신 안전하고 렌더링이 빠른 고정 높이 사용
            child: Row(
              children: [
                _buildPixelBottomNavItem(0, 'fish', '내 수조'),
                _buildPixelBottomNavItem(1, 'memo', '할 일'),
                _buildPixelBottomNavItem(2, 'trophy', '미션'),
                _buildPixelBottomNavItem(3, 'coin', '상점'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
