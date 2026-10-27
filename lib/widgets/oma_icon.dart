import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OmaIcon extends StatelessWidget {
  const OmaIcon(this.asset, {required this.size, this.color, super.key});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
      ),
    );
  }
}

class OmaCroppedImage extends StatelessWidget {
  const OmaCroppedImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.imageLeft,
    required this.imageTop,
    required this.imageWidth,
    required this.imageHeight,
    super.key,
  });

  final String asset;
  final double width;
  final double height;
  final double imageLeft;
  final double imageTop;
  final double imageWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: imageLeft,
              top: imageTop,
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                width: imageWidth,
                height: imageHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OmaLogo extends StatelessWidget {
  const OmaLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 54,
      height: 26,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -16,
              top: -68,
              width: 400,
              height: 868,
              child: Image(
                image: AssetImage('assets/images/home/logo_source.png'),
                fit: BoxFit.fill,
                width: 400,
                height: 868,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
