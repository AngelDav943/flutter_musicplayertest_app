import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:path/path.dart';
//import 'package:music_testapp/player.dart';
//import 'package:music_testapp/widgets/inputs.dart';

import 'notification_service.dart';
import 'player.dart' as player;

import 'pages/queue.dart' as queue;
import 'pages/songs.dart' as songs;

//import './widgets/inputs.dart';
import './widgets/bottom_bar.dart' as bottom_bar;

import 'pages/playlists.dart' as playlist;

NotificationService notifService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await queue.initialize();
  await songs.getSongs
  ();
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
            inversePrimary: Color.fromRGBO(255, 216, 110, 1)),
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
            inversePrimary: Color.fromRGBO(255, 216, 110, 1)),
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
  void startBackgroundService() async {
    bool backgroundPermissions = await FlutterBackground.hasPermissions;
    if (!backgroundPermissions) return;

    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Music player",
      notificationText: "",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(
          name: 'notification_icon',
          defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);

    FlutterBackground.enableBackgroundExecution();
  }

  List<MaterialColor> RandomColors = [
    Colors.deepOrange,
    Colors.blue,
    Colors.lightGreen,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    notifService.initialize();
    startBackgroundService();
    RandomColors.shuffle();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //notifService.showNotification(title: "Angel's Music player", body: "Hello! test notif");

    double screenWidth = MediaQuery.of(context).size.width;
    double iconWidth = screenWidth / 8;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 1,
            child: ListView(
              children: [
                Column( // Playlists tab
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return const playlist.Playlists();
                        }));
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(screenWidth * 0.05, kToolbarHeight, 0, 5.0),
                        child: Row(
                          children: [
                            Image.asset('assets/songqueue.png',
                                width: iconWidth,
                                color: Theme.of(context).colorScheme.onBackground),
                            Text(
                              " Playlists >",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: screenWidth / 16),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kToolbarHeight*3,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        scrollDirection: Axis.horizontal,
                        itemCount: min(queue.playlists.length, 6), // max 6
                        itemBuilder: (BuildContext context, index) {
                          String playlistName = queue.playlists[index].replaceAll('queue_','').replaceAll('.txt', '');
                          return AspectRatio(
                            aspectRatio: 1,
                            child: Card(
                              color: RandomColors[index % RandomColors.length],
                              //color: RandomColors[Random().nextInt(RandomColors.length)],
                              //color: Theme.of(context).colorScheme.secondary,
                              elevation: 5,
                              child: ListTile(
                                title: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/folder.png',
                                      color: Theme.of(context).colorScheme.onSurface, // foreground
                                      //color: RandomColors[Random().nextInt(RandomColors.length)],
                                      fit: BoxFit.contain,
                                    ),
                                    Text(
                                      playlistName,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.normal,
                                          fontSize: screenWidth / 30),
                                    )
                                  ],
                                ),
                                onTap: () async {
                                  bool success = await queue.setQueue(playlistName);
                                  if (success) {
                                    setState(() {});
                                    // ignore: use_build_context_synchronously
                                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                                      return const queue.Queue();
                                    }));
                                  }
                                }
                              )
                            ),
                          );
                        })
                    )
                  ],
                ),
                const Padding(padding:EdgeInsets.only(top: kToolbarHeight)),
                Column( // Songs tab
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return const songs.Songs();
                        }));
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(screenWidth * 0.05, 0, 0, 5.0),
                        child: Row(
                          children: [
                            Image.asset('assets/note2.png',
                                width: iconWidth,
                                color: Theme.of(context).colorScheme.onBackground),
                            Text(
                              " Songs >",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: screenWidth / 16),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kToolbarHeight*7,
                      width: screenWidth * 0.9,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 5/2,
                        ), 
                        itemCount: min(songs.files.length, 8), // max 8
                        itemBuilder: (BuildContext context, index) {
                          String songName = basename(songs.files[index].path).replaceAll(".mp3", "");
                          return Card(
                            color: Theme.of(context).colorScheme.primary,
                            elevation: 10,
                            child: ListTile(
                              leading: Image.asset(
                                'assets/note.png',
                                color: Theme.of(context).colorScheme.onSurface, // foreground
                                width: screenWidth / 20,
                                height: screenWidth / 12,
                                fit: BoxFit.cover,
                              ),
                              titleAlignment: ListTileTitleAlignment.center,
                              title: Text(
                                songName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.normal,
                                    fontSize: screenWidth / 30),
                              ),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return player.Player(file: songs.files[index]);
                                }));
                              }
                            ),
                          );
                        })
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: bottom_bar.BottomNav(key: Key("$screenWidth"),),
      ),
    );
  }
}
