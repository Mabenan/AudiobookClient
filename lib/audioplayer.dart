import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import 'background.dart';
import 'data/album.dart';
import 'data/track.dart';

class AudioplayerWidget extends StatefulWidget {
  AudioplayerWidget({key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioplayerWidget> {
  int sleepCountdown;

  StreamSubscription sub;

  Duration sleepTimer;

  _AudioPlayerState();
  bool big = false;
  int selectedTimer = 0;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressStream>(
        stream: AudioPlayerFrontendService().progressStream,
        initialData: null,
        builder: (context, progressStream) {
          if (progressStream.data != null) {
            return FractionallySizedBox(
              widthFactor: 1,
              heightFactor: big ? 0.9 : 0.1,
              child: big
                  ? buildDetailPlayer(context, progressStream.data)
                  : buildMiniPlayer(progressStream.data),
            );
          } else {
            return FractionallySizedBox(
                widthFactor: 1, heightFactor: 0.001, child: Container());
          }
        });
  }

  buildMiniPlayer(ProgressStream currentPlayerStream) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 50,
            child: GestureDetector(
              child: currentPlayerStream.album.image50x50,
              onTap: () {
                setState(() {
                  big = true;
                });
              },
            ),
          ),
          Expanded(
            child: GestureDetector(
                child: Container(
                  padding: EdgeInsets.only(left: 5, right: 5),
                  child: Marquee(
                    text: currentPlayerStream.album.name +
                        "|" +
                        currentPlayerStream.track.name,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: Duration(seconds: 1),
                  ),
                ),
              onTap: () {
                setState(() {
                  big = true;
                });
              },
            ),
          ),
          buildRewind30(currentPlayerStream),
          buildPlayIcon(),
        ],
      ),
    );
  }

  Container buildRewind30(ProgressStream currentPlayerStream) {
    return Container(
        width: 50,
        child: GestureDetector(
          child: Icon(Icons.replay_30, size: 50),
          onTap: () {
            if (currentPlayerStream.progress >= 30) {
              AudioService.seekTo(
                  Duration(seconds: currentPlayerStream.progress - 30));
            }
          },
        ));
  }

  Container buildForward30(ProgressStream currentPlayerStream) {
    return Container(
        width: 50,
        child: GestureDetector(
          child: Icon(Icons.forward_30, size: 50),
          onTap: () {
            AudioService.seekTo(
                Duration(seconds: currentPlayerStream.progress + 30));
          },
        ));
  }

  Container buildNext(ProgressStream currentPlayerStream) {
    return Container(
        child: GestureDetector(
      child: Icon(Icons.skip_next_outlined, size: 50),
      onTap: () {
        AudioService.seekForward(false);
      },
    ));
  }

  Container buildLast(ProgressStream currentPlayerStream) {
    return Container(
        child: GestureDetector(
      child: Icon(Icons.skip_previous_outlined, size: 50),
      onTap: () {
        if (currentPlayerStream.progress > 10) {
          AudioService.seekTo(Duration(seconds: 0));
        } else {
          AudioService.seekBackward(false);
        }
      },
    ));
  }

  StreamBuilder<PlaybackState> buildPlayIcon() {
    return StreamBuilder<PlaybackState>(
      stream: AudioService.playbackStateStream,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.data != null) {
          final bool isPlaying = asyncSnapshot.data.playing;
          return Container(
              width: 50,
              child: GestureDetector(
                child: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 50),
                onTap: () =>
                    {isPlaying ? AudioService.pause() : AudioPlayerFrontendService().play()},
              ));
        } else {
          return Container();
        }
      },
    );
  }

  buildDetailPlayer(BuildContext context, ProgressStream currentPlayerStream) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down),
                iconSize: 64,
                onPressed: () => {
                  setState(() {
                    big = false;
                  })
                },
              ),
            ],
          ),
          Container(
            height: 180,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: currentPlayerStream.album.image256x256,
                ),
                Container(
                  alignment: Alignment.center,
                  child: sleepTimer != null && sleepTimer.inSeconds > 0
                      ? Text(sleepTimer.toString())
                      : Container(),
                )
              ],
            ),
          ),
          Text(currentPlayerStream.album.name),
          Text(currentPlayerStream.track.name),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: currentPlayerStream.progress /
                      currentPlayerStream.track.length.round(),
                  semanticsLabel: 'Progress Indicator',
                ),
                Row(
                  children: [
                    Text(getRemaininInTrack(currentPlayerStream)),
                    Spacer(),
                    Text(getTrackDuration(currentPlayerStream)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 60),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, //Center Column contents vertically,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildLast(currentPlayerStream),
              buildRewind30(currentPlayerStream),
              buildPlayIcon(),
              buildForward30(currentPlayerStream),
              buildNext(currentPlayerStream),
            ],
          ),
          Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, //Center Column contents vertically,
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
                                      ? TextStyle(color: Colors.orange)
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

  String getRemaininInTrack(ProgressStream currentPlayerStream) {
    var durString = Duration(seconds: currentPlayerStream.progress).toString();
    return durString.substring(0, durString.length - 7);
  }

  String getTrackDuration(ProgressStream currentPlayerStream) {
    var durString = Duration(
            seconds: currentPlayerStream.track.length.round() -
                currentPlayerStream.progress)
        .toString();
    return "-" + durString.substring(0, durString.length - 7);
  }

  void setSleepTimer(int i) {
    selectedTimer = i;
    sleepCountdown = i * 60;
    if (sub != null) {
      sub.cancel();
    }
    if (i != 0) {
      if (!AudioService.playbackState.playing) {
        AudioPlayerFrontendService().play();
      }
      sub = new Stream.periodic(const Duration(seconds: 1), (_) {
        if (AudioService.playbackState.playing) {
          sleepCountdown--;
        }
      }).listen((event) {
        if (sleepCountdown <= 0) {
          selectedTimer = 0;
          sub.cancel();
          AudioService.pause();
        }
        setState(() {
          sleepTimer = Duration(seconds: sleepCountdown);
        });
      });
    }
  }
}
