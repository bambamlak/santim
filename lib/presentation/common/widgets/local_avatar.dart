import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LocalAvatar extends StatelessWidget {
  final String asset;
  final double size;

  const LocalAvatar({super.key, required this.asset, this.size = 100});

  @override
  Widget build(BuildContext context) {
    String path = asset;
    if (!asset.contains('/')) {
      path = 'lottie_assets/$asset.json';
    }

    final lottieWidget = Lottie.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.person, size: size.isFinite ? size * 0.5 : 40),
    );

    // If size is infinite, let parent constrain it
    if (!size.isFinite) {
      return lottieWidget;
    }

    return SizedBox(width: size, height: size, child: lottieWidget);
  }
}
