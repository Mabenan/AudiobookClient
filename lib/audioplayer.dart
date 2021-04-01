import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class Player {
  final AudioPlayer player = new AudioPlayer();
  ParseObject _currentAlbum;
  ParseObject _listening;
  final _currentAlbumStream = BehaviorSubject<ParseObject>();

  List<ParseObject> tracks;
  Stream<ParseObject> get currentAlbumStream => _currentAlbumStream.stream;

  setAlbum(ParseObject album, List<ParseObject> tracks) {
    this._currentAlbum = album;
    _currentAlbumStream.add(album);
    this.tracks = tracks;
  }

  play() async {
    var listening = await (QueryBuilder(ParseObject("Listening"))
          ..whereEqualTo("User", await ParseUser.currentUser())
          ..whereEqualTo("Album", _currentAlbum))
        .query();
    if (listening.success && listening.results != null) {
      _listening = listening.results.first;
      _listening.set("User", await ParseUser.currentUser());
      _listening.set("Album", _currentAlbum);
    } else {
      _listening = ParseObject("Listening");
      _listening.set("User", await ParseUser.currentUser());
      _listening.set("Album", _currentAlbum);
      _listening.set("Track", tracks.first);
      _listening.set("Progress", 0);
      var resp = await _listening.save();

      if (resp.success && resp.results != null) {
        _listening = resp.results.first;
      }
    }
    var firstTrack = _listening.get("Track").objectId;
    var start = tracks.indexWhere((element) => element.objectId == firstTrack);
    var startDuration = new Duration(seconds: _listening.get("Progress"));
    final directory = await getApplicationDocumentsDirectory();
    await Player().player.setAudioSource(
          ConcatenatingAudioSource(
            // Start loading next item just before reaching it.
            useLazyPreparation: true, // default
            // Customise the shuffle algorithm.
            shuffleOrder: DefaultShuffleOrder(), // default
            // Specify the items in the playlist.
            children: List<AudioSource>.from(tracks.map((e) => AudioSource.uri(
                Uri.file(directory.path + "/audioBooks/" + e.get("File"))))),
          ),
          // Playback will be prepared to start from track1.mp3
          initialIndex: start, // default
          // Playback will be prepared to start from position zero.
          initialPosition: startDuration, // default
        );
    player.play();
  }

  static final Player _singleton = Player._internal();
  factory Player() {
    return _singleton;
  }
  Player._internal() {
    player.positionStream.listen((event) async {
      ParseObject currentTrack = tracks.elementAt(player.currentIndex);
      _listening.set("User", await ParseUser.currentUser());
      _listening.set("Album", _currentAlbum);
      _listening.set("Track", currentTrack);
      _listening.set("Progress", event.inSeconds);
      var resp = await _listening.save();

      if (resp.success && resp.results != null) {
        _listening = resp.results.first;
      }
    });
  }
}

class AudioplayerWidget extends StatefulWidget {
  AudioplayerWidget({key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioplayerWidget> {
  _AudioPlayerState();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ParseObject>(
        stream: Player().currentAlbumStream,
        initialData: null,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.data != null) {
            Uint8List bytes = base64.decode(asyncSnapshot.data.get("Cover"));
            return FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.1,
              child: Container(
                child: Row(
                  children: [
                    Image.memory(
                      bytes,
                      width: 50,
                      height: 50,
                    ),
                    Text(asyncSnapshot.data.get("Name")),
                    Spacer(),
                    StreamBuilder<PlayerState>(
                      stream: Player().player.playerStateStream,
                      builder: (context, asyncSnapshot) {
                        if (asyncSnapshot.data != null) {
                          final bool isPlaying = asyncSnapshot.data.playing;
                          return Container(
                              child: GestureDetector(
                            child: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                size: 50),
                            onTap: () => {
                              isPlaying
                                  ? Player().player.pause()
                                  : Player().player.play()
                            },
                          ));
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return FractionallySizedBox(
                widthFactor: 1, heightFactor: 0.001, child: Container());
          }
        });
  }
}
