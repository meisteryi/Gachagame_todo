import 'dart:math';
import 'package:flutter/material.dart';
import 'pixel_fish.dart';
import 'pixel_seaweed.dart';
import 'bouncing_wrapper.dart';
import 'pixel_emoji.dart';

class SlotMachine extends StatefulWidget {
  final String gachaType; // 'fish' 또는 'seaweed'
  final void Function(List<Map<String, dynamic>> drawnItems) onDrawDone;
  final bool Function(int cost) onSpinStart;

  const SlotMachine({
    super.key,
    required this.gachaType,
    required this.onDrawDone,
    required this.onSpinStart,
  });

  static const List<Map<String, dynamic>> fishList = [
    {'type': 'goldfish', 'name': '평범한 금붕어'},
    {'type': 'mackerel', 'name': '날쌘 고등어'},
    {'type': 'betta', 'name': '화려한 베타'},
    {'type': 'nemo', 'name': '귀여운 니모'},
    {'type': 'guppy', 'name': '조용한 구피'},
    {'type': 'shark', 'name': '무서운 상어'},
    {'type': 'whale', 'name': '전설의 흰수염고래'},
    {'type': 'axolotl', 'name': '귀여운 우파루파'},
    {'type': 'tuna', 'name': '은빛 참치'},
    {'type': 'shrimp', 'name': '통통한 새우'},
    {'type': 'seahorse', 'name': '꼬불꼬불 해마'},
    {'type': 'turtle', 'name': '느긋한 거북이'},
    {'type': 'jellyfish', 'name': '둥둥 해파리'},
    {'type': 'stingray', 'name': '납작한 가오리'},
  ];

  // 💡 수초 목록 추가!
  static const List<Map<String, dynamic>> seaweedList = [
    {'type': 'green_algae', 'name': '평범한 녹조류'},
    {'type': 'red_algae', 'name': '붉은 홍조류'},
    {'type': 'kelp', 'name': '길쭉한 다시마'},
    {'type': 'coral', 'name': '아름다운 산호'},
    {'type': 'anemone', 'name': '춤추는 말미잘'},
    {'type': 'purple_kelp', 'name': '보라색 미역'},
    {'type': 'short_grass', 'name': '짧은 잔디 수초'},
    {'type': 'blue_coral', 'name': '푸른 산호초'},
    {'type': 'tall_bamboo', 'name': '거대 대나무 수초'},
    {'type': 'golden_leaf', 'name': '황금빛 잎수초'},
  ];

  @override
  State<SlotMachine> createState() => _SlotMachineState();
}

class _SlotMachineState extends State<SlotMachine> {
  // 3개의 슬롯을 각각 굴리기 위한 컨트롤러
  late FixedExtentScrollController _ctrl1;
  late FixedExtentScrollController _ctrl2;
  late FixedExtentScrollController _ctrl3;

  bool _isSpinning = false; // 도는 중인지 확인
  bool _isPulling = false; // 레버를 당기는 중인지 확인

