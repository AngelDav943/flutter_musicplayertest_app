import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:music_testapp/pages/player.dart';
import 'package:path/path.dart';

//import './pages/player.dart' as player;
import 'pages/queue.dart' as queue;
import 'pages/songs.dart' as songs;

//import './widgets/inputs.dart';
import './widgets/bottom_bar.dart' as bottom_bar;

import 'pages/playlists.dart' as playlist;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await queue.initialize();
  await songs.getSongs();
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

List<MaterialColor> randomColors = [
  Colors.deepOrange,
  Colors.blue,
  Colors.lightGreen,
  Colors.purple,
  Colors.orange,
  Colors.red,
  Colors.teal,
];

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

  @override
  void initState() {
    startBackgroundService();
    randomColors.shuffle();

    // print(songs.displayFiles);
    songs.onSongsUpdate.listen((event) {
      setState(() {});
    });
    /*songs.
    */

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double minSize = screenWidth;
    if (screenHeight < screenWidth) minSize = screenHeight;

    double iconWidth = clampDouble(screenWidth / 8, 5, 75);

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
      )),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FractionallySizedBox(
            widthFactor: 1,
            child: ListView(
              children: [
                Column(
                  // Playlists tab
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const playlist.Playlists();
                        }));
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.05, kToolbarHeight, 0, 5.0),
                        child: Row(
                          children: [
                            Image.asset('assets/songqueue.png',
                                width: iconWidth,
                                color:
                                    Theme.of(context).colorScheme.onBackground),
                            Text(
                              " Playlists >",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: clampDouble(
                                          screenWidth / 16, 10, 30)),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height: minSize / 2.5, //kToolbarHeight*3,
                        child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05),
                            scrollDirection: Axis.horizontal,
                            itemCount: min(queue.playlists.length, 6), // max 6
                            itemBuilder: (BuildContext context, index) {
                              String playlistName = queue.playlists[index];
                              int internalIndex =
                                  queue.internalPlaylists.indexOf(playlistName);

                              return AspectRatio(
                                aspectRatio: 1,
                                child: Card(
                                    color: randomColors[
                                        internalIndex % randomColors.length],
                                    elevation: 5,
                                    child: ListTile(
                                        title: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/folder.png',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fit: BoxFit.contain,
                                            ),
                                            Text(
                                              playlistName,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: clampDouble(
                                                          screenWidth / 25,
                                                          10,
                                                          25)),
                                            )
                                          ],
                                        ),
                                        onTap: () async {
                                          bool success = await queue
                                              .setQueue(playlistName);
                                          if (success) {
                                            setState(() {});
                                            // ignore: use_build_context_synchronously
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (context) {
                                              return const queue.Queue();
                                            }));
                                          }
                                        })),
                              );
                            }))
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: kToolbarHeight)),
                Column(
                  // Songs tab
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const songs.Songs();
                        }));
                      },
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(screenWidth * 0.05, 0, 0, 5.0),
                        child: Row(
                          children: [
                            Image.asset('assets/note2.png',
                                width: iconWidth,
                                color:
                                    Theme.of(context).colorScheme.onBackground),
                            Text(
                              " Songs >",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: clampDouble(
                                          screenWidth / 16, 10, 30) //26
                                      ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height: kToolbarHeight * 7,
                        width: screenWidth * 0.9,
                        child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    childAspectRatio: 5 / 2),
                            itemCount:
                                min(songs.displayFiles.length, 8), // max 8
                            itemBuilder: (BuildContext context, index) {
                              String songName =
                                  basename(songs.displayFiles[index].path)
                                      .replaceAll(".mp3", "");
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return Player(
                                        file: songs.displayFiles[index]);
                                  }));
                                },
                                child: Card(
                                  color: Theme.of(context).colorScheme.primary,
                                  elevation: 10,
                                  child: GridTileBar(
                                    leading: Image.asset(
                                      'assets/note.png',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface, // foreground
                                      width: clampDouble(
                                          screenWidth / 8, 10, 40), //40,
                                      fit: BoxFit.cover,
                                    ),
                                    title: Text(
                                      songName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.normal,
                                              fontSize: clampDouble(
                                                  minSize / 25, 5, 15) //15
                                              ),
                                    ),
                                  ),
                                ),
                              );
                            }))
                  ],
                )
              ],
            ),
          ),
        ),
        bottomNavigationBar: bottom_bar.BottomNav(
          key: Key("$screenWidth"),
        ),
      ),
    );
  }
}
