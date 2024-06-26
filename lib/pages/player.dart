// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_background/flutter_background.dart';

import '../widgets/inputs.dart';
import 'queue.dart' as queue;
import '../widgets/queue_dialog.dart' as queue_dialog;
import 'songs.dart' as songs;

class Player extends StatefulWidget {
  const Player({super.key, required this.file});

  final FileSystemEntity file;

  @override
  State<Player> createState() => _PlayerState();
}

AudioPlayer player = AudioPlayer();

StreamController onPlayerUpdateController = StreamController.broadcast();
Stream onPlayerUpdate = onPlayerUpdateController.stream;

FileSystemEntity? display;
FileSystemEntity? current;

double volume = 1.0;
//bool looping = false;
bool playing = false;
StreamSubscription? onComplete;

int loopMode =
    0; // 0 no repeat, 1 normal looping, 2 queue looping, 3 queue shuffling

void playSong(FileSystemEntity file) async {
  playing = true;

  await player.play(
    DeviceFileSource(file.path),
    mode: PlayerMode.mediaPlayer,
  );

  FlutterBackground.enableBackgroundExecution();

  if (onComplete != null) onComplete!.cancel();
  onComplete = player.onPlayerComplete.listen((event) {
    queue.queueSongEnd();
    if (queue.loop == false) {
      playing = false;
      current = null;
    }
    FlutterBackground.disableBackgroundExecution();
    onPlayerUpdateController.add(null);
  });
  current = file;
  onPlayerUpdateController.add(null);
}

class _PlayerState extends State<Player> {
  late AudioSession session;

  StreamSubscription<Duration>? onPosChanged;
  StreamSubscription? onPlayerNoise;
  StreamSubscription? onNoisyEvent;

  bool loaded = false;
  bool ended = false;
  bool localplaying = false;

  Duration songDuration = const Duration();
  Duration songPosition = const Duration();

  @override
  void initState() {
    display = widget.file;

    var selected = widget.file;
    songs.displayFiles.sort((a, b) {
      if (a.path == selected.path) return -1;
      if (b.path == selected.path) return 1;
      return 0;
    });
    songs.onSongsUpdateController.add(null);

    // update player when song finishes or updates
    onPlayerUpdate.listen((event) => {if (mounted) setState(() {})});

    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    if (onPosChanged != null) onPosChanged!.cancel();
    if (onPlayerNoise != null) onPlayerNoise!.cancel();
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
    Duration duration = (await displayPlayer.getDuration())!;
    return duration;
  }

