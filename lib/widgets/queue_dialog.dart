import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../widgets/inputs.dart';
import '../pages/queue.dart' as queue;

AlertDialog createPlaylistDialog(context) {
  double screenWidth = MediaQuery.of(context).size.width;
  TextEditingController playlistInput = TextEditingController();
  return AlertDialog(
    icon: Image.asset(
      'assets/folder.png',
      color: Theme.of(context).colorScheme.onSurface, // foreground
      height: screenWidth / 10,
      fit: BoxFit.contain,
    ),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    content: TextField(
      style: TextStyle(color: Theme.of(context).colorScheme.background),
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          fillColor: Colors.white,
          filled: true,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.background),
          border: const OutlineInputBorder(
            gapPadding: 0,
          ),
          hintText: "Insert playlist name"),
      controller: playlistInput,
    ),
    actions: [
      ElevatedButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text("Cancel")),
      FilledButton(
          onPressed: () {
            queue.storage.getQueueFile(
                playlist: playlistInput.text,
                autoCreate: true);
            Navigator.pop(context, false);
          },
          child: const Text("Create")),
    ],
  );
}

Widget queueDialog(BuildContext context, FileSystemEntity file) {
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
                  await showDialog(
                    context: context, 
                    builder: (dialogContext) => createPlaylistDialog(dialogContext)
                  );
                  queue.updatePlaylists();
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: queue.playlists.length,
                  itemBuilder: ((context, index) {
                    String playlist = queue.playlists[index];
                    bool contains = queue.storage.checkFile(file, playlist: playlist);
    
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
                          queue.addToQueue(file, playlist);
                        } else {
                          queue.removeFromQueue(file, playlist);
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
                                      queue.storage.removeQueueFile(playlist);
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text("Yes")
                                  ),
                                ],
                              );
                            }
                          );
                          await queue.updatePlaylists();
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