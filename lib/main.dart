import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:text_scroll/text_scroll.dart';

import 'widgets/inputs.dart';

import 'player.dart' as player;
import 'homelist.dart';
import 'queue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          background: Color.fromRGBO(32, 32, 32, 1.0),
          brightness: Brightness.dark,
          surface: Color.fromRGBO(77, 84, 97, 1),
          secondary: Color.fromRGBO(105, 95, 172, 1),
          primary: Color.fromRGBO(117, 125, 229, 1),
          error: Color.fromRGBO(187, 53, 53, 1),
          onBackground: Color.fromRGBO(255, 255, 255, 1.0),
          onSurface: Color.fromRGBO(255, 255, 255, 1.0),
          onSecondary: Color.fromRGBO(177, 193, 225, 1),
          onPrimary: Color.fromRGBO(201, 214, 250, 1),
          onError: Color.fromRGBO(255, 207, 207, 1),
          inversePrimary: Color.fromRGBO(255, 216, 110, 1)
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );   
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<FileSystemEntity> files = [];
  Widget currentPage = const Center(
    child: SizedBox(
      width: 175,height: 175,
      child: CircularProgressIndicator(
        strokeWidth: 20,
      )
    ),
  );

  void getMusicFiles() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) await Permission.storage.request();

    Directory musicDir = Directory('/storage/emulated/0/Music');
    final List<FileSystemEntity> songs = await musicDir.list().toList();

    setState(() {
      files = songs;
    });

    currentPage = HomeList(files: files);
  }

  @override
  void initState() {
    getMusicFiles();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarOpacity: 0,
        toolbarHeight: kToolbarHeight*1.5,
        
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ImageButton(
              image: "note.png",
              color: Theme.of(context).colorScheme.onPrimary,
              width: 40, height: 40,
              pressUp: () => setState( () => currentPage = HomeList(files: files,)),
            ),
            ImageButton(
              image: "songqueue.png",
              color: Theme.of(context).colorScheme.onPrimary,
              width: 50, height: 50,
              pressUp: () => setState( () => currentPage = const Queue()),
            )
          ],
        ),
      ),
      body: currentPage,
      bottomNavigationBar: player.current != null ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
            ]
          ),
        ),
        child: GestureDetector(
          onTapUp: (details) async {
            if (player.current != null) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) {
                return player.Player(file: player.current);
              }));
            }
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Image.asset(
                    "assets/note.png",
                    color: Theme.of(context).colorScheme.onPrimary,
                    height: 50,
                    width: 50,
                  ),
                ),
                Expanded(
                  child: TextScroll(
                    basename(player.current!.path),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      //color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.bold
                    ),
                    fadedBorder: true,
                    velocity: const Velocity(pixelsPerSecond: Offset(10, 0)),
                  ),
                ),
                ImageButton(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  image: (player.playing == false) ? "play.png" : "pause.png",
                  color: Theme.of(context).colorScheme.onBackground,
                  pressUp: () async {   
                    setState(() {
                      if (player.playing) {
                        player.player.pause();
                      } else {
                        player.player.resume();
                      }
                      player.playing = !player.playing;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ) : null,
    );
  }
}