import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

import '../widgets/inputs.dart';
import 'player.dart' as player;
import '../main.dart' as main;

import '../widgets/bottom_bar.dart' as bottom_bar;

import '../classes/queue_storage.dart';

String currentPlaylist = "default";
List<String> queueList = [];
bool loop = false;
bool shuffle = false;
QueueStorage storage = QueueStorage();

List<String> playlists = [];
List<String> internalPlaylists = [];

Future<bool> updatePlaylists() async {
  internalPlaylists = await storage.getPlaylists();
  playlists = List.from(internalPlaylists);
  return true;
}

Future<bool> initialize() async {
  storage.initialise();
  updatePlaylists();
  /*List<String> newList = await storage.read();
  for (String element in newList) {
    queueList.add(element);
  }*/
  return true;
}

Future<bool> setQueue(String playlistName) async {
  if (playlistName.contains('queue_') || playlistName.contains('.txt')) {
    return false;
  }

  currentPlaylist = playlistName;
  List<String> playlistList = await storage.read(playlist: playlistName);

  if (playlistList.isNotEmpty) {
    queueList = playlistList;

    playlists.sort((a, b) {
      if (a == currentPlaylist) return -1;
      if (b == currentPlaylist) return 1;
      return 0;
    });

    return true;
  }

  return false;
}

bool addToQueue(FileSystemEntity file, String playlist) {
  bool contains = queueList.contains(file.path);

  if (!contains) {
    storage.writeFile(file, playlist: playlist);
    if (playlist == currentPlaylist) queueList.add(file.path);
    return true;
  }
  return false;
}

bool removeFromQueue(FileSystemEntity file, String playlist) {
  storage.removeFile(file, playlist: playlist);
  if (playlist == currentPlaylist) return queueList.remove(file.path);
  return false;
}

Random rng = Random();
void queueSongEnd() {
  if (queueList.contains(player.current!.path) &&
      loop &&
      queueList.isNotEmpty) {
    int songIndex = queueList.indexOf(player.current!.path);
    int index = songIndex + 1;

    if (shuffle == true) {
      int newRandom = rng.nextInt(queueList.length - 1);
      if (newRandom == songIndex) newRandom = rng.nextInt(queueList.length - 1);
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

class Queue extends StatefulWidget {
  const Queue({super.key});

  @override
  State<Queue> createState() => _QueueState();
}

class _QueueState extends State<Queue> {
  @override
  void initState() {
    // update player when song finishes or updates
    player.onPlayerUpdate.listen((event) => {if (mounted) setState(() {})});
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    List<Widget> getElements() {
      List<Widget> elements = [];
      for (String element in queueList) {
        String filename = basename(element);
        bool selected =
            player.current == null ? false : (element == player.current!.path);
        elements.add(SongTile(
            selected: selected, element: File(element), filename: filename));
      }
      return elements;
    }

    int currentIndex = internalPlaylists.indexOf(currentPlaylist);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: main.randomColors[currentIndex %
            main.randomColors.length], //Theme.of(context).colorScheme.primary,
        toolbarOpacity: 1,
        toolbarHeight: screenWidth / 6,
        leadingWidth: screenWidth / 4,
        leading: ImageButton(
          image: "back.png",
          color: Theme.of(context).colorScheme.onBackground,
          pressUp: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text(
          currentPlaylist,
          overflow: TextOverflow.fade,
        ),
      ),
      body: Center(
          child: queueList.isNotEmpty
              ? FractionallySizedBox(
                  widthFactor: 0.95,
                  child: ListView(
                      padding: const EdgeInsets.only(top: 20),
                      children: getElements()),
                )
              : Image.asset(
                  'assets/songqueue.png',
                  width: MediaQuery.of(context).size.width / 2,
                )),
      bottomNavigationBar: const bottom_bar.BottomNav(),
    );
  }
}
