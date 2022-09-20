import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:catbooks/app_ids.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import 'data/album.dart';
import 'data/listening.dart';
import 'globals.dart';

const String STORAGE_SESSION_ID = "SESSION_ID";

const String STORAGE_LOCAL_ALBUM = "ALBUM";
const String STORAGE_LISTENING = "LISTENING";

Map<String, Future<Null>> locks = Map<String,Future<Null>>();

Future<List<String>> getLocalLibrary() async {
  List<String> albumsInLibrary = List.empty(growable: true);
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
    var serverAlbum = await Album.fromServer(await Database(client).getDocument(collectionId: COLLECTION_ALBUM, documentId: albumId));
    var localAlbumJSON = jsonEncode(serverAlbum.toJson());

    await box.put(albumId, localAlbumJSON);
    return serverAlbum;
  }
  }catch(e){
    print(e);
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
    print(e);
  }finally{
    lock.complete();
  }
}

Future<Completer<Null>> awaitLock(String lockObject) async {

  if (locks.containsKey(lockObject)) {
    await locks[lockObject]; // wait for future complete
  }

  // lock
  var completer = new Completer<Null>();
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
      var listening = Listening(track: 0, duration: Duration());
      var listeningJSON = jsonEncode(Listening(track: 0, duration: Duration()).toJson());

      await box.put(albumId, listeningJSON);
      return listening;
    }
  }catch(e){
    print(e);
  }finally{
    lock.complete();
  }
}