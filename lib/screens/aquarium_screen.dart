// 내 수조 화면 분리 완료
import 'dart:math';
import 'package:flutter/material.dart';
import '../pixel_fish.dart';

class AquariumScreen extends StatefulWidget {
  final String swimmingFishType;
  final VoidCallback onShowStorage;

  const AquariumScreen({
    super.key,
    required this.swimmingFishType,
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

  @override
  void initState() {
    super.initState();
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(); // 15초 주기로 5가지 모션을 수행하며 무한 반복

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
  (Offset, bool) _getNormalFishPosAndFlip(double v, double w, double h) {
    double x = 0;
    double y = 0;
    bool flipX = false;

    if (v < 0.2) {
      final t = v * 5;
      x = w * t;
      y = h / 2 + sin(t * pi * 4) * 30;
      flipX = false;
    } else if (v < 0.4) {
      final t = (v - 0.2) * 5;
      x = w - (w * t);
      y = h / 2 - (h / 4 * t) + sin(t * pi * 10) * 8;
      flipX = true;
    } else if (v < 0.6) {
      final t = (v - 0.4) * 5;
      x = (w / 2) * t + sin(t * pi * 2) * 40;
      y = h / 4 + (h / 4) * t + (1 - cos(t * pi * 2)) * 40;
      flipX = cos(t * pi * 2) < -0.5;
    } else if (v < 0.8) {
      final t = (v - 0.6) * 5;
      x = (w / 2) + (w / 2) * t;
      final frac = t * 6 % 1;
      y = h / 2 + (frac < 0.5 ? frac * 2 : (1 - frac) * 2) * 35;
      flipX = false;
    } else {
      final t = (v - 0.8) * 5;
      x = w - (w * t);
      y = h / 2 + 50 * sin(t * pi) + sin(t * pi * 4) * 15;
      flipX = true;
    }
    return (Offset(x, y), flipX);
  }

  // 🐟 먹이 주기 로직
  void _startFeeding() {
    if (_isFeeding) return; // 이미 먹이를 먹는 중이면 중복 실행 방지

    setState(() {
      _isFeeding = true;
    });

    // 먹이를 주는 순간의 위치를 기록하여 현재 위치에서 자연스럽게 수면으로 향하도록 함
    final v = _fishController?.value ?? 0.0;
    final double w = 320.0 - 60.0;
    final double h = 320.0 - 40.0 - 30.0;

    final (startOffset, _) = _getNormalFishPosAndFlip(v, w, h);
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                // 💡 윗부분 하얀 선 제거 (왼쪽, 오른쪽, 아래만 테두리 적용)
                border: const Border(
                  left: BorderSide(color: Colors.white54, width: 4),
                  right: BorderSide(color: Colors.white54, width: 4),
                  bottom: BorderSide(color: Colors.white54, width: 4),
                ),
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
                  // 수면 및 물 표현
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(26),
                          bottomRight: Radius.circular(26),
                        ),
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
                      decoration: BoxDecoration(
                        color: Colors.brown.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(26),
                          bottomRight: Radius.circular(26),
                        ),
                      ),
                    ),
                  ),
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
                        double x = 0;
                        double y = 0;
                        bool flipX = false;
                        List<Widget> effectWidgets =
                            []; // 3개의 먹이 조각 + 하트 이펙트 리스트

