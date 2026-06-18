import 'package:flutter/material.dart';

// 💡 버튼 색상을 받아 자동으로 은은한 상하 그라데이션을 생성해 주는 헬퍼 함수
LinearGradient getRetroGradient(Color baseColor) {
  if (baseColor == Colors.transparent) {
    return const LinearGradient(
      colors: [Colors.transparent, Colors.transparent],
    );
  }
  final hsl = HSLColor.fromColor(baseColor);

  // 💡 검은색 등 너무 어두운 색상은 밝기 조절만으로는 그라데이션이 안 보이므로 예외 처리
  if (hsl.lightness < 0.05) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF555555), Color(0xFF111111)], // 확실한 회색~검정 3D 효과
    );
  }

  // 💡 위쪽은 12% 밝게, 아래쪽은 10% 어둡게 만들어 이전보다 입체감을 더 확실하게 부여
  final topColor = hsl
      .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
      .toColor();
  final bottomColor = hsl
      .withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0))
      .toColor();
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [topColor, bottomColor],
  );
}

// 💡 앱 전반에 쓰일 공통 그라데이션 적용 레트로 버튼
class RetroGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;
  final Color? disabledColor;
  final Color foregroundColor;
  final Color? disabledForegroundColor;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;

  const RetroGradientButton({
    super.key,
    required this.onPressed,
    required this.color,
    this.disabledColor,
    this.foregroundColor = Colors.black,
    this.disabledForegroundColor,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)), // 💡 도트 느낌
    this.padding,
    this.borderWidth = 3.0, // 💡 두꺼운 외곽선
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color baseColor = isDisabled
        ? (disabledColor ?? Colors.grey[300]!)
        : color;
    final Color contentColor = isDisabled
        ? (disabledForegroundColor ?? Colors.black54)
        : foregroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: getRetroGradient(baseColor),
        borderRadius: borderRadius,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent, // 배경을 투명하게 하여 그라데이션 노출
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: contentColor,
          disabledForegroundColor: contentColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: padding,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

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
              offset: const Offset(3, 3), // 💡 뚜렷한 도트 그림자
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
              _isPressed ? 3.0 : 0.0, // 💡 픽셀 단위로 투박하게 이동
              _isPressed ? 3.0 : 0.0,
              0.0,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
