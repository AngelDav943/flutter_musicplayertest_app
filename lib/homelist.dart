import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'widgets/inputs.dart';

import 'player.dart' as player;

// ignore: must_be_immutable
class HomeList extends StatefulWidget {
  const HomeList({super.key, this.files = const []});

  final List<FileSystemEntity> files;

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: ListView.builder(
          itemCount: widget.files.length,
          itemBuilder: (context, index) {
            FileSystemEntity element = widget.files[index];
            return SongTile(selected: (element == player.current), element: element, filename: basename(element.path));
          }
        )
      )
    );
  }
}