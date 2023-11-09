
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

List<String> playlists = [];

void initialize() async {
  storage.initialise();
  playlists = await storage.getPlaylists();
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
  //bool contains = queueList.contains(file.path);
  
  double screenWidth = MediaQuery.of(context).size.width;
  
  return Dialog.fullscreen(
    backgroundColor: Theme.of(context).colorScheme.primary,
    child: FractionallySizedBox(
      widthFactor: 0.95,
      child: Column(
        children: [
          Padding(padding: EdgeInsets.symmetric(vertical: screenWidth/ 50)),
          Card(
            color: Theme.of(context).colorScheme.secondary, // background
            elevation: 10,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: screenWidth/ 25),
              leading: Image.asset(
                'assets/menu.png',
                color: Theme.of(context).colorScheme.onSurface, // foreground
                height: screenWidth/10,
                fit: BoxFit.contain,
              ),
              title: Text(
                "Create new playlist",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: screenWidth / 30
                ),
              ),
              onTap: () async {
                TextEditingController playlistInput = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Insert playlist name"
                        ),
                        controller: playlistInput,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text("Cancel")
                        ),
                        FilledButton(
                          onPressed: () {
                            storage.getQueueFile(playlist: playlistInput.text, autoCreate: true);
                            Navigator.pop(context, false);
                          },
                          child: const Text("Create")
                        ),
                      ],
                    );
                  }
                );
                playlists = await storage.getPlaylists();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: ((context, index) {
                String playlist = playlists[index].replaceAll("queue_", "").replaceAll(".txt", "");
                bool contains = storage.checkFile(file, playlist: playlist);
                
                Color backgroundColor = contains ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface;
                Color foregroundColor = contains ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onSurface;
          
                return Card(
                  color: backgroundColor, // background
          
                  elevation: contains ? 20 : 1,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: screenWidth / 100, horizontal: screenWidth/ 25),
                    leading: Image.asset(
                      'assets/songqueue.png',
                      color: foregroundColor, // foreground
                      height: screenWidth/10,
                      fit: BoxFit.contain,
                    ),
                    title: Text(
                      playlist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: contains ? FontWeight.bold : FontWeight.normal,
                        fontSize: screenWidth / 30
                      ),
                    ),
                    onTap: () async {
                      if (!contains) {
                        addToQueue(file);
                      } else {
                        removeFromQueue(file);
                      }
                      Navigator.pop(context, false);
                    },
                    trailing: ImageButton(
                      image: 'delete.png',
                      color: foregroundColor,
                      width: screenWidth/10,
                      pressUp: () async {
                        await storage.removeQueueFile(playlist);
                        playlists = await storage.getPlaylists();
                      },
                    ),
                  ),
                );
              })
            ),
          ),
        ],
      ),
    ),
  );

  /*
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
        width: 10,
      ),
    ),
    title: Text("${contains ? "Delete song from" : "Add song to"} playlist"),
    content: const Text("hii"),
    /*actions: [
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
    ],*/
  );
  // */
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


class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {

  late List<String> playlists = [];

  void getPlaylists() async {
    List<String> storagePlaylists = await storage.getPlaylists();
    setState(() {
      playlists = storagePlaylists;
    });
  }

  @override
  void initState() {
    getPlaylists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: ListView.builder(
        itemCount: playlists.length,
        itemBuilder: ((context, index) {
          return Card(
            child: Text(
              playlists[index],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: screenWidth / 25
              )
            ),
          );
        })
      ),
    );
  }
}