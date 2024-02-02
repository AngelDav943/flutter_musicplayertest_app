import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path/path.dart';

import '../widgets/inputs.dart';

import '../player.dart' as player;
import 'queue.dart' as queue;
import '../widgets/queueDialog.dart' as queue_dialog;

List<FileSystemEntity> files = [];

Future<List<FileSystemEntity>> getMusicFiles() async {
  PermissionStatus status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) await Permission.manageExternalStorage.request();

  String musicPath = '/storage/emulated/0/Music';
  if (Platform.isWindows) musicPath = "/Music";

  Directory musicDir = Directory(musicPath);
  final List<FileSystemEntity> songs =
      (await musicDir.list().toList()).where((FileSystemEntity file) {
    return file.path.contains(".mp3"); // leave only .mp3 audios
  }).toList();

  return songs;
}

class Songs extends StatefulWidget {
  const Songs({super.key});

  @override
  State<Songs> createState() => _SongsState();
}

Future<List<FileSystemEntity>> getSongs() async {
  files = await getMusicFiles();
  return files;
}

class _SongsState extends State<Songs> {
  void updateSongFiles() async {
    List<FileSystemEntity> songs = await getMusicFiles();
    setState(() {
      files = songs;
    });
  }

  @override
  void initState() {
    updateSongFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarHeight: screenWidth / 6,
        leadingWidth: screenWidth / 4,
        leading: ImageButton(
          image: "back.png",
          color: Theme.of(context).colorScheme.onBackground,
          pressUp: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text("All songs"),
      ),
      body: Center(
          child: FractionallySizedBox(
              widthFactor: 0.95,
              child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    FileSystemEntity songFile = files[index];
                    bool selected = player.current == null
                        ? false
                        : (songFile.path == player.current!.path);

                    Color colorPlaying = selected
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Theme.of(context).colorScheme.onSurface;

                    return SongTile(
                      selected: selected,
                      element: songFile,
                      filename: basename(songFile.path),
                      trailing: ImageButton(
                        image: 'addqueue.png',
                        color: colorPlaying,
                        width: screenWidth / 10,
                        pressUp: () async {
                          await showDialog(
                              context: context,
                              builder: (context) =>
                                  queue_dialog.queueDialog(context, songFile));
                          setState(() {});
                        },
                      ),
                    );
                  }))),
    );
  }
}