  void getPositions() async {
    Duration position = Duration.zero;
    Duration duration = await getDuration(display!);

    if (current != null) if (display!.path == current!.path)
      position = (await player.getCurrentPosition())!;
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
      playing = false;
      if (mounted) {
        setState(() {
          playing = false;
        });
      }
      onPlayerUpdateController.add(null);
    });

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        togglePlaying(null, override: false);
      }
    });
  }

  String formatTime(int seconds) {
    List<String> time =
        '${(Duration(seconds: seconds))}'.split('.')[0].split(':');
    time.remove('0');
    return time.join(':').padLeft(1, '0');
  }

  void seekToMillisecond(int milliseconds) {
    Duration newDuration = Duration(milliseconds: milliseconds);
    if (ended == true || current == null) {
      ended = false;
      current = display;
      localplaying = playing;
      onPlayerUpdateController.add(null);

      player.play(
        DeviceFileSource(display!.path),
        mode: PlayerMode.mediaPlayer,
        position: songPosition,
      );

      if (playing == false) player.pause();
    }
    if (display!.path == current!.path) player.seek(newDuration);
  }

  bool draggingVolume = false;

  void togglePlaying(context, {override}) async {
    bool status = !playing;
    if (override != null) status = override;

    bool targetLocal = false;

    if (current != null && display!.path == current?.path) targetLocal = status;

    if ((current != display || player.source == null) &&
        localplaying == false) {
      targetLocal = true;
      playSong(display!);
    }

    if (status) {
      player.resume();
    } else {
      player.pause();
    }

    onPlayerUpdateController.add(null);
    setState(() {
      playing = status;
      localplaying = targetLocal;
    });
  }

  void toggleLooping() {
    int limit = 1;
    if (queue.queueList.isNotEmpty && queue.queueList.contains(display!.path))
      limit = 3;

    int targetMode = loopMode + 1;
    if (targetMode > limit)
      targetMode =
          0; // if targetMode is greater than the limit (1 or 3) reset to 0

    if (current != null && display!.path != current!.path) return;

    bool targetLoop = false;
    bool targetShuffle = false;

    if (targetMode != 1) player.setReleaseMode(ReleaseMode.release);
    switch (targetMode) {
      case 1: // normal looping
        targetLoop = false;
        targetShuffle = false;
        player.setReleaseMode(ReleaseMode.loop);
        break;
      case 2: // queue looping
        targetLoop = true;
        targetShuffle = false;
        break;
      case 3: // queue shuffling
        targetLoop = true;
        targetShuffle = true;
        break;
      default: // default 0: no repeat
        targetLoop = false;
        targetShuffle = false;
    }

    setState(() {
      loopMode = targetMode;
      queue.loop = targetLoop;
      queue.shuffle = targetShuffle;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (current != null) if (display!.path == current!.path)
      localplaying = playing;
    String filename = basename(display!.path);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double squareSize = screenWidth / 1.5;
    double buttonWidth = screenWidth / 5;
    if (screenHeight / screenWidth < 1.5) {
      buttonWidth = screenHeight / 8;
      squareSize = screenHeight / 4;
    }

    if (screenHeight / screenWidth < 0.7) {
      squareSize = 0;
    }

    String loopIcon = "repeat.png";
    Color loopColor = Theme.of(context).colorScheme.surface;

    switch (loopMode) {
      case 1: // normal looping
        loopColor = Theme.of(context).colorScheme.primary;
        break;
      case 2: // queue looping
        loopColor = Theme.of(context).colorScheme.inversePrimary;
        break;
      case 3: // queue shuffling
        loopIcon = "shuffle.png";
        loopColor = Theme.of(context).colorScheme.inversePrimary;
        break;
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: loaded
          ? Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
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
                            margin: const EdgeInsets.only(
                                top: kToolbarHeight / 1.5, bottom: 10),
                            child: ImageButton(
                              image: "back.png",
                              color: Theme.of(context).colorScheme.onBackground,
                              height: screenWidth / 5,
                              width: screenWidth / 5,
                              pressUp: () {
                                Navigator.pop(context, true);
                              },
                            ),
                          ),
                          GestureDetector(
                            onTapUp: (details) => togglePlaying(context),
                            onVerticalDragStart: (details) =>
                                setState(() => draggingVolume = true),
                            onVerticalDragUpdate: (details) {
                              double delta = details.delta.dy / 100;
                              setState(
                                () => volume = clampDouble(volume - delta, 0, 1)
                              );
                              player.setVolume(clampDouble(volume * volume * volume * volume, 0,1));
                            },
                            onVerticalDragCancel: () =>
                                setState(() => draggingVolume = false),
                            onVerticalDragEnd: (details) =>
                                setState(() => draggingVolume = false),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                height: squareSize, // original 250px
                                width: squareSize, // 250
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    radius: 1.2 *
                                        clampDouble(
                                            -volume * (volume - 2), 0.2, 1),
                                    colors: [
                                      Color.alphaBlend(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(
                                                  -(volume * (volume)) + 1),
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(volume)),
                                      Color.alphaBlend(
                                          Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(
                                                  -(volume * (volume)) + 1),
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(volume)),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(15)),
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
                                      'assets/note2.png',
                                      height: (squareSize / 2) *
                                          max(volume, 0.7), // original 125px
                                      width: (squareSize / 2) *
                                          max(volume, 0.7), // 125
                                      fit: BoxFit.cover,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(max(0.1, volume)),
                                    ),
                                    Container(
                                      child: (draggingVolume == true)
                                          ? Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      76, 0, 0, 0),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(15))),
                                              width: 35, // original 35px
                                              height: squareSize *
                                                  0.6, // original 150px
                                              padding: const EdgeInsets.all(10),
                                              child: RotatedBox(
                                                  quarterTurns: -1,
                                                  child:
                                                      LinearProgressIndicator(
                                                          value: volume)),
                                            )
                                          : const SizedBox(
                                              width: 0,
                                              height: 0,
                                            ),
                                    ),
                                  ],
                                )),
                          ),
                          Text(
                              // Song title
                              filename,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth / 20,
                                  )),
                          StatefulBuilder(// Time scroll
                              builder: (BuildContext ctx,
                                  StateSetter setSliderState) {
                            onPosChanged =
                                player.onPositionChanged.listen((newPosition) {
                              if (ctx.mounted &&
                                  display!.path == current!.path) {
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
                                        trackShape:
                                            const RectangularSliderTrackShape(),
                                        trackHeight: 25,
                                        thumbShape:
                                            SliderComponentShape.noThumb),
                                    child: Slider(
                                      activeColor: localplaying
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                      value: clampDouble(
                                          songPosition.inMilliseconds
                                              .toDouble(),
                                          0,
                                          songDuration.inMilliseconds
                                              .toDouble()),
                                      min: 0.0,
                                      max: songDuration.inMilliseconds
                                          .toDouble(),
                                      onChanged: (double value) {
                                        seekToMillisecond(value.toInt());
                                      },
                                    ),
                                  ),
                                ),
                                Text(formatTime(songDuration.inSeconds))
                              ],
                            );
                          }),
                          StatefulBuilder(// Buttons
                              builder: (BuildContext ctx,
                                  StateSetter setSliderState) {
                            return Row(
                              // Buttons
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ImageButton(
                                  image: "songqueue.png",
                                  color: queue.queueList.contains(display!.path)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  width: buttonWidth,
                                  pressUp: () async {
                                    await showDialog(
                                        context: context,
                                        builder: (context) => queue_dialog
                                            .queueDialog(context, display!));
                                    setState(() {});
                                  },
                                ),
                                ImageButton(
                                  image:
                                      (localplaying == false || ended == true)
                                          ? "play.png"
                                          : "pause.png",
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  width: buttonWidth,
                                  pressUp: () => togglePlaying(context),
                                ),
                                ImageButton(
                                  image: loopIcon,
                                  color: loopColor,
                                  width: buttonWidth,
                                  pressUp: () => toggleLooping(),
                                )
                              ],
                            );
                          }),
                          const SizedBox(
                            height: 40,
                          )
                        ]),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
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
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}
