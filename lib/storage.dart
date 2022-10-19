import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:catbooks/app_ids.dart';
import 'package:hive/hive.dart';

import 'package:catbooks/data/album.dart';
import 'package:catbooks/data/listening.dart';
import 'package:catbooks/globals.dart';

const String STORAGE_SESSION_ID = "SESSION_ID";

const String STORAGE_LOCAL_ALBUM = "ALBUM";
const String STORAGE_LISTENING = "LISTENING";

Map<String, Future<void>> locks = <String,Future<void>>{};

Future<List<String>> getLocalLibrary() async {
  var box = await Hive.openBox(STORAGE_LOCAL_ALBUM);
  return List.from(box.keys);
}

Future<Album?> getAlbum(String albumId) async {

  var lock = await awaitLock(STORAGE_LOCAL_ALBUM);
  var box = await Hive.openBox(STORAGE_LOCAL_ALBUM);
  try {
    if (box.containsKey(albumId)) {
      String? localAlbumJSON = box.get(albumId);
      return Album.fromJson(jsonDecode(localAlbumJSON!));
    }else{
      var serverAlbum = await Album.fromServer(await Databases(client).getDocument(databaseId: DATABASE, collectionId: COLLECTION_ALBUM, documentId: albumId), loadTracks: true);
      var localAlbumJSON = jsonEncode(serverAlbum.toJson());

      await box.put(albumId, localAlbumJSON);
      return serverAlbum;
    }
  }catch(e){
    logger.w(e);
  }finally{
    lock.complete();
  }
}

Future<void> removeAlbumFromLocalStorage(String album) async {
  var lock = await awaitLock(STORAGE_LOCAL_ALBUM);
  var box = await Hive.openBox(STORAGE_LOCAL_ALBUM);
  try {
    if (box.containsKey(album)) {
      box.delete(album);
    }
  }catch(e){
    logger.w(e);
  }finally{
    lock.complete();
  }
}

Future<Completer<void>> awaitLock(String lockObject) async {

  if (locks.containsKey(lockObject)) {
    await locks[lockObject]; // wait for future complete
  }

  // lock
  var completer = Completer<void>();
  locks[lockObject] = completer.future;
  locks[lockObject]!.then((value) => locks.remove(lockObject));
  return completer;
}


Future<Listening?> getListening(String albumId) async{
  var lock = await awaitLock(STORAGE_LISTENING);
  var box = await Hive.openBox(STORAGE_LISTENING);
  try {
    if (box.containsKey(albumId)) {
      String? listeningJSON = box.get(albumId);
      return Listening.fromJson(jsonDecode(listeningJSON!));
    }else{
      var listening = Listening(track: 0, duration: const Duration());
      var listeningJSON = jsonEncode(Listening(track: 0, duration: const Duration()).toJson());

      await box.put(albumId, listeningJSON);
      return listening;
    }
  }catch(e){
    logger.w(e);
  }finally{
    lock.complete();
  }
}