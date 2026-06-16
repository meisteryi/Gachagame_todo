import 'package:flutter/material.dart';

class BouncingWrapper extends StatefulWidget {
  final Widget child;
  final bool showShadow;
  const BouncingWrapper({
    super.key,
    required this.child,
    this.showShadow = true,
  });

  @override
  State<BouncingWrapper> createState() => _BouncingWrapperState();
}

class _BouncingWrapperState extends State<BouncingWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (mounted) setState(() => _isPressed = true);
      },
      onPointerUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 고정된 그림자 (위젯의 형태를 그대로 본따 검은색으로 우하단에 고정)
          if (widget.showShadow)
            Transform.translate(
              offset: const Offset(2, 2),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF333333),
                  BlendMode.srcIn,
                ),
                child: widget.child,
              ),
            ),
          // 2. 실제 버튼 내용물 (눌리면 그림자 위치로 이동하여 덮음)
          AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            transform: Matrix4.translationValues(
              _isPressed ? 2.0 : 0.0,
              _isPressed ? 2.0 : 0.0,
              0.0,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
