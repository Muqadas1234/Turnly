import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Reusable SVG icon widget that loads icons from assets/icons/
class AppIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = icon.endsWith('.svg') ? 'assets/icons/$icon' : 'assets/icons/$icon.svg';

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
