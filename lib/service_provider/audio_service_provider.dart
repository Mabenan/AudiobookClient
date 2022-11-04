import 'package:catbooks/data/album.dart';
import 'package:catbooks/data/listening.dart';
import 'package:catbooks/globals.dart';
import 'package:catbooks/storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class AudioServiceProvider {

  static final AudioServiceProvider _singleton = AudioServiceProvider._internal();

  Duration fullLength = Duration.zero;

  Listening? _listening;

  factory AudioServiceProvider() {
    return _singleton;
  }

  AudioServiceProvider._internal() :
    player = AudioPlayer(){
    player.currentIndexStream.listen((event) {
      recalcDurationLeft();
      savePosition();
    });
    player.positionStream.listen((event) {
      recalcDurationLeft();
      savePosition();
    });
    service.on("timerTick").listen((event) {
      if(_sleepTimer != null){
        _sleepTimerLeft.add(_sleepTimer! - Duration(seconds: event!["tick"]));
      }
    });
    service.on("sleepTimerReached").listen((event) {
      player.pause();
    });
    _currentAlbum.add(null);
  }

  final AudioPlayer player;

  BehaviorSubject<Album?> _currentAlbum = BehaviorSubject<Album?>();
  Stream<Album?> get currentAlbum => _currentAlbum.stream;
  BehaviorSubject<Duration?> _durationLeft = BehaviorSubject<Duration?>();
  Stream<Duration?> get durationLeft => _durationLeft.stream;
  BehaviorSubject<Duration?> _sleepTimerLeft = BehaviorSubject<Duration?>();
  Stream<Duration?> get sleepTimerLeft => _sleepTimerLeft.stream;
  Duration? _sleepTimer;

  Album? get lastAlbum => _currentAlbum.value;

  loadAlbum(Album album) async{
    _listening = await getListening(album.id);
    List<AudioSource> trackSources = List.empty(growable: true);
    fullLength = Duration.zero;
    for (var track in album.tracks) {
      fullLength += Duration(seconds: track.length);
      trackSources.add(AudioSource.uri(
        await track.getURI(),
        tag: MediaItem(
          id: track.id,
          title: track.name,
          album: album.name,
          artUri: await album.getArtUri()
        )
      ));
    }
    await player.setAudioSource(ConcatenatingAudioSource(
      children: trackSources
    ));
    await player.seek(_listening!.duration, index: _listening!.track);
    _currentAlbum.add(album);
    recalcDurationLeft();
  }

  void replay(Duration duration) {
    var newDuration = player.position - duration;
    if(newDuration.isNegative){
      newDuration = Duration.zero;
    }
    player.seek(newDuration);
  }
  void forward(Duration duration) {
    print(player.duration!.inSeconds);
    var newDuration = player.duration! - (player.position + duration);
    if(newDuration.isNegative){
      newDuration = player.duration!;
    }
    player.seek((player.position + duration));
  }

  void recalcDurationLeft() {
    if(_currentAlbum.hasValue
    && _currentAlbum.value != null) {
      var album = _currentAlbum.value;
      List<Track> alreadyPlayed = List.empty();
      if (player.currentIndex! > 0) {
        alreadyPlayed = album!.tracks.sublist(0, player.currentIndex! - 1);
      }
      var alreadyPlayedDuration = Duration.zero;
      for (var track in alreadyPlayed) {
        alreadyPlayedDuration += Duration(seconds: track.length);
      }
      var currentDuration = alreadyPlayedDuration + player.position;
      _durationLeft.add(fullLength - currentDuration);
    }
  }

  void skipToNext(){
    player.seekToNext();
  }

  void skipToLast(){
    if(player.position.inSeconds > 10){
      player.seek(Duration(seconds: 0));
    }else{
      player.seekToPrevious();
    }
  }

  void sleepTimer(int i){
    _sleepTimer = Duration(minutes: i);
    _sleepTimerLeft.add(_sleepTimer);
    service.invoke("setTimer", { "duration" : _sleepTimer!.inSeconds });
    if(!player.playing){
      player.play();
    }
  }

  void savePosition() {
    if(_currentAlbum.hasValue
        && _currentAlbum.value != null) {
      _listening!.duration = player.position;
      _listening!.track = player.currentIndex!;
      saveListening(_currentAlbum.value!.id, _listening!);
    }
  }

}