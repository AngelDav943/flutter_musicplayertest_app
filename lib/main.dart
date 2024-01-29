import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:flutter_background/flutter_background.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'widgets/inputs.dart';

import 'notification_service.dart';
import 'player.dart' as player;
import 'homelist.dart';
import 'queue.dart' as queue;
import 'playlists.dart' as playlist;

NotificationService notifService = NotificationService();

void startBackgroundService() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Music player",
    notificationText: "",
    notificationImportance: AndroidNotificationImportance.Default,
    notificationIcon: AndroidResource(name: 'notification_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  
  bool success = await FlutterBackground.enableBackgroundExecution();
  print("successful? $success");
}

void main() {
  //WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Angel's Music Player",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "ComicNeue",
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          background: Color.fromRGBO(202, 219, 233, 1),
          surface: Color.fromRGBO(176, 198, 247, 1),
          secondary: Color.fromRGBO(135, 122, 219, 1),
          primary: Color.fromRGBO(117, 172, 255, 1),
          error: Color.fromRGBO(187, 53, 53, 1),
          onBackground: Color.fromRGBO(125, 134, 148, 1),
          onSurface: Color.fromRGBO(77, 95, 255, 1),
          onSecondary: Color.fromRGBO(177, 193, 225, 1),
          onPrimary: Color.fromRGBO(201, 214, 250, 1),
          onError: Color.fromRGBO(255, 207, 207, 1),
          inversePrimary: Color.fromRGBO(255, 216, 110, 1)
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: "ComicNeue",
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          background: Color.fromRGBO(32, 32, 32, 1.0),
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
      themeMode: ThemeMode.dark,
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
  int indexPage = 0;
  Widget currentPage = Center(
    child: Image.asset("assets/note.png"),
  );

  void getMusicFiles() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) await Permission.manageExternalStorage.request();

    Directory musicDir = Directory('/storage/emulated/0/Music');
    final List<FileSystemEntity> songs = (await musicDir.list().toList()).where((FileSystemEntity file) {
      return file.path.contains(".mp3"); // leave only .mp3 audios
    }).toList();

    setState(() {
      files = songs;
    });
  }

  @override
  void initState() {
    notifService.initialize();
    queue.initialize();
    getMusicFiles();
    startBackgroundService();

    player.onPlayerUpdate.listen((event) => {
      if (mounted) setState(() {})
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {

    //notifService.showNotification(title: "Angel's Music player", body: "Hello! test notif");

    switch (indexPage) {
      case 0:
        currentPage = HomeList(files: files);
        break;
      case 1:
        // ignore: prefer_const_constructors
        currentPage = queue.Queue();
        break;
      case 2: // temp.. c vc
        currentPage = const playlist.Playlists();
        break;
    }
    
    double screenWidth = MediaQuery.of(context).size.width;

    currentPage = currentPage;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarOpacity: 0,
        toolbarHeight: screenWidth/6,
        
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ImageButton(
              image: "note2.png",
              color: indexPage == 0 ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onPrimary,
              width: screenWidth/8,
              pressUp: () => setState( () => indexPage = 0),
            ),
            ImageButton(
              image: "songqueue.png",
              color: indexPage == 1 ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onPrimary,
              width: screenWidth/8,
              pressUp: () => setState( () => indexPage = 1),
            ),
            ImageButton(
              image: "shuffle.png",
              color: indexPage == 2 ? Theme.of(context).colorScheme.inversePrimary : Theme.of(context).colorScheme.onPrimary,
              width: screenWidth/8,
              pressUp: () => setState( () => indexPage = 2),
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
                return player.Player(file: player.current!);
              }));
            }
          },
          child: Container(
            margin: EdgeInsets.all(screenWidth/25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
                  child: Image.asset(
                    "assets/note.png",
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: screenWidth / 8,
                  ),
                ),
                Expanded(
                  child: TextScroll(
                    basename(player.current!.path),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      //color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth / 25
                    ),
                    fadedBorder: true,
                    velocity: Velocity(pixelsPerSecond: Offset(screenWidth / 25, 0)),
                  ),
                ),
                ImageButton(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
                  image: (player.playing == false) ? "play.png" : "pause.png",
                  color: Theme.of(context).colorScheme.onPrimary,
                  width: screenWidth / 8,
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