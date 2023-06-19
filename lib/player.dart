// ignore_for_file: prefer_typing_uninitialized_variables, avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'package:audio_session/audio_session.dart';

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
bool playing = false;

class _PlayerState extends State<Player> {

  late AudioSession session;
  bool ended = false;

  var onPosChanged;
  var onComplete;
  var onNoisyEvent;

  @override
  void initState() {
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    print("cancelling events");
    onPosChanged!.cancel();
    super.dispose();
  }

  void initPlayer() async {
    AudioSession.instance.then((session) async {
      await session.configure(const AudioSessionConfiguration.music());
      handleInterruptions(session);
    });

    //if (current != widget.file) {
    await player.play(DeviceFileSource(widget.file.path));
    setState(() {
      playing = true;
    });
    current = widget.file;

    songDuration = (await player.getDuration())!;
    onPosChanged = player.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          songPosition = newPosition;
        });
      }
    });

    onComplete = player.onPlayerComplete.listen((event) {
      ended = true;
      playing = false;
      if (looping) {
        ended = false;
        player.play(DeviceFileSource(widget.file.path));
        if (mounted) {
          setState(() {
            playing = true;
          });
        }
      } else {
        current = null;
      }
    });
  }

  void handleInterruptions(AudioSession session) {
    session.becomingNoisyEventStream.listen((event) {
      if (playing == true && ended == false) player.pause();
    });

    session.devicesChangedEventStream.listen((event) {
      if (event.devicesRemoved.isNotEmpty) player.pause();
      if (mounted) {
        setState(() {
          playing = false;
        });
      }
    });
  }

  String formatTime(int seconds) {
    var time = '${(Duration(seconds: seconds))}'.split('.')[0].split(':');
    time.remove('0');
    return time.join(':').padLeft(1, '0');
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
  bool draggingVolume = false;

  @override
  Widget build(BuildContext context) {
    String filename = basename(widget.file.path);
    
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
                    setState(() {
                      draggingVolume = true;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      double delta = details.delta.dy / 100;
                      volume = clampDouble(volume - delta, 0, 1);
                    });
                    player.setVolume(volume);
                    print(details);
                  },
                  onVerticalDragCancel: () {
                    setState(() {
                      draggingVolume = false;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    setState(() {
                      draggingVolume = false;
                    });
                  },
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.all(Radius.circular(10))
                    ),
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        Image.asset(
                          'assets/note.png',
                          height: 125 * max(volume, 0.7),
                          width: 125 * max(volume, 0.7),
                          fit: BoxFit.cover,
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(max(0.1, volume)),
                        ),
                        Container(
                          child: (draggingVolume == true) ? Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(76, 0, 0, 0),
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            width: 30,
                            height: 150,
                            padding: const EdgeInsets.all(10),
                            child: RotatedBox(
                              quarterTurns: -1,
                              child: ProgressIndicatorTheme(
                                data: const ProgressIndicatorThemeData(),
                                child: LinearProgressIndicator(value: volume)
                              )
                            ),
                          ) : const SizedBox(width: 0,height: 0,),
                        ),
                      ],
                    )
                  ),
                ),
                Text(filename, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold
                ),),
                Row(
                  children: [
                    Text(formatTime(songPosition.inSeconds)),
                    Expanded(
                      child: SliderTheme(
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
                    ),
                    Text(formatTime(songDuration.inSeconds))
                  ],
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
                const SizedBox(
                  height: 40,
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}