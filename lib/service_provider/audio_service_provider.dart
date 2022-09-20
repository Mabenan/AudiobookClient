import 'package:catbooks/data/album.dart';
import 'package:catbooks/data/listening.dart';
import 'package:catbooks/storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioServiceProvider {

  static final AudioServiceProvider _singleton = AudioServiceProvider._internal();

  factory AudioServiceProvider() {
    return _singleton;
  }

  AudioServiceProvider._internal() :
    player = AudioPlayer();

  final AudioPlayer player;

  startAlbum(Album album) async{
    Listening? listening = await getListening(album.id);
    List<AudioSource> trackSources = List.empty(growable: true);
    for (var track in album.tracks) {
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
    await player.seek(listening!.duration, index: listening!.track);
    player.play();
  }

}