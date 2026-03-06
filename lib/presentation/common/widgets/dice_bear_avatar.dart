import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiceBearAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final String style;

  const DiceBearAvatar({
    super.key,
    required this.seed,
    this.size = 100,
    this.style = 'croodles', // 'bottts', 'adventurer', etc.
  });

  @override
  Widget build(BuildContext context) {
    // DiceBear v7 API
    final url = 'https://api.dicebear.com/7.x/$style/svg?seed=$seed';

    return SvgPicture.network(
      url,
      width: size,
      height: size,
      placeholderBuilder: (context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
