// 내 수조 화면 분리 완료
import 'dart:math';
import 'package:flutter/material.dart';
import '../pixel_fish.dart';
import '../pixel_seaweed.dart';
import '../pixel_emoji.dart';

class AquariumScreen extends StatefulWidget {
  final String swimmingFishType;
  final List<Map<String, dynamic>> plantedSeaweeds;
  final int feedCount;
  final VoidCallback onFeed;
  final ValueChanged<List<Map<String, dynamic>>> onUpdateSeaweeds;
  final VoidCallback onShowStorage;

  const AquariumScreen({
    super.key,
    required this.swimmingFishType,
    required this.plantedSeaweeds,
    required this.feedCount,
    required this.onFeed,
    required this.onUpdateSeaweeds,
    required this.onShowStorage,
  });

  @override
  State<AquariumScreen> createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  AnimationController? _fishController;
  AnimationController? _feedController; // 🌟 먹이 애니메이션 전용 컨트롤러 추가

  bool _isFeeding = false;
  double _feedStartX = 0;
  double _feedStartY = 0;
  bool _isEditMode = false; // 🌟 수초 편집 모드

  @override
  void initState() {
    super.initState();
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(); // 30초 주기로 10가지 모션을 수행하며 무한 반복

    _feedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // 2.5초간 먹이 이벤트 진행
    );
  }

  @override
  void dispose() {
    _fishController?.dispose();
    _feedController?.dispose();
    super.dispose();
  }

  // 평상시 물고기의 유영 궤도를 계산하는 헬퍼 함수 (재사용성 및 애니메이션 보간을 위해 분리)
  (Offset, bool) _getNormalFishPosAndFlip(
    String type,
    double v,
    double w,
    double h,
  ) {
    double x = 0;
    double y = 0;
    bool flipX = false;

    if (type == 'jellyfish') {
      // 🪼 해파리: 위아래로 강하게 펄스 치며 수직 이동 강조, 느린 수평 이동
      double drift = sin(v * pi * 2); // 30초 동안 1번 좌우 왕복 (거북이처럼 느리게)
      x = w / 2 + drift * (w / 2.5);
      // % 대신 연속적인 사인 곡선을 사용하여 위치가 뚝 끊기지 않게 보정
      double pulse = (sin(v * pi * 20) + 1.0) / 2.0; // 펄스(맥박) 주기를 3배 느리게 완화
      y = h * 0.4 + sin(v * pi * 2) * (h * 0.2) - (pulse * 20.0);
      flipX = drift < 0;
    } else if (type == 'seahorse') {
      // 🐉 해마: 꼿꼿하게 서서 위아래로 통통 튀며 아주 느리게 전진
      double t = v * 2; // 30초 동안 좌우 왕복 1회
      x = (w / 2) + sin(t * pi * 2) * (w * 0.4);
      y = h * 0.6 + sin(v * pi * 30) * 12; // 빠르게 통통 튀기 (조금 더 부드럽게 완화)
      flipX = cos(t * pi * 2) < 0;
    } else if (type == 'shrimp') {
      // 🦐 새우: 바닥을 기어가다가 연속성을 유지하며 뒤로 펄쩍 뜀
      double cycleV = (v * 4) % 1.0; // 30초 동안 4사이클
      int cycle = (v * 4).floor();
      bool isMovingRight = cycle % 2 == 0; // 지그재그 방향

      double xProgress;
      if (cycleV < 0.8) {
        // 0.0 ~ 0.8 동안 목표 지점보다 살짝 더 전진 (1.1배)
        xProgress = (cycleV / 0.8) * 1.1;
        double subT = cycleV / 0.8;
        y = h * 0.95 - (sin(subT * pi * 16).abs() * 4); // 바닥을 꼬물꼬물
      } else {
        // 0.8 ~ 1.0 동안 초과했던 0.1만큼 뒤로 후퇴하며 펄쩍 뜀!
        double subT = (cycleV - 0.8) / 0.2;
        xProgress = 1.1 - (subT * 0.1);
        y = h * 0.95 - (sin(subT * pi) * 35); // 부드러운 포물선 점프
      }

      x = isMovingRight
          ? (w * 0.1) + (w * 0.8 * xProgress)
          : (w * 0.9) - (w * 0.8 * xProgress);

      flipX = !isMovingRight; // 점프 시에도 시선 유지
    } else {
      // 🐟 일반 물고기 그룹 (10단계 다채로운 모션)
      double timeV = v;
      bool isFast = type == 'shark' || type == 'mackerel' || type == 'tuna';
      bool isBottom =
          type == 'stingray' || type == 'turtle' || type == 'axolotl';

      if (isFast) {
        timeV = (v * 2.0) % 1.0; // 💡 애니메이션 루프가 끊기지 않도록 정수배(2.0배)로 수정
      }
      if (isBottom) {
        timeV = (v * 1.0) % 1.0; // 💡 애니메이션 루프가 끊기지 않도록 정수배(1.0배)로 수정
      }

      if (timeV < 0.1) {
        final t = timeV * 10;
        x = (w * 0.8) * t;
        y = h / 2 + sin(t * pi * 2) * 20;
        flipX = false;
      } else if (timeV < 0.2) {
        final t = (timeV - 0.1) * 10;
        x = (w * 0.8) - (w * 0.4 * t);
        y = h / 2 + (h * 0.2 * t) + sin(t * pi * 4) * 10;
        flipX = true;
      } else if (timeV < 0.3) {
        final t = (timeV - 0.2) * 10;
        x = (w * 0.4) + (w * 0.6 * t);
        y = h * 0.7 - (h * 0.4 * t);
        flipX = false;
      } else if (timeV < 0.4) {
        final t = (timeV - 0.3) * 10;
        x = w - (w * 0.8 * t);
        y = h * 0.3 + sin(t * pi * 2) * 30;
        flipX = true;
      } else if (timeV < 0.5) {
        final t = (timeV - 0.4) * 10;
        x = (w * 0.2) + sin(t * pi * 2) * 40;
        y = h * 0.3 + (h * 0.4 * t) - cos(t * pi * 2) * 40 + 40;
        flipX = cos(t * pi * 2) < -0.5;
      } else if (timeV < 0.6) {
        final t = (timeV - 0.5) * 10;
        x = (w * 0.2) + (w * 0.7 * t);
        final frac = (t * 2) % 1.0;
        y = h * 0.7 - (frac < 0.5 ? frac * 2 : (1 - frac) * 2) * 20;
        flipX = false;
      } else if (timeV < 0.7) {
        final t = (timeV - 0.6) * 10;
        x = (w * 0.9) - (w * 0.5 * t);
        y = h * 0.7 + sin(t * pi) * 30;
        flipX = true;
      } else if (timeV < 0.8) {
        final t = (timeV - 0.7) * 10;
        x = (w * 0.4) + (w * 0.4 * t);
        y = h * 0.7 - (h * 0.5 * t) + sin(t * pi * 3) * 15;
        flipX = false;
      } else if (timeV < 0.9) {
        final t = (timeV - 0.8) * 10;
        x = (w * 0.8) - (w * 0.6 * t);
        y = h * 0.2 + (h * 0.3 * t);
        flipX = true;
      } else {
        final t = (timeV - 0.9) * 10;
        x = (w * 0.2) - (w * 0.2 * t);
        y = h * 0.5 + sin(t * pi * 2) * 20;
        flipX = true;
      }

      // 가오리나 거북이는 바닥에 깔려서 헤엄치도록 y 반경을 아래로 보정
      if (isBottom) {
        y = (y * 0.4) + (h * 0.55);
      }
    }
    return (Offset(x, y), flipX);
  }

  // 현재 물고기의 위치와 좌우 반전 상태를 계산하는 통합 함수 (회전각 계산을 위한 미래 위치 예측용)
  (double, double, bool) _getFishPose(
    String type,
    bool isFeeding,
    double fishV,
    double feedV,
    double w,
    double h,
  ) {
    double x = 0;
    double y = 0;
    bool flipX = false;

    if (isFeeding && feedV > 0.0) {
      final targetX = w / 2;
      final targetY = 20.0;

      if (feedV < 0.2) {
        x = _feedStartX;
        y = _feedStartY;
        flipX = targetX < _feedStartX;
      } else if (feedV < 0.4) {
        final t = (feedV - 0.2) / 0.2;
        x = _feedStartX + (targetX - _feedStartX) * t;
        y = _feedStartY + (targetY - _feedStartY) * t;
        flipX = targetX < _feedStartX;
      } else if (feedV < 0.7) {
        x = targetX + sin((feedV - 0.4) * pi * 10) * 3;
        y = targetY + sin((feedV - 0.4) * pi * 15) * 3;
        flipX = targetX < _feedStartX;
      } else {
        final t = (feedV - 0.7) / 0.3;
        final (nextOffset, nextFlip) = _getNormalFishPosAndFlip(
          type,
          fishV,
          w,
          h,
        );
        x = targetX + (nextOffset.dx - targetX) * t;
        y = targetY + (nextOffset.dy - targetY) * t;
        flipX = t > 0.8 ? nextFlip : (nextOffset.dx < targetX);
      }
    } else {
      final (normalOffset, normalFlip) = _getNormalFishPosAndFlip(
        type,
        fishV,
        w,
        h,
      );
      x = normalOffset.dx;
      y = normalOffset.dy;
      flipX = normalFlip;
    }
    return (x, y, flipX);
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

  // 🐟 먹이 주기 로직
  void _startFeeding() {
    if (_isFeeding) return; // 이미 먹이를 먹는 중이면 중복 실행 방지

    if (widget.feedCount <= 0) {
      _showNoticeDialog('남은 먹이가 없습니다! 🍗');
      return;
    }

    widget.onFeed(); // 💡 먹이 개수 -1 차감 및 상태 저장 알림

    setState(() {
      _isFeeding = true;
    });

    // 먹이를 주는 순간의 위치를 기록하여 현재 위치에서 자연스럽게 수면으로 향하도록 함
    final v = _fishController?.value ?? 0.0;
    final double w = 320.0 - 60.0;
    final double h = 320.0 - 40.0 - 30.0;

    final (startOffset, _) = _getNormalFishPosAndFlip(
      widget.swimmingFishType,
      v,
      w,
      h,
    );
    _feedStartX = startOffset.dx;
    _feedStartY = startOffset.dy;

    _feedController?.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isFeeding = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                color: Colors.white.withValues(alpha: 0.05), // 물 밖의 빈 유리 느낌
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none, // 💡 수조 밖에서 떨어지는 먹이가 잘리지 않게 설정
                children: [
                  // 수면 및 물 표현 (도트 수조에 맞게 둥근 모서리 제거)
                  Positioned(
                    top: 40,
                    left: 4, // 도트 테두리 두께(4)만큼 안쪽으로
                    right: 4,
                    bottom: 4,
                    child: Container(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                    ),
                  ),
                  // 🧊 도트 수조 테두리 및 텍스처 모래 바닥
                  Positioned.fill(
                    child: CustomPaint(painter: PixelTankPainter()),
                  ),
                  // 🌱 여러 개의 수초를 바닥에 배치 및 편집 가능하게 구성
                  if (_fishController != null)
                    ...widget.plantedSeaweeds.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final Map<String, dynamic> seaweed = entry.value;
                      final double x =
                          (seaweed['x'] as num?)?.toDouble() ?? 140.0;

                      return Positioned(
                        key: ObjectKey(
                          seaweed,
                        ), // 💡 순서가 바뀌어도 드래그가 끊기지 않도록 고유 키 부여
                        bottom: 25,
                        left: x,
                        child: Listener(
                          onPointerDown: _isEditMode
                              ? (_) {
                                  // 💡 터치 시 해당 수초를 배열 맨 끝으로 보내서 화면 맨 앞(위)으로 렌더링
                                  if (idx !=
                                      widget.plantedSeaweeds.length - 1) {
                                    setState(() {
                                      widget.plantedSeaweeds.remove(seaweed);
                                      widget.plantedSeaweeds.add(seaweed);
                                    });
                                    widget.onUpdateSeaweeds(
                                      widget.plantedSeaweeds,
                                    );
                                  }
                                }
                              : null,
                          child: GestureDetector(
                            onPanUpdate: _isEditMode
                                ? (details) {
                                    setState(() {
                                      seaweed['x'] = (x + details.delta.dx)
                                          .clamp(10.0, 280.0); // 어항 범위 제한
                                    });
                                  }
                                : null,
                            onPanEnd: _isEditMode
                                ? (_) => widget.onUpdateSeaweeds(
                                    widget.plantedSeaweeds,
                                  )
                                : null,
                            onDoubleTap: _isEditMode
                                ? () {
                                    setState(() {
                                      widget.plantedSeaweeds.remove(
                                        seaweed,
                                      ); // 💡 바뀐 순서에 맞춰 안전하게 객체로 삭제
                                    });
                                    widget.onUpdateSeaweeds(
                                      widget.plantedSeaweeds,
                                    );
                                  }
                                : null,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  color: Colors.transparent, // 💡 드래그 터치 영역 확보
                                  child: Container(
                                    decoration: _isEditMode
                                        ? BoxDecoration(
                                            border: Border.all(
                                              color: Colors.redAccent,
                                              width: 2,
                                            ),
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.2,
                                            ),
                                          )
                                        : null,
                                    child: Transform.scale(
                                      alignment: Alignment.bottomCenter,
                                      scale: 1.5,
                                      child: PixelSeaweed(
                                        type: seaweed['type'] ?? 'green_algae',
                                      ),
                                    ),
                                  ),
                                ),
                                // 💡 왼쪽 도트 화살표
                                if (_isEditMode)
                                  Positioned(
                                    left: -12,
                                    child: CustomPaint(
                                      size: const Size(6, 10),
                                      painter: PixelArrowPainter(isLeft: true),
                                    ),
                                  ),
                                // 💡 오른쪽 도트 화살표
                                if (_isEditMode)
                                  Positioned(
                                    right: -12,
                                    child: CustomPaint(
                                      size: const Size(6, 10),
                                      painter: PixelArrowPainter(isLeft: false),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  // 헤엄치는 2D 도트 물고기 & 떨어지는 먹이 효과 결합
                  if (_fishController != null && _feedController != null)
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _fishController!,
                        _feedController!,
                      ]),
                      builder: (context, child) {
                        final double w = 320.0 - 60.0; // 어항 가로 - 물고기 가로 길이
                        final double h =
                            320.0 - 40.0 - 30.0; // 어항 세로 - 물고기 - 모래
                        List<Widget> effectWidgets =
                            []; // 3개의 먹이 조각 + 하트 이펙트 리스트

                        final fishV = _fishController!.value;
                        final feedV = _isFeeding ? _feedController!.value : 0.0;

                        final currentPose = _getFishPose(
                          widget.swimmingFishType,
                          _isFeeding,
                          fishV,
                          feedV,
                          w,
                          h,
                        );
                        final double x = currentPose.$1;
                        final double y = currentPose.$2;
                        final bool flipX = currentPose.$3;

                        // 🌟 방향에 맞게 기울기(회전 각도) 계산을 위해 아주 살짝 미래의 위치를 구함
                        final nextFishV = (fishV + 0.005) % 1.0;
                        final nextFeedV = _isFeeding
                            ? min(1.0, feedV + 0.005)
                            : 0.0;
                        final nextPose = _getFishPose(
                          widget.swimmingFishType,
                          _isFeeding,
                          nextFishV,
                          nextFeedV,
                          w,
                          h,
                        );

                        double tiltAngle = 0.0;
                        if (_isFeeding && feedV >= 0.4 && feedV < 0.7) {
                          tiltAngle = -0.2; // 먹이를 먹을 땐 살짝 위를 향함
                        } else if (_isFeeding && feedV < 0.2) {
                          tiltAngle = 0.0; // 먹이 떨어지길 대기할 땐 평형 유지
                        } else {
                          double dx = nextPose.$1 - x;
                          double dy = nextPose.$2 - y;
                          // 움직임이 있을 때만 각도 계산
                          if (dx.abs() > 0.01 || dy.abs() > 0.01) {
                            tiltAngle = flipX ? atan2(dy, -dx) : atan2(dy, dx);
                          }
                        }

                        // 💡 해파리, 해마처럼 수직으로 서서 다니는 생물은 회전(기울기)을 제한합니다.
                        if (widget.swimmingFishType == 'jellyfish' ||
                            widget.swimmingFishType == 'seahorse') {
                          tiltAngle = 0.0;
                        }
                        // 새우는 바닥 기어다니거나 뒤로 펄쩍 뛰므로 각도를 약간만 줌
                        if (widget.swimmingFishType == 'shrimp') {
                          tiltAngle *= 0.3;
                        }

                        if (_isFeeding) {
                          final targetX = w / 2; // 수면 중앙 위치
                          final targetY = 20.0; // 수면 높이
                          final waterSurfaceY = 37.0; // 수면 경계선의 Y 위치

                          // 🌟 시간차를 두고 떨어지는 개별 먹이 UI 함수
                          Widget buildFood(
                            double delay,
                            double dropEnd,
                            double eatTime,
                            double offsetX,
                            Color color,
                          ) {
                            if (feedV > eatTime) {
                              return const SizedBox.shrink(); // 다 먹으면 사라짐
                            }

                            double currentY;
                            if (feedV < delay) {
                              currentY = -150.0; // 아직 떨어지기 전 (수조 밖 대기)
                            } else if (feedV < dropEnd) {
                              final fallT = (feedV - delay) / (dropEnd - delay);
                              // 포물선을 그리며 중력에 의해 떨어짐
                              currentY =
                                  -150.0 +
                                  (waterSurfaceY - (-150.0)) * (fallT * fallT);
                            } else {
                              // 수면에 도달하여 동동 떠다님 (도트 느낌으로 4px 단위 스냅)
                              currentY =
                                  waterSurfaceY +
                                  (sin((feedV - dropEnd) * pi * 8) > 0
                                      ? 4.0
                                      : 0.0);
                            }

                            return Positioned(
                              left: 157 + offsetX, // 수조 폭(320)/2 = 160 근처 배치
                              top: currentY,
                              child: Container(
                                width: 6,
                                height: 6,
                                color: color,
                              ),
                            );
                          }

                          // 💖 먹이를 먹고 난 뒤 떠오르는 광택 픽셀 하트 UI 함수
                          Widget buildHeart(
                            double delay,
                            double duration,
                            double offsetX,
                          ) {
                            if (feedV < delay) return const SizedBox.shrink();
                            double progress = (feedV - delay) / duration;
                            if (progress > 1.0) return const SizedBox.shrink();

                            double currentY =
                                targetY -
                                5 -
                                (progress * 40); // 입 주변에서 위로 둥둥 떠오름
                            double currentX =
                                targetX +
                                25 +
                                offsetX +
                                sin(progress * pi * 4) * 6; // 좌우로 살짝 흔들림

                            return Positioned(
                              left: currentX,
                              top: currentY,
                              child: CustomPaint(
                                size: const Size(15, 15),
                                painter: PixelHeartPainter(
                                  (1.0 - progress).clamp(0.0, 1.0),
                                ),
                              ),
                            );
                          }

                          // 높이(시간) 차이를 두고 3조각 생성
                          effectWidgets.add(
                            buildFood(
                              0.0,
                              0.15,
                              0.45,
                              -12,
                              const Color.fromARGB(255, 202, 119, 94),
                            ),
                          );
                          effectWidgets.add(
                            buildFood(
                              0.05,
                              0.20,
                              0.55,
                              0,
                              const Color.fromARGB(255, 189, 128, 115),
                            ),
                          );
                          effectWidgets.add(
                            buildFood(0.10, 0.25, 0.65, 12, Colors.brown[900]!),
                          );

                          // 밥을 먹는 타이밍에 맞춰 하트 3개 뿅뿅 발사
                          effectWidgets.add(buildHeart(0.40, 0.4, -15));
                          effectWidgets.add(buildHeart(0.48, 0.4, 5));
                          effectWidgets.add(buildHeart(0.55, 0.4, -5));
                        }

                        // 💡 Stack 내부가 Positioned 자식만 있어서 크기가 0이 되어 잘리는 현상 해결!
                        return SizedBox.expand(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 🌊 흔들리는 도트 수면 효과 애니메이션 연동
                              Positioned(
                                top: 36,
                                left: 0,
                                right: 0,
                                height: 16,
                                child: CustomPaint(
                                  painter: PixelWaterSurfacePainter(
                                    _fishController!.value,
                                  ),
                                ),
                              ),
                              ...effectWidgets, // 먹이 조각과 하트 이펙트 일괄 배치
                              Positioned(
                                left: x,
                                top: y,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(
                                    flipX ? -1.0 : 1.0, // 좌우 반전 적용
                                    1.0,
                                    1.0,
                                  )..rotateZ(tiltAngle), // 이동 방향에 맞게 회전 추가
                                  child: child!,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: PixelFish(type: widget.swimmingFishType),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: PixelButton(
            color: Colors.white,
            textColor: Colors.black,
            onPressed: widget.onShowStorage,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelEmoji('box', size: 18),
                SizedBox(width: 6),
                Text('보관함'),
              ],
            ),
          ),
        ),
        // 먹이 주기 버튼 (왼쪽 배치)
        Positioned(
          bottom: 20,
          left: 20,
          child: PixelButton(
            color: Colors.orangeAccent,
            textColor: Colors.white,
            onPressed: _startFeeding,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelEmoji('meat', size: 18),
                SizedBox(width: 6),
                Text('먹이 주기'),
              ],
            ),
          ),
        ),
        // 🌿 수초 꾸미기 편집 모드 토글 버튼 (상단 우측)
        Positioned(
          top: 16,
          right: 16,
          child: PixelButton(
            color: _isEditMode ? Colors.greenAccent : Colors.white,
            textColor: Colors.black,
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isEditMode ? Icons.check : Icons.edit, size: 18),
                const SizedBox(width: 6),
                Text(_isEditMode ? '편집 완료' : '수초 편집'),
              ],
            ),
          ),
        ),
        // 💡 편집 모드일 때 안내 메시지
        if (_isEditMode)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                ),
                child: const Text(
                  '수초를 좌우로 드래그해서 옮기세요.\n더블탭하면 수조에서 삭제됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// --- ⬅️➡️ 수초 편집 모드용 도트 화살표 ---
class PixelArrowPainter extends CustomPainter {
  final bool isLeft;

  PixelArrowPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()..color = Colors.black;
    final fillPaint = Paint()..color = Colors.white;
    const double p = 2.0; // 픽셀 크기

    // 3x5 도트 매트릭스로 그리는 좌우 화살표
    final List<List<int>> pointsLeft = [
      [2, 0],
      [1, 1],
      [2, 1],
      [0, 2],
      [1, 2],
      [2, 2],
      [1, 3],
      [2, 3],
      [2, 4],
    ];
    final List<List<int>> pointsRight = [
      [0, 0],
      [0, 1],
      [1, 1],
      [0, 2],
      [1, 2],
      [2, 2],
      [0, 3],
      [1, 3],
      [0, 4],
    ];

    final points = isLeft ? pointsLeft : pointsRight;

    // 1. 외곽선(검은색) 먼저 그리기: 상하좌우 및 대각선으로 1픽셀(p)씩 빗겨서 배치
    final offsets = [
      Offset(-p, 0),
      Offset(p, 0),
      Offset(0, -p),
      Offset(0, p),
      Offset(-p, -p),
      Offset(p, -p),
      Offset(-p, p),
      Offset(p, p),
    ];

    for (var pt in points) {
      for (var offset in offsets) {
        canvas.drawRect(
          Rect.fromLTWH(pt[0] * p + offset.dx, pt[1] * p + offset.dy, p, p),
          outlinePaint,
        );
      }
    }

    // 2. 내부(흰색) 화살표 그리기
    for (var pt in points) {
      canvas.drawRect(Rect.fromLTWH(pt[0] * p, pt[1] * p, p, p), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PixelArrowPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft;
}

// --- 🌊 도트 느낌의 흔들리는 수면 애니메이션 ---
class PixelWaterSurfacePainter extends CustomPainter {
  final double time;

  PixelWaterSurfacePainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.4);
    final foamPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    const double p = 4.0; // dotSize를 p로 수정합니다!

    // 수면 폭을 도트 크기로 나누어 가로로 촘촘하게 그립니다.
    for (double x = p; x < size.width - p; x += p) {
      // 시간에 따른 사인파 생성
      double wave = sin((x * 0.05) - (time * pi * 8));

      // 부드러운 곡선 대신 픽셀 단위로 위치가 딱딱 끊기게(스냅) 설정
      double yOffset = (wave > 0.5) ? p : ((wave < -0.5) ? -p : 0);

      // 뒤쪽 짙은 물결 (그림자 느낌)
      canvas.drawRect(Rect.fromLTWH(x, yOffset + p, p, p), waterPaint);
      // 앞쪽 하얀 거품 물결
      canvas.drawRect(Rect.fromLTWH(x, yOffset, p, p), foamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PixelWaterSurfacePainter oldDelegate) => true;
}

// --- 💖 도트 느낌의 광택 있는 하트 애니메이션 ---
class PixelHeartPainter extends CustomPainter {
  final double opacity;

  PixelHeartPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final redPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: opacity);
    final darkRedPaint = Paint()
      ..color = Colors.red[900]!.withValues(alpha: opacity);
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity); // 광택 색상

    const double p = 3.0; // 픽셀 하나당 크기 (3x3 논리 픽셀)

    void drawPixel(int x, int y, Paint paint) =>
        canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);

    // 5x5 도트 매트릭스로 하트 그리기 (* 모양이 빛나는 광택 부분)
    // . X . X .
    drawPixel(1, 0, darkRedPaint);
    drawPixel(3, 0, darkRedPaint);
    // X * X X X
    drawPixel(0, 1, darkRedPaint);
    drawPixel(1, 1, shinePaint);
    drawPixel(2, 1, redPaint);
    drawPixel(3, 1, redPaint);
    drawPixel(4, 1, darkRedPaint);
    // X X X X X
    drawPixel(0, 2, darkRedPaint);
    drawPixel(1, 2, redPaint);
    drawPixel(2, 2, redPaint);
    drawPixel(3, 2, redPaint);
    drawPixel(4, 2, darkRedPaint);
    // . X X X .
    drawPixel(1, 3, darkRedPaint);
    drawPixel(2, 3, redPaint);
    drawPixel(3, 3, darkRedPaint);
    // . . X . .
    drawPixel(2, 4, darkRedPaint);
  }

  @override
  bool shouldRepaint(covariant PixelHeartPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

// --- 🧊 도트 느낌의 수조 테두리 및 모래 바닥 ---
class PixelTankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glassPaint = Paint()..color = Colors.white54;
    final sandPaint = Paint()..color = Colors.brown[400]!;
    final darkSandPaint = Paint()..color = Colors.brown[600]!;
    const double p = 4.0; // 픽셀 크기

    // 1. 수조 유리 테두리 (U자 형태, 두께 4px)
    for (double y = 0; y < size.height; y += p) {
      canvas.drawRect(Rect.fromLTWH(0, y, p, p), glassPaint); // 왼쪽 벽
      canvas.drawRect(
        Rect.fromLTWH(size.width - p, y, p, p),
        glassPaint,
      ); // 오른쪽 벽
    }
    for (double x = 0; x < size.width; x += p) {
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - p, p, p),
        glassPaint,
      ); // 바닥 벽
    }

    // 2. 도트 질감 모래 바닥
    final sandTop = size.height - 32;
    for (double y = sandTop; y < size.height - p; y += p) {
      for (double x = p; x < size.width - p; x += p) {
        // 위치 기반 난수로 어두운 모래알을 섞어 도트 질감 생성
        bool isDark = ((x * 13) + (y * 7)) % 17 < 5;
        canvas.drawRect(
          Rect.fromLTWH(x, y, p, p),
          isDark ? darkSandPaint : sandPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 🎮 레트로 감성의 8비트 도트 스타일 버튼 ---
class PixelButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const PixelButton({
    super.key,
    required this.child,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        // 눌렸을 때 아래로 4픽셀 이동하는 효과
        margin: EdgeInsets.only(
          top: _isPressed ? 4 : 0,
          bottom: _isPressed ? 0 : 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: Colors.black, width: 3), // 두꺼운 픽셀 테두리
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                ], // 도트 그림자
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