  @override
  void initState() {
    super.initState();
    _ctrl1 = FixedExtentScrollController(initialItem: 0);
    _ctrl2 = FixedExtentScrollController(initialItem: 0);
    _ctrl3 = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  // 현재 진행 중인 가챠의 아이템 리스트 반환
  List<Map<String, dynamic>> get _currentList => widget.gachaType == 'seaweed'
      ? SlotMachine.seaweedList
      : SlotMachine.fishList;

  // 타입에 따른 픽셀 위젯 렌더링
  Widget _buildItemWidget(String type) {
    return widget.gachaType == 'seaweed'
        ? PixelSeaweed(type: type)
        : PixelFish(type: type);
  }

  Future<void> _spin({int count = 1}) async {
    if (_isSpinning) return; // 이미 돌고 있으면 무시

    if (!widget.onSpinStart(count)) return; // 코인 부족 시 취소

    setState(() {
      _isSpinning = true;
      _isPulling = true;
    });

    // 1. 레버 당기는 애니메이션 짧게 대기 후 원상복구
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return; // 💡 비동기 대기 후 화면이 파괴되었으면 실행 취소

    setState(() {
      _isPulling = false;
    });

    // 2. 당첨될 물고기(들) 랜덤 선택
    final random = Random();
    final List<Map<String, dynamic>> winners = [];
    for (int i = 0; i < count; i++) {
      winners.add(_currentList[random.nextInt(_currentList.length)]);
    }

    // 슬롯머신이 시각적으로 멈출 목표는 첫 번째 당첨 아이템으로 설정
    final winIndex = _currentList.indexOf(winners.first);

    // 3. 현재 위치에서 몇 바퀴를 더 돌아서 목표 물고기에 도달할지 계산
    final current1 = _ctrl1.selectedItem;
    final current2 = _ctrl2.selectedItem;
    final current3 = _ctrl3.selectedItem;

    // (현재 위치의 나머지 보정 + 당첨 인덱스 + 추가 바퀴 수)
    final target1 =
        current1 +
        (_currentList.length - (current1 % _currentList.length)) +
        winIndex +
        (_currentList.length * 5);
    final target2 =
        current2 +
        (_currentList.length - (current2 % _currentList.length)) +
        winIndex +
        (_currentList.length * 8);
    final target3 =
        current3 +
        (_currentList.length - (current3 % _currentList.length)) +
        winIndex +
        (_currentList.length * 12);

    // 4. 슬롯 드르르륵 애니메이션 시작 (각각 다른 시간으로 설정해 리얼함 부여)
    _ctrl1.animateToItem(
      target1,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
    );
    _ctrl2.animateToItem(
      target2,
      duration: const Duration(seconds: 3),
      curve: Curves.easeOutCubic,
    );
    await _ctrl3.animateToItem(
      target3,
      duration: const Duration(seconds: 4),
      curve: Curves.easeOutCubic,
    );

    if (!mounted) return; // 💡 애니메이션이 끝난 후 화면이 파괴되었으면 실행 취소

    setState(() {
      _isSpinning = false;
    });

    // 5. 모두 멈추면 팝업 띄우기 함수 호출
    widget.onDrawDone(winners);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Text(
                  'GACHA MACHINE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 6
                      ..color = const Color(0xFF333333),
                  ),
                ),
                const Text(
                  'GACHA MACHINE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.pinkAccent,
                    shadows: [
                      Shadow(color: Color(0xFF333333), offset: Offset(3, 3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '할 일을 완료하고 코인을 모아보세요!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 화면이 좁은 기기에서 가로로 넘치지 않게 비율을 유지하며 축소
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 🎰 1. 화려해진 빠칭코 기계 본체
                  Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      color: widget.gachaType == 'seaweed'
                          ? const Color(0xFF85CAC5)
                          : const Color(0xFFFFB7B2), // 부드러운 기계 색상
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF333333),
                        width: 6,
                      ), // 검정 픽셀 테두리
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF333333),
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 기계 상단 화려한 전광판 간판
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF333333),
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'LUCKY GACHA',
                            style: TextStyle(
                              color: Color(0xFFFFF3B0),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        // 드르륵 돌아가는 슬롯 화면
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Row(
                                children: [
                                  _buildSlotColumn(_ctrl1),
                                  Container(
                                    width: 3,
                                    color: Colors.black87,
                                  ), // 슬롯 구분선
                                  _buildSlotColumn(_ctrl2),
                                  Container(width: 3, color: Colors.black87),
                                  _buildSlotColumn(_ctrl3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  // 🕹️ 2. 3D 효과가 적용된 앞으로 꺾이는 레버
                  GestureDetector(
                    onTap: _spin,
                    child: Container(
                      height: 180,
                      width: 50,
                      color: Colors.transparent, // 터치 영역 확보
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // 레버 받침대 기둥
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF333333),
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF333333),
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          // 움직이는 쇠막대와 빨간 공
                          Positioned(
                            bottom: 20,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              transformAlignment: Alignment.bottomCenter,
                              // ✨ 핵심 포인트: 3D 매트릭스로 X축을 회전시켜 사용자 쪽으로 쓰러지는 효과 연출!
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.003) // 원근감(Perspective) 부여
                                ..rotateX(
                                  _isPulling ? 1.2 : 0.0,
                                ), // 1.2 라디안(약 70도) 앞으로 당김
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 도트 느낌의 각진 빨간 손잡이
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB7B2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFF333333),
                                        width: 4,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF333333),
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 단색 픽셀 막대기
                                  Container(
                                    width: 16,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      border: Border(
                                        left: BorderSide(
                                          color: Color(0xFF333333),
                                          width: 4,
                                        ),
                                        right: BorderSide(
                                          color: Color(0xFF333333),
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // 3. 뽑기 버튼 (1회 / 10회)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                BouncingWrapper(
                  child: ElevatedButton(
                    onPressed: () => _spin(count: 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpinning
                          ? Colors.grey
                          : (widget.gachaType == 'seaweed'
                                ? const Color(0xFFA8D8B9)
                                : const Color(0xFFFFC6D3)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Color(0xFF333333),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '1회 뽑기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            PixelEmoji('coin', size: 16),
                            SizedBox(width: 4),
                            Text(
                              '1',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                BouncingWrapper(
                  child: ElevatedButton(
                    onPressed: () => _spin(count: 10),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpinning
                          ? Colors.grey
                          : (widget.gachaType == 'seaweed'
                                ? const Color(0xFF85CAC5)
                                : const Color(0xFFFFAAA5)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Color(0xFF333333),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '10연속 뽑기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            PixelEmoji('coin', size: 16),
                            SizedBox(width: 4),
                            Text(
                              '10',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 휠(슬롯) 하나를 만들어주는 함수
  Widget _buildSlotColumn(FixedExtentScrollController controller) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 65, // 슬롯 화면 높이에 맞게 크기 축소
        physics: const NeverScrollableScrollPhysics(), // 사용자가 직접 스크롤 불가능하게 고정
        childDelegate: ListWheelChildLoopingListDelegate(
          children: _currentList.map((item) {
            return Center(
              child: Transform.scale(
                scale: 1.3,
                child: _buildItemWidget(item['type']),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
