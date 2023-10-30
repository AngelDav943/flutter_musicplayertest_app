import 'dart:io';
import 'package:flutter/material.dart';

import '../player.dart' as player;

class ImageButton extends StatelessWidget {
  const ImageButton({
    super.key,
    this.image = "",
    this.pressDown, this.pressUp,
    this.height = -1,
    this.width = -1,
    this.color = const Color.fromRGBO(128, 128, 128, 1),
    this.padding = const EdgeInsets.all(0)
  });

  final String image;
  final dynamic pressDown;
  final dynamic pressUp;
  final double height;
  final double width;
  final Color? color;
  final EdgeInsetsGeometry? padding;

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
      child: Container(
        padding: padding,
        child: Image.asset(
          "assets/$image",
          color: color,
          height: height == -1 ? width : height,
          width: width,
        ),
      ),
    );
  }
}

class SongTile extends StatefulWidget {
  const SongTile({
    super.key,
    required this.selected,
    required this.element,
    required this.filename,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor
  });

  final bool selected;
  final FileSystemEntity element;
  final String filename;
  final Widget? trailing;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<SongTile> {
  @override
  Widget build(BuildContext context) {
    
    double screenWidth = MediaQuery.of(context).size.width;

    Color defaultBackground = widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface;
    Color defaultForeground = widget.selected ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onSurface;

    return Card(
      color: widget.backgroundColor ?? defaultBackground,

      elevation: (widget.element == player.current) ? 20 : 1,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: screenWidth / 100, horizontal: screenWidth/ 25),
        leading: Image.asset(
          'assets/note.png',
          color: widget.foregroundColor ?? defaultForeground,
          height: screenWidth/10,
          fit: BoxFit.contain,
        ),
        title: Text(
          widget.filename,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.foregroundColor ?? defaultForeground,
            fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
            fontSize: screenWidth / 30
          ),
        ),
        trailing: widget.trailing,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) {
            return player.Player(file: widget.element);
          }));
        },
      ),
    );
  }
}