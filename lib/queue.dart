
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

import 'widgets/inputs.dart';
import 'player.dart' as player;

import 'queue_storage.dart';
//storage.QueueStorage

List<String> queueList = [];
bool loop = false;
bool shuffle = false;
QueueStorage storage = QueueStorage();

void initialize() async {
  List<String> newList = await storage.read();
  for (String element in newList) {
    queueList.add(element);
  }
}

bool addToQueue(FileSystemEntity file) {
  bool contains = queueList.contains(file.path);
  
  if (!contains) {
    storage.writeFile(file);
    queueList.add(file.path);
    return true;
  }
  return false;
}

bool removeFromQueue(FileSystemEntity file) {
  storage.removeFile(file);
  return queueList.remove(file.path);
}

Random rng = Random();
void queueSongEnd() {
  if (queueList.contains(player.current!.path) && loop && queueList.isNotEmpty) {
    int songIndex = queueList.indexOf(player.current!.path);
    int index = songIndex + 1;
    
    if (shuffle == true) {
      int newRandom = rng.nextInt(queueList.length-1);
      if (newRandom == songIndex) newRandom = rng.nextInt(queueList.length-1);
      index = newRandom;
    }
    
    if (index >= queueList.length) index = 0;

    FileSystemEntity next = File(queueList[index]);

    player.playSong(next);
    if (player.current == player.display) player.display = next;
    player.current = next;

    player.onPlayerUpdateController.add(null);
  }
}

Widget queueDialog(BuildContext context, FileSystemEntity file) {
  bool contains = queueList.contains(file.path);
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
      for (String element in queueList) {
        String filename = basename(element);
        bool selected = player.current == null ? false : (element == player.current!.path);
        elements.add(SongTile(selected: selected, element: File(element), filename: filename));
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
      ) : Image.asset(
        'assets/songqueue.png',
        width: MediaQuery.of(context).size.width/2,
      )
    );
  }
}