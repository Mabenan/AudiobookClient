import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';

import 'data/album.dart';
import 'data/listening.dart';
import 'data/track.dart';
import 'package:rxdart/rxdart.dart';
import 'globals.dart' as globals;

class ProgressStream {
  final Album album;
  final Track track;
  final int progress;
  ProgressStream(this.album, this.track, this.progress);
}

void _entrypoint() => AudioServiceBackground.run(() => AudioPlayerTask());

class AudioPlayerFrontendService {
  static final AudioPlayerFrontendService _singleton =
      AudioPlayerFrontendService._internal();
  factory AudioPlayerFrontendService() {
    return _singleton;
  }
  AudioPlayerFrontendService._internal() {
    AudioService.start(backgroundTaskEntrypoint: _entrypoint).then((value) {
      Listenings().getLast().then((value) async {
        await AudioService.customAction("playAlbum", value.album);
      });
      AudioService.runningStream.listen((event) {
        if(!event){
          exit(0);
        }
      });
    });
    AudioService.customEventStream.listen((event) {
      _handleCustomEvent(event);
    });
  }

  final _progressStream = BehaviorSubject<ProgressStream>();
  Stream<ProgressStream> get progressStream => _progressStream.stream;
  final _sleepTimerStream = BehaviorSubject<Duration>();
  Stream<Duration> get sleepTimerStream => _sleepTimerStream.stream;

  void _handleCustomEvent(event) {
    Map<String, dynamic> eventData = event;
    switch (eventData["event"] as String) {
      case "progress":
        _progress(eventData["data"] as Map<String, dynamic>);
        break;
      case "sleepTimer":
        _sleepTimer(eventData["data"] as  Map<String,dynamic>);
    }
  }

  offline(bool value) async{
    await AudioService.customAction("offline", value);
  }

  sleepTimer(int i) async{
    await AudioService.customAction("sleepTimer", i);
  }

  play() async {
    if (!AudioService.running) {
      await AudioService.start(backgroundTaskEntrypoint: _entrypoint);

      var value = await Listenings().getLast();
      await AudioService.customAction("playAlbum", value.album);
    }
    AudioService.play();
  }

  playAlbum(Album album) async {
    await AudioService.customAction("playAlbum", album.objectId);
    AudioService.play();
  }

  _progress(Map<String, dynamic> eventData) async {
    _progressStream.add(ProgressStream(await Albums().get(eventData["album"]),
        await Tracks().get(eventData["track"]), eventData["progress"]));
  }

  void dispose() {
    _progressStream.close();
  }

  void _sleepTimer(Map<String, dynamic> eventData) {
    _sleepTimerStream.add(new Duration(seconds:eventData["sleepCountdown"]));
  }
}

class AudioPlayerTask extends BackgroundAudioTask {
  Album _currentAlbum;
  LocalListening _listening;
  List<Track> tracks;
  final AudioPlayer player = new AudioPlayer();
  final ConcatenatingAudioSource source = new ConcatenatingAudioSource(
      // Start loading next item just before reaching it.
      useLazyPreparation: false, // default
      // Customise the shuffle algorithm.
      shuffleOrder: DefaultShuffleOrder(),
      children: [] // default
      );

  bool _playAfterClear;

  int sleepCountdown;

  StreamSubscription<Null> sub;

  onStop() async {
    await player.pause();
    // Stop and dispose of the player.
    await player.dispose();
    // Shut down the background task.
    await super.onStop();
  }

  onCustomAction(name, arguments) async {
    switch (name) {
      case "playAlbum":
        await playAlbum(arguments);
        break;
      case "sleepTimer":
        await sleepTimer(arguments);
        break;
      case "offline":
        await offline(arguments);
    }
  }

  playAlbum(String objectId) async {
    await player.pause();
    _currentAlbum = await Albums().get(objectId);
    tracks = await Tracks().getAlbum(_currentAlbum);
    tracks.sort((a, b) => a.order.compareTo(b.order));
    _listening = null;
    await setup();
  }

