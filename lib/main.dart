import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart';

import 'player.dart' as player;

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

  void getMusicFiles() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) await Permission.storage.request();

    Directory musicDir = Directory('/storage/emulated/0/Music');
    final List<FileSystemEntity> songs = await musicDir.list().toList();

    setState(() {
      files = songs;
    });
  }

  @override
  void initState() {
    getMusicFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> getElements() {
      List<Widget> elements = [];
      for (var element in files) {
        String filename = basename(element.path);
        elements.add(Card(
          elevation: (element == player.current) ? 20 : 1,
          child: ListTile(
            leading: (element == player.current) ? Image.asset(
              'assets/note.png',
              color: Theme.of(context).colorScheme.onSurface,
              height: 35,
              fit: BoxFit.contain,
            ) : null,
            title: Text(filename),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) {
                return player.Player(file: element);
              }));
              setState(() {
                if (player.current != null) {
                  player.player.onPlayerComplete.listen((event) => setState(() {
                    if (player.looping == false) player.current = null;
                  }));
                }
              });
            },
          ),
        ));
      }
      return elements;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        toolbarHeight: 0,
      ),
      body: files.isEmpty ? const ListTile(title: Text("No files found")) : Center(
        child: ListView(
          children: getElements()
        )
      ),
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
              children: [
                Image.asset(
                  "assets/note.png",
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 50,
                  width: 50,
                ),
                Text(basename(player.current!.path))
              ],
            ),
          ),
        ),
      ) : null,
    );
  }
}