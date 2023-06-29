
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

import 'widgets/inputs.dart';
import 'player.dart' as player;

List<FileSystemEntity> queueList = [];
bool loop = false;

bool addToQueue(FileSystemEntity file) {
  var contains = queueList.contains(file);
  //print(contains);
  if (!contains) {
    queueList.add(file);
    return true;
  }
  return false;
}

bool removeFromQueue(FileSystemEntity file) {
  return queueList.remove(file);
}

void queueSongEnd(BuildContext context) {
  if (queueList.contains(player.current) && loop) {

    int index = queueList.indexOf(player.current) + 1;
    if (index >= queueList.length) index = 0;

    FileSystemEntity next = queueList[index];

    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return player.Player(file: next, playing: true);
    }));

    if (context.mounted) return;

    print("play next song!");
  }
}

Widget queueDialog(BuildContext context, FileSystemEntity file) {
  var contains = queueList.contains(file);
  return AlertDialog(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
    icon: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          colors: [
            contains ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Image.asset(
        "assets/songqueue.png",
        color: Theme.of(context).colorScheme.onPrimary,
        width: 40,
      ),
    ),
    iconPadding: const EdgeInsets.all(10),
    titlePadding: const EdgeInsets.all(10),
    titleTextStyle: Theme.of(context).textTheme.titleLarge,
    title: Text("${contains ? "Delete song from" : "Add song to"} queue?"),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: const Text("No")
      ),
      FilledButton(
        onPressed: () {
          if (!contains) {
            addToQueue(file);
          } else {
            removeFromQueue(file);
          }
          Navigator.pop(context, false);
        },
        child: const Text("Yes")
      ),
    ],
  );
}

class Queue extends StatefulWidget {
  const Queue({super.key});

  @override
  State<Queue> createState() => _QueueState();
}

class _QueueState extends State<Queue> {
  @override
  Widget build(BuildContext context) {

    List<Widget> getElements() {
      List<Widget> elements = [];
      for (var element in queueList) {
        String filename = basename(element.path);
        bool selected = (element == player.current);
        elements.add(SongTile(selected: selected, element: element, filename: filename));
      }
      return elements;
    }

    return Center(
      child: queueList.isNotEmpty ? FractionallySizedBox(
        widthFactor: 0.95,
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: getElements()
        ),
      ) : Image.asset('assets/songqueue.png')
    );
  }
}