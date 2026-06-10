import 'dart:math';
import 'package:flutter/material.dart';
import 'pixel_fish.dart';

class SlotMachine extends StatefulWidget {
  final void Function(Map<String, dynamic> drawnFish) onDrawDone;

  const SlotMachine({super.key, required this.onDrawDone});

  // 💡 물고기 목록을 State 밖으로 분리! (핫 리로드 시에도 즉시 변경사항이 반영되도록 static 사용)
  static const List<Map<String, dynamic>> fishList = [
    {'type': 'goldfish', 'name': '평범한 금붕어'},
    {'type': 'mackerel', 'name': '날쌘 고등어'},
    {'type': 'puffer', 'name': '도트 복어'},
    {'type': 'shark', 'name': '무서운 상어'},
    {'type': 'whale', 'name': '전설의 흰수염고래'},
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

  Future<void> _spin() async {
    if (_isSpinning) return; // 이미 돌고 있으면 무시

    setState(() {
      _isSpinning = true;
      _isPulling = true;
    });

    // 1. 레버 당기는 애니메이션 짧게 대기 후 원상복구
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      _isPulling = false;
    });

    // 2. 당첨될 물고기 랜덤 선택
    final random = Random();
    final winIndex = random.nextInt(SlotMachine.fishList.length);

    // 3. 현재 위치에서 몇 바퀴를 더 돌아서 목표 물고기에 도달할지 계산
    final current1 = _ctrl1.selectedItem;
    final current2 = _ctrl2.selectedItem;
    final current3 = _ctrl3.selectedItem;

    // (현재 위치의 나머지 보정 + 당첨 인덱스 + 추가 바퀴 수)
    final target1 =
        current1 +
        (SlotMachine.fishList.length -
            (current1 % SlotMachine.fishList.length)) +
        winIndex +
        (SlotMachine.fishList.length * 5);
    final target2 =
        current2 +
        (SlotMachine.fishList.length -
            (current2 % SlotMachine.fishList.length)) +
        winIndex +
        (SlotMachine.fishList.length * 8);
    final target3 =
        current3 +
        (SlotMachine.fishList.length -
            (current3 % SlotMachine.fishList.length)) +
        winIndex +
        (SlotMachine.fishList.length * 12);

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

    setState(() {
      _isSpinning = false;
    });

    // 5. 모두 멈추면 팝업 띄우기 함수 호출
    final winner = SlotMachine.fishList[winIndex];
    widget.onDrawDone(winner);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '가챠 샵',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 10),
            const Text('할 일을 완료하고 코인을 모아보세요!'),
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
                      color: Colors.red[800], // 오락실 느낌의 강렬한 빨간색
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber,
                        width: 6,
                      ), // 금색 테두리
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 10),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 기계 상단 화려한 전광판 간판
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '🌟 LUCKY GACHA 🌟',
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.orange[900]!,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 드르륵 돌아가는 슬롯 화면
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black87,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
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
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(2, 5),
                                  blurRadius: 5,
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
                                  // 입체감이 있는 빨간 구슬
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.red[300]!,
                                          Colors.red[900]!,
                                        ],
                                        center: const Alignment(-0.3, -0.3),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 5,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 쇠 재질 막대기
                                  Container(
                                    width: 14,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[400]!,
                                          Colors.grey[700]!,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // 3. 뽑기 버튼
            ElevatedButton(
              onPressed: _spin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSpinning ? Colors.grey : Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                elevation: 5,
              ),
              child: Text(
                _isSpinning ? '가챠 진행 중...' : '물고기 뽑기 🐟',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          children: SlotMachine.fishList.map((fish) {
            return Center(
              child: Transform.scale(
                scale: 1.3,
                child: PixelFish(type: fish['type']),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
