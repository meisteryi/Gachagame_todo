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
    with SingleTickerProviderStateMixin {
  AnimationController? _fishController;

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
                          final double w = 320.0 - 60.0; // 어항 가로 - 물고기 가로 길이
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
                            y = h / 2 - (h / 4 * t) + sin(t * pi * 10) * 8;
                            flipX = true;
                          } else if (v < 0.6) {
                            // 모션 3: 크게 빙글 루프(회전) 돌며 전진하기
                            final t = (v - 0.4) * 5;
                            x = (w / 2) * t + sin(t * pi * 2) * 40;
                            y =
                                h / 4 +
                                (h / 4) * t +
                                (1 - cos(t * pi * 2)) * 40;
                            flipX = cos(t * pi * 2) < -0.5; // 거꾸로 돌 때 방향 반전
                          } else if (v < 0.8) {
                            // 모션 4: 바닥을 향해 지그재그로 통통 튀며 전진
                            final t = (v - 0.6) * 5;
                            x = (w / 2) + (w / 2) * t;
                            final frac = t * 6 % 1;
                            y =
                                h / 2 +
                                (frac < 0.5 ? frac * 2 : (1 - frac) * 2) * 35;
                            flipX = false;
                          } else {
                            // 모션 5: 바닥을 훑고 부드럽게 위로 올라오며 복귀
                            final t = (v - 0.8) * 5;
                            x = w - (w * t);
                            y = h / 2 + 50 * sin(t * pi) + sin(t * pi * 4) * 15;
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
                        child: PixelFish(type: widget.swimmingFishType),
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
            onPressed: widget.onShowStorage,
            icon: const Icon(Icons.inventory_2),
            label: const Text('보관함'),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
