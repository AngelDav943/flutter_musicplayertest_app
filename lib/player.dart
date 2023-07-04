// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'package:audio_session/audio_session.dart';

import 'widgets/inputs.dart';
import 'queue.dart' as queue;

class Player extends StatefulWidget {
  const Player({super.key, required this.file});

  final FileSystemEntity file;

  @override
  State<Player> createState() => _PlayerState();
}

AudioPlayer player = AudioPlayer();

StreamController onPlayerUpdateController = StreamController.broadcast();
Stream onPlayerUpdate = onPlayerUpdateController.stream;

var display;
var current;

double volume = 1.0;
bool looping = false;
bool playing = false;
var onComplete;

void playSong(FileSystemEntity file) async {
  playing = true;
  
  await player.play(
    DeviceFileSource(file.path),
    mode: PlayerMode.mediaPlayer,
  );
  
  onComplete = player.onPlayerComplete.listen((event) {
    queue.queueSongEnd();
    if (queue.loop == false) {
      playing = false;
      current = null;
    }
    onPlayerUpdateController.add(null);
  });
  current = file;
  onPlayerUpdateController.add(null);
}

class _PlayerState extends State<Player> {

  late AudioSession session;

  var onPosChanged;
  var onPlayerNoise;
  var onNoisyEvent;

  bool loaded = false;
  bool ended = false;
  bool localplaying = false;

  Duration songDuration = const Duration();
  Duration songPosition = const Duration();

  @override
  void initState() {
    display = widget.file;
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    if (onPosChanged != null) onPosChanged.cancel();
    if (onPlayerNoise != null) onPlayerNoise.cancel();
    super.dispose();
  }

  void initPlayer() {
    AudioSession.instance.then((session) async {
      await session.configure(const AudioSessionConfiguration.music());
      handleInterruptions(session);
    });
    
    getPositions();
    loaded = true;
  }

  Future<Duration> getDuration(FileSystemEntity file) async {
    AudioPlayer displayPlayer = AudioPlayer();
    await displayPlayer.setSource(DeviceFileSource(file.path));
    var duration = (await displayPlayer.getDuration())!;
    return duration;
  }

  void getPositions() async {
    var position = Duration.zero;
    var duration = await getDuration(display);

    if (display == current) position = (await player.getCurrentPosition())!;
    setState(() {
      songPosition = position;
      songDuration = duration;
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

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        togglePlaying(null, override: false);
      }
    });
  }

  String formatTime(int seconds) {
    var time = '${(Duration(seconds: seconds))}'.split('.')[0].split(':');
    time.remove('0');
    return time.join(':').padLeft(1, '0');
  }

  void seekToMillisecond(int milliseconds) {
    if (ended == true || current == null) {
      ended = false;
      current = display;
      onPlayerUpdateController.add(null);

      player.play(
        DeviceFileSource(display.path),
        mode: PlayerMode.mediaPlayer,
      );
      
      if (playing == false) player.pause();
    }
    Duration newDuration = Duration(milliseconds: milliseconds);
    player.seek(newDuration);
  }
  bool draggingVolume = false;

  void togglePlaying(context, {override}) async {
    bool status = !playing;
    if (override != null) status = override;

    if ((current != display || player.source == null) && localplaying == false) {
      localplaying = true;
      playSong(display);
      return;
    }

    if (ended == true && looping == false) {
      player.play(DeviceFileSource(display.path));
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

    if (display == current) localplaying = playing;
    onPlayerUpdateController.add(null);
  }

  void toggleLooping() {
    if (ended == false) {
      if (!looping && queue.loop == false) { // activate looping
        looping = true;
        player.setReleaseMode(ReleaseMode.loop);
      } else { // disable looping
        looping = false;
        player.setReleaseMode(ReleaseMode.release);
        queue.loop = !queue.loop;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (display == current) localplaying = playing;
    String filename = basename(display.path);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: loaded ? Container(
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
                    onTapUp: (details) => setState(() {
                      togglePlaying(context);
                    }),
                    onVerticalDragStart:(details) => setState(()=> draggingVolume = true),
                    onVerticalDragUpdate: (details) {
                      double delta = details.delta.dy / 100;
                      setState(() => volume = clampDouble(volume - delta, 0, 1));
                      player.setVolume(volume);
                    },
                    onVerticalDragCancel: () => setState(() => draggingVolume = false),
                    onVerticalDragEnd: (details) => setState(() => draggingVolume = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
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
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
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
                                borderRadius: BorderRadius.all(Radius.circular(15))
                              ),
                              width: 30,
                              height: 150,
                              padding: const EdgeInsets.all(10),
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: LinearProgressIndicator(value: volume)
                              ),
                            ) : const SizedBox(width: 0,height: 0,),
                          ),
                        ],
                      )
                    ),
                  ),
                  Text(
                    filename,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  StatefulBuilder(
                    builder: (BuildContext ctx, StateSetter setSliderState) {
                      
                      onPosChanged = player.onPositionChanged.listen((newPosition) {
                        if (ctx.mounted && display == current) {
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
                                activeColor: localplaying ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                                value: clampDouble(songPosition.inMilliseconds.toDouble(), 0, songDuration.inMilliseconds.toDouble()) ,
                                min: 0.0,
                                max: songDuration.inMilliseconds.toDouble(),
                                onChanged: (double value) {
                                  seekToMillisecond(value.toInt());
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
                        image: "songqueue.png",
                        color: queue.queueList.contains(display) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                        pressUp: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => queue.queueDialog(context, display)
                          );
                          setState(() {});
                        },
                      ),
                      ImageButton(
                        image: (localplaying == false || ended == true) ? "play.png" : "pause.png",
                        color: Theme.of(context).colorScheme.onBackground,
                        pressUp: () => setState(() {
                          togglePlaying(context);
                        }),
                      ),
                      ImageButton(
                        image: "repeat.png",
                        color: queue.loop ? Theme.of(context).colorScheme.inversePrimary : looping ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                        pressUp: () => setState(() => toggleLooping()),
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
      ),
    );
  }
}