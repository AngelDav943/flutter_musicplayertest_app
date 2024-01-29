import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

import 'widgets/inputs.dart';
import 'player.dart' as player;

import 'queue_storage.dart';
//storage.QueueStorage

String currentPlaylist = "default";
List<String> queueList = [];
bool loop = false;
bool shuffle = false;
QueueStorage storage = QueueStorage();

List<String> playlists = [];

void initialize() async {
  storage.initialise();
  playlists = await storage.getPlaylists();
  List<String> newList = await storage.read();
  for (String element in newList) {
    queueList.add(element);
  }
}

Future<bool> setQueue(String playlistName) async {
  if (playlistName.contains('queue_') || playlistName.contains('.txt')) return false;

  currentPlaylist = playlistName;
  queueList = await storage.read(playlist: playlistName);

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

Widget queueDialog(BuildContext context, FileSystemEntity file) {
  //bool contains = queueList.contains(file.path);

  double screenWidth = MediaQuery.of(context).size.width;

  return Dialog.fullscreen(
    backgroundColor: Theme.of(context).colorScheme.background,
    child: StatefulBuilder(
      builder: (builderContext, setState) {
        return Column(
          children: [
            Card(
              margin: EdgeInsets.symmetric(vertical: screenWidth / 25, horizontal: screenWidth / 40),
              color: Theme.of(context).colorScheme.secondary, // background
              elevation: 10,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    vertical: 0, horizontal: screenWidth / 25),
                leading: Image.asset(
                  'assets/folder.png',
                  color: Theme.of(context).colorScheme.onSurface, // foreground
                  height: screenWidth / 10,
                  fit: BoxFit.contain,
                ),
                title: Text(
                  "Create new playlist",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: screenWidth / 30),
                ),
                onTap: () async {
                  TextEditingController playlistInput = TextEditingController();
                  await showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          icon: Image.asset(
                            'assets/folder.png',
                            color: Theme.of(context).colorScheme.onSurface, // foreground
                            height: screenWidth / 10,
                            fit: BoxFit.contain,
                          ),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          content: TextField(
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                border: OutlineInputBorder(
                                  gapPadding: 0,
                                ),
                                hintText: "Insert playlist name"),
                            controller: playlistInput,
                          ),
                          actions: [
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: const Text("Cancel")),
                            FilledButton(
                                onPressed: () {
                                  storage.getQueueFile(
                                      playlist: playlistInput.text,
                                      autoCreate: true);
                                  Navigator.pop(dialogContext, false);
                                },
                                child: const Text("Create")),
                          ],
                        );
                      });
                  playlists = await storage.getPlaylists();
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: ((context, index) {
                    String playlist = playlists[index]
                        .replaceAll("queue_", "")
                        .replaceAll(".txt", "");
                    bool contains = storage.checkFile(file, playlist: playlist);
    
                    Color backgroundColor = contains
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface;
                    Color foregroundColor = contains
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Theme.of(context).colorScheme.onSurface;
    
                    return ListTile(
                      tileColor: backgroundColor,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: screenWidth / 100,
                          horizontal: screenWidth / 25),
                      leading: Image.asset(
                        'assets/songqueue.png',
                        color: foregroundColor, // foreground
                        height: screenWidth / 10,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        playlist,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: foregroundColor,
                            fontWeight:
                                contains ? FontWeight.bold : FontWeight.normal,
                            fontSize: screenWidth / 30),
                      ),
                      onTap: () async {
                        if (!contains) {
                          addToQueue(file, playlist);
                        } else {
                          removeFromQueue(file, playlist);
                        }
                        Navigator.pop(context, false);
                      },
                      trailing: ImageButton(
                        image: 'delete.png',
                        color: foregroundColor,
                        width: screenWidth / 10,
                        pressUp: () async {
                          await showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                content: Text("Are you sure to delete playlist '$playlist'"),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text("No")
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      storage.removeQueueFile(playlist);
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text("Yes")
                                  ),
                                ],
                              );
                            }
                          );
                          playlists = await storage.getPlaylists();
                          setState(() {});
                        },
                      ),
                    );
                  })),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: screenWidth / 75)),
            ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                  vertical: 0, horizontal: screenWidth / 25),
              leading: Image.asset(
                'assets/delete.png',
                color: Theme.of(context).colorScheme.onSurface, // foreground
                height: screenWidth / 10,
                fit: BoxFit.contain,
              ),
              title: Text(
                "Cancel",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: screenWidth / 30),
              ),
              onTap: () async {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      }
    ),
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
        bool selected =
            player.current == null ? false : (element == player.current!.path);
        elements.add(SongTile(
            selected: selected, element: File(element), filename: filename));
      }
      return elements;
    }

    return Center(
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
              ));
  }
}