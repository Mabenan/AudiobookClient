import 'dart:io';

import 'package:catbooks/data/album.dart';
import 'package:catbooks/globals.dart';
import 'package:catbooks/service_provider/audio_service_provider.dart';
import 'package:flutter/material.dart';

class PlayerWindow extends StatefulWidget {
  const PlayerWindow({Key? key}) : super(key: key);

  @override
  State<PlayerWindow> createState() => _PlayerWindowState();
}

class _PlayerWindowState extends State<PlayerWindow> {
  int selectedTimer = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            globalNavigator.pop();
          },
        ),
      ),
      body: StreamBuilder<Album?>(
          stream: AudioServiceProvider().currentAlbum,
          builder: (context, currAlbSnap) {
            if (currAlbSnap.hasData) {
              var album = currAlbSnap.data!;
              return SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  children: [
                    Stack(alignment: AlignmentDirectional.center, children: [
                      FutureBuilder<Uri>(
                        builder: (context, uriSnap) {
                          if (uriSnap.hasData) {
                            return Image.file(
                              File.fromUri(uriSnap.data!),
                              fit: BoxFit.fitWidth,
                            );
                          } else {
                            return Container();
                          }
                        },
                        future: album.getArtUri(),
                      ),
                      StreamBuilder<Duration?>(
                        stream: AudioServiceProvider().sleepTimerLeft,
                        initialData: null,
                        builder: (context, sleepTimerLeftSnap) {
                          if (sleepTimerLeftSnap.data != null) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black12
                              ),
                              child: Center(
                                child: Text(
                                  formatDurationToMinuteAndSeconds(
                                      sleepTimerLeftSnap.data!),
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        },
                      )
                    ]),
                    Text(album.name),
                    StreamBuilder<int?>(
                      stream: AudioServiceProvider().player.currentIndexStream,
                      initialData: 0,
                      builder: (context, currIndexSnap) =>
                          Text(album.tracks[currIndexSnap.data!].name),
                    ),
                    StreamBuilder<Duration?>(
                        stream: AudioServiceProvider().player.positionStream,
                        initialData: Duration(seconds: 1),
                        builder: (context, currIndexSnap) {
                          return Container(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  value: (AudioServiceProvider()
                                              .player
                                              .position
                                              .inSeconds +
                                          1) /
                                      (AudioServiceProvider().player.duration ??
                                              Duration(seconds: 1))
                                          .inSeconds,
                                  semanticsLabel: 'Progress Indicator',
                                ),
                                Row(
                                  children: [
                                    Text(formatDurationToMinuteAndSeconds(
                                        AudioServiceProvider()
                                            .player
                                            .position)),
                                    Spacer(),
                                    Text(formatDurationToMinuteAndSeconds(
                                        (AudioServiceProvider()
                                                .player
                                                .duration ??
                                            Duration(seconds: 0)))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    Container(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, //Center Column contents vertically,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildLast(),
                        buildRewind30(),
                        buildPlayIcon(),
                        buildForward30(),
                        buildNext(),
                      ],
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, //Center Column contents vertically,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.timer),
                            iconSize: 50,
                            onPressed: () async {
                              switch (await showDialog<bool>(
                                context: context,
                                builder: (BuildContext cntx) {
                                  return SimpleDialog(
                                    title: Text("Schlafmodus Einstellungen"),
                                    children: [
                                      SimpleDialogOption(
                                        onPressed: () {
                                          setSleepTimer(0);
                                          Navigator.pop(cntx, true);
                                        },
                                        child: Text(("Schlafmodus aus"),
                                            style: 0 == selectedTimer
                                                ? TextStyle(
                                                    color: Colors.orange)
                                                : null),
                                      ),
                                      buildSleepTimerOption(cntx, 1),
                                      buildSleepTimerOption(cntx, 15),
                                      buildSleepTimerOption(cntx, 30),
                                      buildSleepTimerOption(cntx, 45),
                                      buildSleepTimerOption(cntx, 60),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(cntx, true);
                                        },
                                        child: Text("Close"),
                                      ),
                                    ],
                                  );
                                },
                              )) {
                                default:
                              }
                            },
                          ),
                        ])
                  ],
                ),
              );
            } else {
              return Container();
            }
          }),
    );
  }

  Container buildRewind30() {
    return Container(
        width: 50,
        child: GestureDetector(
          child: Icon(Icons.replay_30, size: 50),
          onTap: () {
            AudioServiceProvider().replay(Duration(seconds: 30));
          },
        ));
  }

  Widget buildPlayIcon() {
    return StreamBuilder<bool>(
      stream: AudioServiceProvider().player.playingStream,
      builder: (context, playingData) =>
          playingData.hasData && playingData.data!
              ? IconButton(
                  iconSize: 48,
                  icon: Icon(
                    Icons.pause_circle,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    AudioServiceProvider().player.pause();
                  },
                )
              : IconButton(
                  iconSize: 48,
                  icon: Icon(
                    Icons.play_circle,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    AudioServiceProvider().player.play();
                  },
                ),
    );
  }

  Container buildForward30() {
    return Container(
        width: 50,
        child: GestureDetector(
          child: Icon(Icons.forward_30, size: 50),
          onTap: () {
            AudioServiceProvider().forward(Duration(seconds: 30));
          },
        ));
  }

  Container buildNext() {
    return Container(
        child: GestureDetector(
      child: Icon(Icons.skip_next_outlined, size: 50),
      onTap: () {
        AudioServiceProvider().skipToNext();
      },
    ));
  }

  Container buildLast() {
    return Container(
        child: GestureDetector(
      child: Icon(Icons.skip_previous_outlined, size: 50),
      onTap: () {
        AudioServiceProvider().skipToLast();
      },
    ));
  }

  String formatDurationToMinuteAndSeconds(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  SimpleDialogOption buildSleepTimerOption(BuildContext cntx, int time) {
    return SimpleDialogOption(
      onPressed: () {
        setSleepTimer(time);
        Navigator.pop(cntx, true);
      },
      child: Text((time.toString() + " Minuten"),
          style:
              time == selectedTimer ? TextStyle(color: Colors.orange) : null),
    );
  }

  void setSleepTimer(int i) {
    selectedTimer = i;
    AudioServiceProvider().sleepTimer(i);
  }
}
