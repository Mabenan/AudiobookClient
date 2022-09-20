
import 'package:audio_service/audio_service.dart';

class CatbooksAudioHandler extends BaseAudioHandler
    with QueueHandler, // mix in default queue callback implementations
        SeekHandler{

  // The most common callbacks:
  Future<void> play() async {
    // All 'play' requests from all origins route to here. Implement this
    // callback to start playing audio appropriate to your app. e.g. music.
  }
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<void> skipToQueueItem(int i) async {}

  @override
  Future<void> prepareFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async{

    // mediaId is albumId

  }


}