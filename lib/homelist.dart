import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'widgets/inputs.dart';

import 'player.dart' as player;
import 'queue.dart' as queue;

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
    double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        child: ListView.builder(
          itemCount: widget.files.length,
          itemBuilder: (context, index) {
            FileSystemEntity element = widget.files[index];
            bool selected = (element == player.current);
            bool inQueue = queue.queueList.contains(element);

            Color colorPlaying = selected ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onSurface;

            return SongTile(
              selected: selected, 
              element: element, 
              filename: basename(element.path),
              backgroundColor: inQueue ? Theme.of(context).colorScheme.inversePrimary : null,
              foregroundColor: inQueue ? Theme.of(context).colorScheme.background : null,
              trailing: ImageButton(
                image: inQueue ? 'songqueue.png' : 'addqueue.png',
                color: inQueue ? Theme.of(context).colorScheme.background : colorPlaying,
                width: screenWidth/10,
                pressUp: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => queue.queueDialog(context, element)
                  );
                  setState(() {});
                },
              ),
            );
          }
        )
      )
    );
  }
}