                        if (_isFeeding) {
                          final feedV = _feedController!.value;
                          final targetX = w / 2; // 수면 중앙 위치
                          final targetY = 20.0; // 수면 높이
                          final waterSurfaceY = 37.0; // 수면 경계선의 Y 위치

                          if (feedV < 0.2) {
                            // 1. 먹이가 수면에 떨어질 때까지 대기
                            x = _feedStartX;
                            y = _feedStartY;
                            flipX = targetX < _feedStartX;
                          } else if (feedV < 0.4) {
                            // 2. 수면으로 올라가는 모션
                            final t = (feedV - 0.2) / 0.2;
                            x = _feedStartX + (targetX - _feedStartX) * t;
                            y = _feedStartY + (targetY - _feedStartY) * t;
                            flipX = targetX < _feedStartX;
                          } else if (feedV < 0.7) {
                            // 3. 수면에서 먹이를 냠냠 먹는 모션 (앞뒤, 위아래로 살짝 통통 튐)
                            x = targetX + sin((feedV - 0.4) * pi * 10) * 3;
                            y = targetY + sin((feedV - 0.4) * pi * 15) * 3;
                            flipX = targetX < _feedStartX;
                          } else {
                            // 4. 밥을 다 먹고 원래 있어야 할 궤도로 부드럽게 복귀
                            final t = (feedV - 0.7) / 0.3;
                            final (
                              nextOffset,
                              nextFlip,
                            ) = _getNormalFishPosAndFlip(
                              _fishController!.value,
                              w,
                              h,
                            );
                            x = targetX + (nextOffset.dx - targetX) * t;
                            y = targetY + (nextOffset.dy - targetY) * t;
                            // 거의 도착했을 때쯤 자연스럽게 방향을 변경
                            flipX = t > 0.8
                                ? nextFlip
                                : (nextOffset.dx < targetX);
                          }

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
                              // 수면에 도달하여 동동 떠다님
                              currentY =
                                  waterSurfaceY +
                                  sin((feedV - dropEnd) * pi * 8) * 1.5;
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
                            buildFood(0.0, 0.15, 0.45, -12, Colors.brown[700]!),
                          );
                          effectWidgets.add(
                            buildFood(0.05, 0.20, 0.55, 0, Colors.brown[800]!),
                          );
                          effectWidgets.add(
                            buildFood(0.10, 0.25, 0.65, 12, Colors.brown[900]!),
                          );

                          // 밥을 먹는 타이밍에 맞춰 하트 3개 뿅뿅 발사
                          effectWidgets.add(buildHeart(0.40, 0.4, -15));
                          effectWidgets.add(buildHeart(0.48, 0.4, 5));
                          effectWidgets.add(buildHeart(0.55, 0.4, -5));
                        } else {
                          // 평상시 유영 로직
                          final v = _fishController!.value;
                          final (normalOffset, normalFlip) =
                              _getNormalFishPosAndFlip(v, w, h);
                          x = normalOffset.dx;
                          y = normalOffset.dy;
                          flipX = normalFlip;
                        }

                        // 💡 Stack 내부가 Positioned 자식만 있어서 크기가 0이 되어 잘리는 현상 해결!
                        return SizedBox.expand(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 🌊 흔들리는 도트 수면 효과 애니메이션 연동
                              Positioned(
                                top: 38,
                                left: 0,
                                right: 0,
                                height: 10,
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
                                child: Transform.scale(
                                  scaleX: flipX ? -1 : 1, // 방향에 맞게 좌우 반전
                                  alignment: Alignment.center,
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
          child: FloatingActionButton.extended(
            onPressed: widget.onShowStorage,
            icon: const Icon(Icons.inventory_2),
            label: const Text('보관함'),
            backgroundColor: Colors.white,
          ),
        ),
        // 먹이 주기 버튼 (왼쪽 배치)
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton.extended(
            onPressed: _startFeeding,
            icon: const Icon(Icons.restaurant),
            label: const Text('먹이 주기'),
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// --- 🌊 도트 느낌의 흔들리는 수면 애니메이션 ---
class PixelWaterSurfacePainter extends CustomPainter {
  final double time;

  PixelWaterSurfacePainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    const double dotSize = 4.0;

    // 수면 폭을 도트 크기로 나누어 가로로 촘촘하게 그립니다.
    for (double x = 0; x < size.width; x += dotSize) {
      // x좌표와 무한 반복되는 time 값을 결합해 도트형 사인파(물결) 생성
      double wave = sin((x * 0.05) - (time * pi * 10));
      double y = wave * 2.0; // 위아래로 2픽셀씩 통통 튀며 흔들림

      canvas.drawRect(Rect.fromLTWH(x, y, dotSize, dotSize), paint);
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