  onStart(Map<String, dynamic> params) async {
    await globals.initParse(back: true);
    ParseUser user = await ParseUser.currentUser();
    if (user != null) {
      if (!await globals.isOffline()) {
        await user.getUpdatedUser();
      }
    }
    await player.setAudioSource(source, preload: false);
    player.positionStream.listen((event) async {
      try {
        if (tracks != null) {
          Track currentTrack = tracks.elementAt(player.currentIndex);
          var mi = MediaItem(
            id: currentTrack.objectId,
            album: _currentAlbum.name,
            title: currentTrack.name,
            artUri: await _currentAlbum.imageUri,
          );
          AudioServiceBackground.setMediaItem(mi);
          _listening.track = currentTrack.objectId;
          if (player.playerState.playing) {
            _listening.progress = player.position.inSeconds;
          }
          sendStreams();
        }
      } catch (ex) {}
    });
    player.playerStateStream.listen((playerState) {
      // ... and forward them to all audio_service clients.
      AudioServiceBackground.setState(
        playing: playerState.playing,
        // Every state from the audio player gets mapped onto an audio_service state.
        processingState: {
          ProcessingState.idle: AudioProcessingState.none,
          ProcessingState.loading: AudioProcessingState.connecting,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[playerState.processingState],
        // Tell clients what buttons/controls should be enabled in the
        // current state.
        controls: [
          MediaControl.skipToPrevious,
          player.playerState.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
      );
    });

    Stream.periodic(new Duration(seconds: 5), (comp) => comp).listen((event) {
      if(_listening != null)
        sendStreams();
    });
  }

  void sendStreams() {
    AudioServiceBackground.sendCustomEvent({
      "event": "progress",
      "data": {
        "album": this._currentAlbum.objectId,
        "track": _listening.track,
        "progress": _listening.progress,
      },
    });
    AudioServiceBackground.sendCustomEvent({
      "event": "sleepTimer",
      "data": {
        "sleepCountdown": sleepCountdown
      },
    });
  }

  setup() async {
    if (this._listening == null)
      this._listening = await Listenings().getAlbum(this._currentAlbum);
    if (this._listening == null) {
      this._listening = LocalListening(
          user: (await ParseUser.currentUser() as ParseUser).objectId,
          album: _currentAlbum.objectId,
          track: tracks.first.objectId,
          progress: 0);
      await Listenings().add(this._listening);
    }
    var firstTrack = this._listening.track;
    var start = tracks.indexWhere((element) => element.objectId == firstTrack);
    if (start < 0) {
      start = 0;
    }
    var startDuration = new Duration(seconds: this._listening.progress);
    final directory = await getApplicationDocumentsDirectory();
    File file = File(directory.path +
        "/audioBooks/" +
        (await Tracks().get(firstTrack)).file);
    if (!await file.exists()) {
      return;
    }
    try {
      await source.clear();
      List<AudioSource> trackSources = List<AudioSource>.from(tracks.map((e) =>
          AudioSource.uri(
              Uri.file(directory.path + "/audioBooks/" + e.get("File")))));
      await source.addAll(trackSources);
      await player.seek(startDuration, index: start);
    } catch (ex) {
      return;
    }

    AudioServiceBackground.sendCustomEvent({
      "event": "progress",
      "data": {
        "album": this._currentAlbum.objectId,
        "track": tracks[start].objectId,
        "progress": _listening.progress,
      },
    });
    AudioServiceBackground.setState(
      playing: player.playerState.playing,
      // Every state from the audio player gets mapped onto an audio_service state.
      processingState: {
        ProcessingState.idle: AudioProcessingState.none,
        ProcessingState.loading: AudioProcessingState.connecting,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.playerState.processingState],
      // Tell clients what buttons/controls should be enabled in the
      // current state.
      controls: [
        MediaControl.skipToPrevious,
        player.playerState.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
    );
    // Listen to state changes on the player...
  }

  onPlay() => player.play();
  onPause() => player.pause();
  onSeekTo(Duration duration) => player.seek(duration);
  onSetSpeed(double speed) => player.setSpeed(speed);
  onSkipToNext() => player.seekToNext();
  onSkipToPrevious() => player.seekToPrevious();

  sleepTimer(int i) async{

    sleepCountdown = i * 60;
    if (sub != null){
     await sub.cancel();
    }
    if (i != 0) {
      if (!AudioServiceBackground.state.playing) {
        onPlay();
      }
      sub = new Stream.periodic(const Duration(seconds: 1), (_) {
        if (AudioServiceBackground.state.playing) {
          sleepCountdown--;
        }
      }).listen((event) {
        if (sleepCountdown <= 0) {
          sub.cancel();
          onPause();
        }
      });
    }
  }

  offline(bool value) {
    globals.offline = value;
  }
}
