import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'widgets/inputs.dart';

import 'player.dart' as player;

// ignore: must_be_immutable
class HomeList extends StatefulWidget {
  HomeList({super.key, this.files = const []});

  final List<FileSystemEntity> files;

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {

  @override
  Widget build(BuildContext context) {

    List<Widget> getElements() {
      List<Widget> elements = [];
      for (var element in widget.files) {
        String filename = basename(element.path);
        bool selected = (element == player.current);
        elements.add(songTile(selected: selected, element: element, filename: filename));
      }
      return elements;
    }

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: widget.files.isEmpty ? [const ListTile(title: Text("No files found"))] : getElements()
        ),
      )
    );
  }
}