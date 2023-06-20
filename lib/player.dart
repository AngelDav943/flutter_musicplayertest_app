// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'package:audio_session/audio_session.dart';

import 'widgets/inputs.dart';

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

  bool loaded = false;

  @override
  void initState() {
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    if (onPosChanged != null) onPosChanged.cancel();
    super.dispose();
  }

  void initPlayer() {
    player.audioCache.clearAll();
    if (current != widget.file) {
      player.stop();
    }

    AudioSession.instance.then((session) async {
      await session.configure(const AudioSessionConfiguration.music());
      handleInterruptions(session);
    });
    
    player.play(DeviceFileSource(widget.file.path));
    setState(() {
      playing = true;
    });

    //songDuration = ()!;
    player.getDuration().then((value) => songDuration);
    songPosition = Duration.zero;

    onComplete = player.onPlayerComplete.listen((event) {
      playing = false;
      current = null;
      if (mounted) setState(() => ended = true);
    });
    current = widget.file;
    loaded = true;
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

  void seekToMillisecond(int milliseconds) async {
    if (ended == true || current == null) {
      ended = false;
      current = widget.file;
      await player.play(DeviceFileSource(widget.file.path));
      
      if (playing == false) player.pause();
    }
    Duration newDuration = Duration(milliseconds: milliseconds);
    player.seek(newDuration);
  }
  bool draggingVolume = false;

  void togglePlaying({override}) {
    bool status = !playing;
    if (override != null) status = override;

    if (ended == true && looping == false) {
      player.play(DeviceFileSource(widget.file.path));
      playing = true;
      ended = false;
      return;
    }

    playing = status;
    if (playing) {
      player.resume();
    } else {
      player.pause();
    }
  }

  void toggleLooping() {
    if (ended == false) {
      looping = !looping;
      if (looping) {
        player.setReleaseMode(ReleaseMode.loop);
      } else {
        player.setReleaseMode(ReleaseMode.release);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String filename = basename(widget.file.path);
    return loaded ? Container(
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
                StatefulBuilder(
                  builder: (BuildContext ctx, StateSetter setMainState) {
                    return GestureDetector(
                      onTapUp: (details) => setState(() =>togglePlaying()),
                      onVerticalDragStart:(details) => setMainState(()=> draggingVolume = true),
                      onVerticalDragUpdate: (details) {
                        double delta = details.delta.dy / 100;
                        setMainState(() => volume = clampDouble(volume - delta, 0, 1));
                        player.setVolume(volume);
                      },
                      onVerticalDragCancel: () => setMainState(() => draggingVolume = false),
                      onVerticalDragEnd: (details) => setMainState(() => draggingVolume = false),
                      child: Container(
                        height: 250,
                        width: 250,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 1.2 * clampDouble(-volume * (volume - 2), 0.2, 1),
                            colors: [
                              Color.alphaBlend(
                                Theme.of(context).colorScheme.secondary.withOpacity(-(volume*(volume)) + 1), 
                                Theme.of(context).colorScheme.primary.withOpacity(volume)
                              ),
                              Color.alphaBlend(
                                Theme.of(context).colorScheme.surface.withOpacity(-(volume*(volume)) + 1), 
                                Theme.of(context).colorScheme.secondary.withOpacity(volume)
                              ),
                            ],
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 0,
                              blurRadius: 15,
                            ),
                          ],
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
                    );
                  }
                ),
                Text(
                  filename, 
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold
                  )
                ),
                StatefulBuilder(
                  builder: (BuildContext ctx, StateSetter setSliderState) {
                    
                    onPosChanged = player.onPositionChanged.listen((newPosition) {
                      if (ctx.mounted) {
                        setSliderState(() {
                          songPosition = newPosition;
                        });
                      }
                    });

                    return Row(
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
                              value: clampDouble(songPosition.inMilliseconds.toDouble(), 0, songDuration.inMilliseconds.toDouble()) ,
                              min: 0.0,
                              max: songDuration.inMilliseconds.toDouble(),
                              onChanged: (double value) {
                                setSliderState(() {
                                  seekToMillisecond(value.toInt());
                                });
                              },
                              onChangeEnd:(value) {
                                togglePlaying(override: true);
                              },
                            ),
                          ),
                        ),
                        Text(formatTime(songDuration.inSeconds))
                      ],
                    );
                  }
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ImageButton(
                      image: (playing == false || ended == true) ? "play.png" : "pause.png",
                      color: Theme.of(context).colorScheme.onBackground,
                      pressUp: () => {
                        setState(() => togglePlaying())
                      },
                    ),
                    ImageButton(
                      image: "repeat.png",
                      color: looping ? Theme.of(context).colorScheme.onBackground : Theme.of(context).colorScheme.secondary,
                      pressUp: () => {
                        setState(() => toggleLooping())
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
    ) : Container(
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
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/note.png',
              height: 125,
              width: 125,
              fit: BoxFit.cover,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(
              width: 175,
              height: 175,
              child: CircularProgressIndicator(
                strokeWidth: 20,
              )
            ),
          ],
        ),
      ), 
    );
  }
}