import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:text_scroll/text_scroll.dart';

import 'inputs.dart';

import '../player.dart' as player;

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  @override
  void initState() {
    player.onPlayerUpdate.listen((event) => {
      if (mounted) setState(() {})
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (player.current == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ]),
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
          margin: EdgeInsets.all(screenWidth / 25),
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
                      fontWeight: FontWeight.bold, fontSize: screenWidth / 25),
                  fadedBorder: true,
                  velocity:
                      Velocity(pixelsPerSecond: Offset(screenWidth / 25, 0)),
                ),
              ),
              ImageButton(
                padding: EdgeInsets.symmetric(horizontal: screenWidth / 50),
                image: (player.playing == false) ? "play.png" : "pause.png",
                color: Theme.of(context).colorScheme.onPrimary,
                width: screenWidth / 8,
                pressUp: () async {
                  if (player.playing) {
                    player.player.pause();
                  } else {
                    player.player.resume();
                  }
                  setState(() {
                    player.playing = !player.playing;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
