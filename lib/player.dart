// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';

import 'inputs.dart';

class Player extends StatefulWidget {
  const Player({super.key, required this.file});

  final FileSystemEntity file;

  @override
  State<Player> createState() => _PlayerState();
}

AudioPlayer player = AudioPlayer();
Duration songDuration = const Duration();
Duration songPosition = const Duration();
var current;
double volume = 1.0;
bool looping = false;

class _PlayerState extends State<Player> {

  bool playing = false;
  bool ended = false;

  var onPosChanged;
  var onComplete;

  @override
  void initState()  {
    current = widget.file;
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    print("cancelling events");
    onPosChanged!.cancel();
    onComplete!.cancel();
    super.dispose();
  }

  void initPlayer() async {
    await player.play(DeviceFileSource(widget.file.path));
    setState(() {
      playing = true;
    });

    songDuration = (await player.getDuration())!;

    onPosChanged = player.onPositionChanged.listen((newPosition) => setState(() {
      songPosition = newPosition;
    }));

    onComplete = player.onPlayerComplete.listen((event) => setState(() {
      ended = true;
      playing = false;
      if (looping) {
        ended = false;
        player.play(DeviceFileSource(widget.file.path));
        setState(() {
          playing = true;
        });
      } else {
        current = null;
      }
    }));
  }

  void seekToSecond(int second) async {
    if (ended == true || current == null) {
      ended = false;
      current = widget.file;
      await player.play(DeviceFileSource(widget.file.path));
      
      if (playing == false) player.pause();
    }
    Duration newDuration = Duration(seconds: second);
    player.seek(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    String filename = basename(widget.file.path);
    bool draggingVolume = false;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
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
            widthFactor: 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 40, bottom: 10),
                  child: ImageButton(
                    image: "back.png",
                    color: Theme.of(context).colorScheme.onBackground,
                    pressUp: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ),
                GestureDetector(
                  onVerticalDragStart:(details) {
                    print("haa");
                    setState(() {
                      draggingVolume = true;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    setState(() {
                      draggingVolume = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        /*Container( // TODO: Create volume slider 
                          child: (draggingVolume == true) ? RotatedBox(
                            quarterTurns: -1,
                            child: Slider(
                              value: volume, 
                              min: 0,
                              max: 1.0,
                              onChanged: (newvalue) {
                                setState(() {
                                  volume = newvalue;
                                  player.setVolume(newvalue);
                                });
                              }
                            ),
                          ) : null,
                        ),*/
                        Image.asset(
                          'assets/note.png',
                          height: 250,
                          width: 250,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ],
                    )
                  ),
                ),
                Text(filename, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold
                ),),
                SliderTheme(
                  data: SliderThemeData(
                    trackShape: const RectangularSliderTrackShape(),
                    trackHeight: 20,
                    thumbShape: SliderComponentShape.noThumb
                  ), 
                  child: Slider(
                    value: songPosition.inSeconds.toDouble(),
                    min: 0.0,
                    max: songDuration.inSeconds.toDouble(),
                    onChanged: (double value) {
                      setState(() {
                        seekToSecond(value.toInt());
                      });
                    }
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ImageButton(
                      image: (playing == false || ended == true) ? "play.png" : "pause.png",
                      color: Theme.of(context).colorScheme.onBackground,
                      pressUp: () async {
                        if (ended == true) {
                          await player.play(DeviceFileSource(widget.file.path));
                          setState(() {
                            playing = true;
                            ended = false;
                            if (!looping) current = widget.file;
                          });
                          return;
                        }
          
                        setState(() {
                          if (playing) {
                            player.pause();
                          } else {
                            player.resume();
                          }
                          playing = !playing;
                        });
                      },
                    ),
                    ImageButton(
                      image: "repeat.png",
                      color: looping ? Theme.of(context).colorScheme.onBackground : Theme.of(context).colorScheme.secondary,
                      pressUp: () {
                        setState(() {
                          looping = !looping;
                        });
                      },
                    )
                  ],
                ),
                Slider(
                  value: volume, 
                  min: 0,
                  max: 1.0,
                  onChanged: (newvalue) {
                    setState(() {
                      volume = newvalue;
                      player.setVolume(newvalue);
                    });
                  }
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}