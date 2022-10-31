import 'package:catbooks/data/album.dart';
import 'package:catbooks/data/listening.dart';
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
  }

  final AudioPlayer player;

  BehaviorSubject<Album?> _currentAlbum = BehaviorSubject<Album?>();
  Stream<Album?> get currentAlbum => _currentAlbum.stream;
  BehaviorSubject<Duration?> _durationLeft = BehaviorSubject<Duration?>();
  Stream<Duration?> get durationLeft => _durationLeft.stream;

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
  }

  void replay(Duration duration) {
    var newDuration = player.position - duration;
    if(newDuration.isNegative){
      newDuration = Duration.zero;
    }
    player.seek(newDuration);
  }

  void recalcDurationLeft() async {
    var album = await currentAlbum.last;
    List<Track> alreadyPlayed = List.empty();
    if(player.currentIndex! > 0) {
      alreadyPlayed = album!.tracks.sublist(0, player.currentIndex! - 1);
    }
    var alreadyPlayedDuration = Duration.zero;
    for (var track in alreadyPlayed) {
      alreadyPlayedDuration += Duration(seconds: track.length);
    }
    var currentDuration = alreadyPlayedDuration + player.position;
    _durationLeft.add(fullLength - currentDuration);
  }

  void savePosition() {
    _listening!.duration = player.duration!;
    _listening!.track = player.currentIndex!;
    saveListening(_currentAlbum.value!.id, _listening!);
  }

}