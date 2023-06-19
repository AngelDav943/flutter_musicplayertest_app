import 'package:flutter/material.dart';

class ImageButton extends StatelessWidget {
  const ImageButton({
    super.key,
    this.image = "",
    this.pressDown, this.pressUp,
    this.height = 50, this.width = 50,
    this.color = const Color.fromRGBO(128, 128, 128, 1)
  });

  final String image;
  final dynamic pressDown;
  final dynamic pressUp;
  final double height;
  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:(details){
        if (pressDown != null) pressDown();
      },
      onTapUp: (details) {
        if (pressUp != null) pressUp();
      },
      onTapCancel: () {
        if (pressUp != null) pressUp();
      },
      child: Image.asset(
        "assets/$image",
        color: color,
        height: height,
        width: width,
      ),
    );
  }
}