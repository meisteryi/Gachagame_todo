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
import 'screens/settings_screen.dart';
import 'translations.dart';
import 'pixel_fish.dart';
import 'pixel_seaweed.dart';
import 'pixel_decoration.dart';
import 'bouncing_wrapper.dart';
import 'pixel_emoji.dart';
import 'slot_machine.dart';
import 'pixel_supplement.dart';
import 'theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 💡 앱 시작 전 저장소 통신 채널을 완벽하게 초기화
  await AppTheme.init(); // 💡 테마 설정 초기화
  await Tr.init(); // 💡 언어 설정 초기화

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
    return ValueListenableBuilder<ThemeType>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, theme, child) {
        return ValueListenableBuilder<AppLang>(
          valueListenable: Tr.langNotifier,
          builder: (context, lang, child) {
            return MaterialApp(
              title: 'Gacha Todo',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppTheme.themeSeed,
                ),
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
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final VoidCallback onSkip;
  const SplashScreen({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF68C2D3), // 귀여운 파스텔 하늘색 배경
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
                    Shadow(color: Color(0xFF212123), offset: Offset(3, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '- 화면을 터치해서 시작 -'.tr,
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
  bool _isFishStorageExpanded = true;
  bool _isSeaweedStorageExpanded = true;
  bool _isDecoStorageExpanded = true;

  final List<Map<String, dynamic>> _ownedFishes = [];
  final List<Map<String, dynamic>> _ownedSeaweeds = []; // 💡 수초 보관 리스트
  final List<Map<String, dynamic>> _ownedDecorations = []; // 💡 장식물 보관 리스트
  List<String> _swimmingFishIds = []; // 💡 수조에서 헤엄치는 여러 마리의 물고기 ID 목록
  List<Map<String, dynamic>> _plantedSeaweeds = []; // 💡 수조에 심어진 여러 수초들의 위치 정보
  List<Map<String, dynamic>> _plantedDecorations = []; // 💡 수조에 배치된 장식물
  int _coins = 0; // 💡 코인 재화 추가
  int _feedCount = 10; // 💡 기본 먹이 개수 (테스트용 10개)
  int _supplementCount = 5; // 💡 영양제 개수 추가
  bool _isSupplementActive = false; // 💡 영양제 활성화 상태 (다음 먹이 경험치 2배 버프)
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // 💡 초기 화면을 '할 일'로 변경
  Timer? _moodTimer;
  int _lastMoodUpdateTime =
      DateTime.now().millisecondsSinceEpoch; // 💡 마지막 기분 변경 시간 기록

  @override
  void initState() {
    super.initState();
    _loadMainData(); // 앱 시작 시 보관함 데이터 불러오기
    _startMoodTimer();
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- 💡 기기 저장소(SharedPreferences) 연동 로직 ---
  Future<void> _loadMainData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? fishesStr = prefs.getString('ownedFishes');
      int idGen = 0; // 💡 마이그레이션용 ID 발급기
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
            fish['id'] ??=
                'fish_${DateTime.now().millisecondsSinceEpoch}_${idGen++}'; // 💡 고유 ID 부여
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
            'id': 'fish_default_0',
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
      // 💡 장식물 보관함 로드
      final String? decoStr = prefs.getString('ownedDecorations');
      if (decoStr != null) {
        final List<dynamic> decodedDecos = jsonDecode(decoStr);
        setState(() {
          _ownedDecorations.clear();
          for (var item in decodedDecos) {
            _ownedDecorations.add(Map<String, dynamic>.from(item));
          }
        });
      }
      final String? plantedSeaweedsStr = prefs.getString('plantedSeaweeds');
      if (plantedSeaweedsStr != null) {
        final List<dynamic> decoded = jsonDecode(plantedSeaweedsStr);
        _plantedSeaweeds = decoded
            .where((e) => e != null)
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
      // 💡 배치된 장식물 로드
      final String? plantedDecoStr = prefs.getString('plantedDecorations');
      if (plantedDecoStr != null) {
        final List<dynamic> decodedDeco = jsonDecode(plantedDecoStr);
        _plantedDecorations = decodedDeco
            .where((e) => e != null)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      setState(() {
        _coins = prefs.getInt('coins') ?? 0; // 코인 로드
        _feedCount = prefs.getInt('feedCount') ?? 10; // 먹이 로드
        _supplementCount = prefs.getInt('supplementCount') ?? 5; // 영양제 로드
        _isSupplementActive = prefs.getBool('isSupplementActive') ?? false;

        // 💡 수조의 물고기 목록 불러오기 (마이그레이션 포함)
        final String? swimStr = prefs.getString('swimmingFishIds');
        final ownedIds = _ownedFishes.map((f) => f['id'].toString()).toSet();
        if (swimStr != null) {
          // 💡 리스트 내부에 null이 섞여 있거나 더 이상 소유하지 않은 물고기의 ID는 필터링하여 제거
          _swimmingFishIds = (jsonDecode(swimStr) as List)
              .where((e) => e != null)
              .map((e) => e.toString())
              .where((id) => ownedIds.contains(id))
              .toList();
        } else {
          final String oldSwim = prefs.getString('swimmingFish') ?? 'puffer';
          final match = _ownedFishes.firstWhere(
            (f) => f['type'] == oldSwim,
            orElse: () => _ownedFishes.first,
          );
          if (match['id'] != null) _swimmingFishIds = [match['id'].toString()];
        }
        if (_swimmingFishIds.isEmpty && _ownedFishes.isNotEmpty) {
          _swimmingFishIds.add(_ownedFishes.first['id'].toString());
        }
        _lastMoodUpdateTime =
            prefs.getInt('lastMoodUpdateTime') ??
            DateTime.now().millisecondsSinceEpoch;
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastMoodUpdateTime >= 5 * 60 * 1000) {
          _randomizeFishMoods();
        }
      });
    } catch (e) {
      debugPrint('메인 데이터 로드 에러: $e');
    }
  }

  Future<void> _saveMainData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ownedFishes', jsonEncode(_ownedFishes));
    await prefs.setString('ownedSeaweeds', jsonEncode(_ownedSeaweeds));
    await prefs.setString('ownedDecorations', jsonEncode(_ownedDecorations));
    await prefs.setString('swimmingFishIds', jsonEncode(_swimmingFishIds));
    await prefs.setString('plantedSeaweeds', jsonEncode(_plantedSeaweeds));
    await prefs.setString('plantedDecorations', jsonEncode(_plantedDecorations));
    await prefs.setInt('coins', _coins); // 코인 저장
    await prefs.setInt('feedCount', _feedCount); // 먹이 저장
    await prefs.setInt('supplementCount', _supplementCount); // 영양제 저장
    await prefs.setBool('isSupplementActive', _isSupplementActive); // 버프 상태 저장
    await prefs.setInt(
      'lastMoodUpdateTime',
      _lastMoodUpdateTime,
    ); // 마지막 기분 변경 시간 저장
  }

  void _startMoodTimer() {
    _moodTimer?.cancel();
    _moodTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _randomizeFishMoods();
    });
  }

  void _randomizeFishMoods() {
    final random = Random();
    final moods = ['보통', '좋음', '최고야!', '나쁨'];
    _lastMoodUpdateTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      for (var fish in _ownedFishes) {
        fish['mood'] = moods[random.nextInt(moods.length)];
      }
    });
    _saveMainData();
  }

  void _cheatAllFishesToLevel5() {
    setState(() {
      for (var fish in _ownedFishes) {
        fish['level'] = 5;
        fish['exp'] = 0;
      }
    });
    _saveMainData();
    _showNoticeDialog('치트: 모든 물고기가 5레벨이 되었습니다! ⚡');
  }

  void _resetAllFishesLevel() {
    setState(() {
      for (var fish in _ownedFishes) {
        fish['level'] = 1;
        fish['exp'] = 0;
      }
    });
    _saveMainData();
    _showNoticeDialog('치트: 모든 물고기 레벨이 초기화되었습니다! 🔄');
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
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
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

  // 상점 탭에서 새로운 물고기를 뽑았을 때 호출되는 함수
  void _onAddFish(Map<String, dynamic> drawnFish) {
    setState(() {
      _ownedFishes.add(<String, dynamic>{
        ...drawnFish,
        'level': 1,
        'exp': 0,
        'mood': '좋음', // 💡 새로 뽑은 물고기는 기분이 좋음!
        'id':
            'fish_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      });
    });
    _saveMainData();
  }

  // 💡 먹이 및 영양제 경험치 증가 로직
  void _gainExp(int amount, String targetId) {
    bool leveledUp = false;
    int finalAmount = amount;

    // 영양제 버프가 활성화되어 있으면 경험치 2배 획득 후 버프 해제
    if (_isSupplementActive) {
      finalAmount *= 2;
      _isSupplementActive = false;
    }

    for (var fish in _ownedFishes) {
      if (fish['id'] == targetId) {
        // --- 💡 기분에 따른 경험치 추가 효과 ---
        double moodMultiplier = 1.0;
        final String mood = fish['mood'] ?? '보통';
        if (mood == '최고야!') {
          moodMultiplier = 1.5;
        } else if (mood == '좋음') {
          moodMultiplier = 1.2;
        } else if (mood == '나쁨') {
          moodMultiplier = 0.7;
        }
        int expGain = (finalAmount * moodMultiplier).round();

        fish['exp'] = (fish['exp'] ?? 0) + expGain;
        while (true) {
          int level = fish['level'] ?? 1;
          int maxExp = 30 * (1 << (level - 1).clamp(0, 10));
          if (fish['exp'] >= maxExp) {
            fish['level'] = level + 1;
            fish['exp'] -= maxExp;
            fish['mood'] = '최고야!';
            leveledUp = true;
          } else {
            break;
          }
        }
      }
    }
    if (leveledUp) {
      // 먹이 애니메이션이 끝날 즈음에 축하 팝업 띄우기
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) _showNoticeDialog('수조의 물고기가 레벨업했습니다! 🎉'.tr);
      });
    }
  }

  void _onAddSeaweed(Map<String, dynamic> drawnSeaweed) {
    setState(() {
      _ownedSeaweeds.add(drawnSeaweed);
    });
    _saveMainData();
  }

  void _onAddDeco(Map<String, dynamic> deco) {
    setState(() => _ownedDecorations.add(deco));
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



  // ☁️ 파이어베이스 REST API: 클라우드 저장
  void _saveToCloud() {
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
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '클라우드 저장'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => userId = val,
                  decoration: InputDecoration(
                    hintText: '사용할 아이디 (영문/숫자)'.tr,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(4),
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
                        child: Text(
                          '취소'.tr,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RetroGradientButton(
                        color: const Color(0xFF68C2D3),
                        onPressed: () async {
                          if (userId.trim().isEmpty) return;

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final Map<String, dynamic> allData = {
                              'ownedFishes': prefs.getString('ownedFishes'),
                              'ownedSeaweeds': prefs.getString('ownedSeaweeds'),
                              'swimmingFishIds': prefs.getString(
                                'swimmingFishIds',
                              ),
                              'plantedSeaweeds': prefs.getString(
                                'plantedSeaweeds',
                              ),
                              'coins': prefs.getInt('coins'),
                              'feedCount': prefs.getInt('feedCount'),
                              'supplementCount': prefs.getInt(
                                'supplementCount',
                              ),
                              'isSupplementActive': prefs.getBool(
                                'isSupplementActive',
                              ),
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
                                '데이터가 클라우드에 저장되었습니다! ☁️\n아이디: %s'.trArgs([
                                  userId.trim(),
                                ]),
                              );
                            } else if (mounted) {
                              _showNoticeDialog(
                                '저장에 실패했습니다.\n상태 코드: %s'.trArgs([
                                  response.statusCode.toString(),
                                ]),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              _showNoticeDialog(
                                '저장 중 오류가 발생했습니다.\n인터넷 연결을 확인해 주세요. 🥲'.tr,
                              );
                            }
                          }
                        },
                        child: Text(
                          '저장'.tr,
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
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Color(0xFF212123), offset: Offset(3, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '클라우드 불러오기'.tr,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => userId = val,
                  decoration: InputDecoration(
                    hintText: '저장했던 아이디 입력'.tr,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(4),
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
                        child: Text(
                          '취소'.tr,
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

                              if (allData['ownedFishes'] != null) {
                                await prefs.setString(
                                  'ownedFishes',
                                  allData['ownedFishes'].toString(),
                                );
                              }
                              if (allData['ownedSeaweeds'] != null) {
                                await prefs.setString(
                                  'ownedSeaweeds',
                                  allData['ownedSeaweeds'].toString(),
                                );
                              }
                              if (allData['swimmingFishIds'] != null) {
                                await prefs.setString(
                                  'swimmingFishIds',
                                  allData['swimmingFishIds'].toString(),
                                );
                              }
                              if (allData['plantedSeaweeds'] != null) {
                                await prefs.setString(
                                  'plantedSeaweeds',
                                  allData['plantedSeaweeds'].toString(),
                                );
                              }
                              if (allData['coins'] != null) {
                                await prefs.setInt(
                                  'coins',
                                  allData['coins'] as int,
                                );
                              }
                              if (allData['feedCount'] != null) {
                                await prefs.setInt(
                                  'feedCount',
                                  allData['feedCount'] as int,
                                );
                              }
                              if (allData['supplementCount'] != null) {
                                await prefs.setInt(
                                  'supplementCount',
                                  allData['supplementCount'] as int,
                                );
                              }
                              if (allData['isSupplementActive'] != null) {
                                await prefs.setBool(
                                  'isSupplementActive',
                                  allData['isSupplementActive'] as bool,
                                );
                              }
                              if (allData['todos'] != null) {
                                await prefs.setString(
                                  'todos',
                                  allData['todos'].toString(),
                                );
                              }
                              if (allData['categories'] != null) {
                                await prefs.setString(
                                  'categories',
                                  allData['categories'].toString(),
                                );
                              }
                              if (allData['mission_data'] != null) {
                                await prefs.setString(
                                  'mission_data',
                                  allData['mission_data'].toString(),
                                );
                              }

                              if (mounted) {
                                _showNoticeDialog(
                                  '클라우드 복구 성공! 🎉\n완벽한 적용을 위해 앱을 완전히 껐다 켜주세요.'
                                      .tr,
                                );
                              }
                            } else {
                              if (mounted) {
                                _showNoticeDialog(
                                  '해당 아이디의 데이터를 찾을 수 없습니다. 🥲\n(입력한 아이디: %s)'
                                      .trArgs([userId.trim()]),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              _showNoticeDialog(
                                '불러오기 중 오류가 발생했습니다.\n인터넷 연결을 확인해 주세요. 🥲'.tr,
                              );
                            }
                          }
                        },
                        child: Text(
                          '복구'.tr,
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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // SafeArea 추가: 아이폰 하단 홈 바에 UI가 가려지지 않도록 보호
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                height:
                    MediaQuery.of(context).size.height *
                    0.6, // 스크롤을 위해 기기 높이의 60% 사용
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            PixelEmoji('box', size: 24),
                            SizedBox(width: 8),
                            Text(
                              '내 보관함'.tr,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    _isFishStorageExpanded = !_isFishStorageExpanded;
                                  });
                                },
                                child: Row(
                                  children: [
                                    PixelEmoji('fish', size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '내 물고기'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isFishStorageExpanded ? 0.0 : -0.25,
                                      duration: const Duration(milliseconds: 200),
                                      child: const PixelTriangle(isExpanded: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _isFishStorageExpanded
                                  ? (_ownedFishes.isEmpty
                                      ? Text('아직 뽑은 물고기가 없어요!'.tr)
                                      : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(), // 스크롤은 부모가 대신함
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 6,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 1.1,
                                        ),
                                    itemCount: _ownedFishes.length,
                                    itemBuilder: (context, index) {
                                      final fish = _ownedFishes[index];
                                      final bool isSwimming = _swimmingFishIds
                                          .contains(fish['id']);
                                      return BouncingWrapper(
                                        child: SizedBox.expand(
                                          child: Card(
                                            margin: EdgeInsets.zero,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              onTap: () {
                                                setSheetState(() {
                                                  // 💡 팝업창 내부 UI(체크마크 등) 즉시 갱신
                                                  if (isSwimming) {
                                                    if (_swimmingFishIds
                                                            .length >
                                                        1) {
                                                      _swimmingFishIds.remove(
                                                        fish['id'],
                                                      );
                                                    } else {
                                                      _showNoticeDialog(
                                                        '최소 1마리의 물고기는 수조에 있어야 합니다!'
                                                            .tr,
                                                      );
                                                    }
                                                  } else {
                                                    if (_swimmingFishIds
                                                            .length >=
                                                        5) {
                                                      _showNoticeDialog(
                                                        '수조에는 최대 5마리까지만 넣을 수 있습니다!'
                                                            .tr,
                                                      );
                                                    } else {
                                                      _swimmingFishIds.add(
                                                        fish['id']
                                                            .toString(), // 💡 확실하게 String으로 변환
                                                      );
                                                      Navigator.of(
                                                        context,
                                                      ).pop(); // 💡 물고기를 수조에 넣으면 창 닫기
                                                    }
                                                  }
                                                });
                                                setState(
                                                  () {},
                                                ); // 💡 뒤에 깔려있는 메인 수조 화면도 갱신
                                                _saveMainData();
                                              },
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Transform.scale(
                                                        scale: 1.2,
                                                        child: PixelFish(
                                                          type:
                                                              fish['type']
                                                                  ?.toString() ??
                                                              'puffer',
                                                          isAnimated: false,
                                                          level:
                                                              fish['level'] ??
                                                              1,
                                                          useLevel5Color:
                                                              fish['useLevel5Color'] ??
                                                              true,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        (fish['name']
                                                                    ?.toString() ??
                                                                '')
                                                            .tr,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if ((fish['level'] ?? 0) >= 5)
                                                        const SizedBox(height: 12),
                                                    ],
                                                  ),
                                                  if (isSwimming)
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CustomPaint(
                                                          painter:
                                                              PixelCheckPainter(
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Text(
                                                      'Lv.${fish['level'] ?? 1}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                    ),
                                                  ),
                                                  if ((fish['level'] ?? 0) >= 5)
                                                    Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      bottom: 4,
                                                      child: Center(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setSheetState(() {
                                                              fish['useLevel5Color'] =
                                                                  !(fish['useLevel5Color'] ?? true);
                                                            });
                                                            setState(() {});
                                                            _saveMainData();
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: (fish['useLevel5Color'] ?? true)
                                                                  ? Colors.amber.shade100
                                                                  : Colors.grey.shade300,
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(
                                                                color: (fish['useLevel5Color'] ?? true)
                                                                    ? Colors.amber
                                                                    : Colors.grey,
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              (fish['useLevel5Color'] ?? true)
                                                                  ? '특수색 ON'.tr
                                                                  : '특수색 OFF'.tr,
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.bold,
                                                                color: (fish['useLevel5Color'] ?? true)
                                                                    ? Colors.amber.shade900
                                                                    : Colors.grey.shade700,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),

                            // --- 수초 보관함 영역 ---
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    _isSeaweedStorageExpanded = !_isSeaweedStorageExpanded;
                                  });
                                },
                                child: Row(
                                  children: [
                                    PixelEmoji('seaweed', size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '내 수초'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isSeaweedStorageExpanded ? 0.0 : -0.25,
                                      duration: const Duration(milliseconds: 200),
                                      child: const PixelTriangle(isExpanded: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _isSeaweedStorageExpanded
                                  ? (_ownedSeaweeds.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      '아직 뽑은 수초가 없어요!\n가챠 샵에서 수초를 뽑아보세요.'.tr,
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                      final bool isPlanted = _plantedSeaweeds
                                          .any(
                                            (s) => s['type'] == seaweed['type'],
                                          );
                                      return BouncingWrapper(
                                        child: SizedBox.expand(
                                          child: Card(
                                            margin: EdgeInsets.zero,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Transform.scale(
                                                        scale: 1.1,
                                                        child: PixelSeaweed(
                                                          type:
                                                              seaweed['type']
                                                                  ?.toString() ??
                                                              'green_algae',
                                                          isAnimated: false,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        (seaweed['name']
                                                                    ?.toString() ??
                                                                '')
                                                            .tr,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  if (isPlanted)
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CustomPaint(
                                                          painter:
                                                              PixelCheckPainter(
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),

                            // --- 장식물 보관함 영역 ---
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    _isDecoStorageExpanded = !_isDecoStorageExpanded;
                                  });
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: const PixelDecoration(type: 'ammonite', isAnimated: false),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '내 장식물'.tr,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _isDecoStorageExpanded ? 0.0 : -0.25,
                                      duration: const Duration(milliseconds: 200),
                                      child: const PixelTriangle(isExpanded: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _isDecoStorageExpanded
                                  ? (_ownedDecorations.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.only(bottom: 20),
                                    child: Text('아직 산 장식물이 없어요!\n상점에서 장식물을 구매해보세요.'),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: _ownedDecorations.length,
                                    itemBuilder: (context, index) {
                                      final deco = _ownedDecorations[index];
                                      final bool isPlaced = _plantedDecorations
                                          .any((d) => d['type'] == deco['type']);
                                      return BouncingWrapper(
                                        child: SizedBox.expand(
                                          child: Card(
                                            margin: EdgeInsets.zero,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide.none,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _plantedDecorations.add({
                                                    'type': deco['type']?.toString() ?? 'ammonite',
                                                    'name': deco['name']?.toString() ?? '',
                                                    'x': 80.0 + (Random().nextDouble() * 160 - 40),
                                                  });
                                                  _selectedIndex = 0;
                                                });
                                                _saveMainData();
                                                _pageController.animateToPage(0,
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                );
                                                Navigator.of(context).pop();
                                              },
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      PixelDecoration(
                                                        type: deco['type']?.toString() ?? 'ammonite',
                                                        isAnimated: false,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        deco['name']?.toString() ?? '',
                                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  if (isPlaced)
                                                    Positioned(
                                                      top: 6,
                                                      left: 6,
                                                      child: SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CustomPaint(
                                                          painter: PixelCheckPainter(color: Colors.green),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                                  : const SizedBox.shrink(),
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
          color: isSelected ? AppTheme.selectedTabBg : AppTheme.unselectedTabBg,
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
                label.tr, // 💡 라벨 번역
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isSelected ? 13 : 11,
                  color: isSelected ? AppTheme.selectedTabText : AppTheme.unselectedTabText,
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
        title: Text(
          'Gacha TODO!',
          style: GoogleFonts.pressStart2p(fontSize: 16),
        ),
        centerTitle: false, // 💡 어느 기기/화면이든 제목을 좌측 정렬 강제
        // 💡 탭에 따라 우측 상단바 UI를 다르게 표시
        actions: [
          if (_selectedIndex == 0) // 내 수조 탭: 남은 먹이 개수 표시
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5CEB4),
                borderRadius: BorderRadius.circular(4),
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
                        Shadow(color: Color(0xFF212123), offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedIndex == 0) // 내 수조 탭: 남은 영양제 개수 표시
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8AB060),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const PixelSupplement(size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_supplementCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0xFF212123), offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedIndex == 2 || _selectedIndex == 3) // 미션 탭이나 상점 탭일 때는 코인/먹이 표시
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 미션 탭 상단 먹이 표시 유지
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5CEB4),
                    borderRadius: BorderRadius.circular(4),
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
                              color: Color(0xFF212123),
                              offset: Offset(2, 2),
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
                    color: const Color(0xFFEDE19E),
                    borderRadius: BorderRadius.circular(4),
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
                              color: Color(0xFF212123),
                              offset: Offset(2, 2),
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
            swimmingFishes: _ownedFishes
                .where((f) => _swimmingFishIds.contains(f['id']))
                .toList(),
            plantedSeaweeds: _plantedSeaweeds,
            plantedDecorations: _plantedDecorations,
            feedCount: _feedCount,
            supplementCount: _supplementCount,
            isSupplementActive: _isSupplementActive,
            onFeed: (fishId) {
              setState(() {
                _feedCount--;
                _gainExp(10, fishId);
              });
              _saveMainData();
            },
            onSupplement: () {
              setState(() {
                _supplementCount--;
                _isSupplementActive = true;
              });
              _saveMainData();
            },
            onUpdateSeaweeds: (newList) {
              setState(() => _plantedSeaweeds = newList);
              _saveMainData();
            },
            onUpdateDecorations: (newList) {
              setState(() => _plantedDecorations = newList);
              _saveMainData();
            },
            onShowStorage: _showStorage,
            onCheatAllLevel5: _cheatAllFishesToLevel5,
            onCheatResetLevel: _resetAllFishesLevel,
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
                  'id': 'fish_default_0',
                }); // 기본 복어 유지

                int index = 1;
                final nowMs = DateTime.now().millisecondsSinceEpoch;
                _ownedFishes.addAll(
                  SlotMachine.fishList.map(
                    (e) => <String, dynamic>{
                      ...Map<String, dynamic>.from(e),
                      'level': 1,
                      'exp': 0,
                      'mood': '좋음',
                      'id': 'fish_${nowMs}_${index++}',
                    },
                  ),
                );
                _ownedSeaweeds.clear();
                _ownedSeaweeds.addAll(
                  SlotMachine.seaweedList.map(
                    (e) => Map<String, dynamic>.from(e),
                  ),
                );
                // 💡 해금 후 수조의 헤엄치는 목록을 초기화하고 기본 복어만 넣어줌으로써 ID 불일치 및 가득 참 현상 방지
                _swimmingFishIds.clear();
                _swimmingFishIds.add('fish_default_0');
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
            onAddDeco: _onAddDeco,
            onBuyItem: (type, cost, amount) {
              setState(() {
                _coins -= cost;
                if (type == 'feed') {
                  _feedCount += amount;
                } else if (type == 'supplement') {
                  _supplementCount += amount;
                }
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
          // 5. 설정 탭 (게임 설정)
          SettingsScreen(
            onSaveToCloud: _saveToCloud,
            onLoadFromCloud: _loadFromCloud,
          ),
        ],
      ),
      // 3. 픽셀 스타일 하단 네비게이션 바
      bottomNavigationBar: SafeArea(
        top: false, // 하단 아이폰 홈 바 여백 보호
        child: SizedBox(
          height: 56, // IntrinsicHeight 대신 안전하고 렌더링이 빠른 고정 높이 사용
          child: Row(
            children: [
              _buildPixelBottomNavItem(0, 'fish', '내 수조'),
              _buildPixelBottomNavItem(1, 'memo', '할 일'),
              _buildPixelBottomNavItem(2, 'trophy', '미션'),
              _buildPixelBottomNavItem(3, 'coin', '상점'),
              _buildPixelBottomNavItem(4, 'gear', '설정'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 픽셀 감성 삼각형 접기/펼치기 아이콘 위젯 ---
class PixelTriangle extends StatelessWidget {
  final bool isExpanded;
  final double size;
  final Color color;

  const PixelTriangle({
    super.key,
    required this.isExpanded,
    this.size = 14,
    this.color = const Color(0xFF212123),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelTrianglePainter(isExpanded, color),
    );
  }
}

class _PixelTrianglePainter extends CustomPainter {
  final bool isExpanded;
  final Color color;

  _PixelTrianglePainter(this.isExpanded, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // 💡 도트 아트 스타일 삼각형 패턴 (7x7 / 4x7 매트릭스)
    final List<List<int>> pixels = isExpanded
        ? [
            [1, 1, 1, 1, 1, 1, 1],
            [0, 1, 1, 1, 1, 1, 0],
            [0, 0, 1, 1, 1, 0, 0],
            [0, 0, 0, 1, 0, 0, 0],
          ]
        : [
            [1, 0, 0, 0],
            [1, 1, 0, 0],
            [1, 1, 1, 0],
            [1, 1, 1, 1],
            [1, 1, 1, 0],
            [1, 1, 0, 0],
            [1, 0, 0, 0],
          ];

    final int rows = pixels.length;
    final int cols = pixels[0].length;

    final double cellSize = size.width / 7.0; // 7픽셀 기준으로 셀크기 통일
    final double startX = (size.width - (cols * cellSize)) / 2;
    final double startY = (size.height - (rows * cellSize)) / 2;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (pixels[y][x] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              startX + x * cellSize,
              startY + y * cellSize,
              cellSize + 0.1,
              cellSize + 0.1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelTrianglePainter oldDelegate) {
    return oldDelegate.isExpanded != isExpanded || oldDelegate.color != color;
  }
}

