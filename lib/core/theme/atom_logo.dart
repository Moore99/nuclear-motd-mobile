import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Atom logo widget matching the web version
class AtomLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? atomColor;
  final double borderRadius;

  const AtomLogo({
    super.key,
    this.size = 80,
    this.backgroundColor,
    this.atomColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final color = atomColor ?? AppColors.primary;
    final nucleusSize = size * 0.2;
    final orbitWidth = size * 0.625;
    final orbitHeight = size * 0.3;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: orbitWidth,
          height: orbitWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Electron orbits
              ...List.generate(3, (index) {
                final rotation = index * 60.0;
                return Transform.rotate(
                  angle: rotation * 3.14159 / 180,
                  child: Container(
                    width: orbitWidth,
                    height: orbitHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(orbitHeight / 2),
                    ),
                  ),
                );
              }),
              // Nucleus (on top)
              Container(
                width: nucleusSize,
                height: nucleusSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple atom icon (without container) for smaller uses in AppBars
class AtomIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AtomIcon({
    super.key,
    this.size = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Default to white for AppBar visibility, or use provided color
    final iconColor = color ?? Colors.white;
    final nucleusSize = size * 0.28;
    final orbitWidth = size;
    final orbitHeight = size * 0.42;
    final strokeWidth = size > 24 ? 1.5 : 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Electron orbits
          ...List.generate(3, (index) {
            final rotation = index * 60.0;
            return Transform.rotate(
              angle: rotation * 3.14159 / 180,
              child: Container(
                width: orbitWidth,
                height: orbitHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: iconColor.withOpacity(0.8),
                    width: strokeWidth,
                  ),
                  borderRadius: BorderRadius.circular(orbitHeight / 2),
                ),
              ),
            );
          }),
          // Nucleus
          Container(
            width: nucleusSize,
            height: nucleusSize,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
