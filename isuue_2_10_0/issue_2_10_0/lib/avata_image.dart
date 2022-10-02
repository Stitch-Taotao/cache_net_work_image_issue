import 'package:flutter/material.dart';

import 'ly_avatar/ly_avatar_cache_image.dart';

class LYAvatarWidget extends StatelessWidget {
  final double width;
  final double height;
  final String src;
  final double radius;
  final AssetImage? error;
  const LYAvatarWidget({Key? key, required this.src, this.width = 52, this.height = 52, this.radius = 0, this.error})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(radius),
        ),
      ),
      child: LYAvatarCacheImage(
        imageUrl: src,
      ),
      // child: Image.network(
      //   src,
      //   fit: BoxFit.cover,
      // ),
    );
  }
}
