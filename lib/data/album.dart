import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:catbooks/app_ids.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as path_helper;

import '../globals.dart';

class Album {
  String id;
  String name;
  String author;
  String coverFileId;
  List<Track> tracks;

  final BehaviorSubject<int> _isDownloaded = BehaviorSubject<int>();
  final BehaviorSubject<int> _downloadProgress = BehaviorSubject<int>();
  Future<void>? _downloadFuture;
  Stream<int> get isDownloaded {
    if (_isDownloaded.value == 0 && _downloadFuture == null) {
      checkDownload();
    }
    return _isDownloaded.stream;
  }
  int downloadMass = 0;
  Stream<int> get downloadProgress {
    return _downloadProgress.stream;
  }

  Album(
      {required this.id,
      required this.name,
      required this.author,
      required this.coverFileId,
      required this.tracks}) {
    _isDownloaded.add(0);
  }

  static Album fromJson(Map<String, dynamic> json) {
    var alb = Album(
      id: json["id"],
      name: json["name"],
      author: json["author"],
      coverFileId: json["coverFileID"],
      tracks: List<Track>.from(
          (json["tracks"] as Iterable).map((e) => Track.fromJson(e))),
    );
    alb.tracks.sort((a, b) {
      if(a.cdNumber == b.cdNumber ){
        if(a.trackNumber == b.trackNumber){
          return a.name.compareTo(b.name);
        }else {
          return a.trackNumber.compareTo(b.trackNumber);
        }
      }else{
        return a.cdNumber.compareTo(b.cdNumber);
      }
    });
    return alb;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "author": author,
      "coverFileID": coverFileId,
      "tracks": List.from(tracks.map((e) => e.toJson()))
    };
  }

  static Future<Album> fromServer(Document doc, {bool loadTracks = false}) async {
    return Album(
      id: doc.$id,
      name: doc.data["name"],
      author: doc.data["author"],
      coverFileId: doc.data["coverFileID"],
      tracks: loadTracks ? await getTracksFromServer(doc.$id) : List.empty(growable: true),
    );
  }
  static Album fromServerWithoutTrack(Document doc){
    return Album(
        id: doc.$id,
        name: doc.data["name"],
        author: doc.data["author"],
        coverFileId: doc.data["coverFileID"],
        tracks: List.empty(growable: true),
    );
  }

  dispose() {
    _isDownloaded.close();
    _downloadProgress.close();
  }

  static Future<List<Track>> getTracksFromServer(String id) async {
    List<Track> trackObjects =List.empty();
    try {
      List<Document> tracks = List.empty(growable: true);
      do {
        var serverTracks = await Databases(client).listDocuments(
            databaseId: DATABASE,
            collectionId: COLLECTION_TRACK,
            queries: [Query.equal("album",id), ...(tracks.isNotEmpty ? [Query.cursorAfter(tracks.last.$id)] : [])]);
        tracks.addAll(serverTracks.documents);
        if(tracks.length == serverTracks.total){
          break;
        }
      }while(true);
      trackObjects = List<Track>.from(
          tracks.map((e) => Track.fromServer(e)));
    } catch (e) {
      logger.w(e);
      trackObjects = List.empty(growable: true);
    }
    trackObjects.sort((a, b) {
      if(a.cdNumber == b.cdNumber ){
        if(a.trackNumber == b.trackNumber){
          return a.name.compareTo(b.name);
        }else {
          return a.trackNumber.compareTo(b.trackNumber);
        }
      }else{
        return a.cdNumber.compareTo(b.cdNumber);
      }
    });
    return trackObjects;
  }

  download() async {
    var albumDir = path_helper.join(await getApplicationDir(), id);
    if (!await io.Directory(albumDir).exists()) {
      io.Directory(albumDir).create(recursive: true);
    }
    Map<Track, File> trackToFile = {};
    downloadMass = 0;
    for(var track in tracks){
      trackToFile[track] = await Storage(client).getFile(bucketId: BUCKET_TRACK, fileId: track.fileid);
      downloadMass += trackToFile[track]!.sizeOriginal;
    }
    var downloadedMass = 0;
    _downloadProgress.add(1);
    await Future.wait(tracks.map((track) async {
      var trackFilePath = path_helper.join(albumDir, track.id);
      io.File file = io.File(trackFilePath);
      if (!(await file.exists())) {
        var data = await Storage(client).getFileDownload(bucketId: BUCKET_TRACK,fileId: track.fileid);
        await file.create();
        await file.writeAsBytes(data);
      }
      downloadedMass += trackToFile[track]!.sizeOriginal;
      _downloadProgress.add(downloadedMass);
      return true;
    }));
    _downloadProgress.add(0);
    downloadMass = 0;
    checkDownload();
  }

  void checkDownload() async {
    if (_downloadFuture != null) await _downloadFuture;

    var completer = Completer<void>();
    _downloadFuture = completer.future;

    if (await checkIfTracksDownloaded()) {
      _isDownloaded.add(1);
    } else {
      _isDownloaded.add(2);
    }

    completer.complete();
  }

  Future<bool> checkIfTracksDownloaded() async {
    var albumDir = path_helper.join(await getApplicationDir(), id);
    var notDownloaded = false;
    for (var track in tracks) {
      var trackFilePath = path_helper.join(albumDir, track.id);
      io.File file = io.File(trackFilePath);
      if (!(await file.exists())) {
        notDownloaded = true;
        break;
      }
    }
    return !notDownloaded;
  }

  Future<void> deleteDownload() async {
    var albumDir = path_helper.join(await getApplicationDir(), id);
    for (var track in tracks) {
      var trackFilePath = path_helper.join(albumDir, track.id);
      io.File file = io.File(trackFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    checkDownload();
  }

  Future<Uri> getArtUri() async {
    var albumDir = path_helper.join(await getApplicationDir(), id);
    if (!await io.Directory(albumDir).exists()) {
      io.Directory(albumDir).create(recursive: true);
    }
    var artFilePath = path_helper.join(albumDir, "art.jpeg");
    io.File file = io.File(artFilePath);
    if (!await file.exists()) {
      var storageFile = await Storage(client).getFileDownload(bucketId: BUCKET_COVER, fileId: coverFileId);
      await file.create();
      await file.writeAsBytes(storageFile);
    }
    return file.uri;

  }

  Future<void> refreshTracks() async {
    tracks = await getTracksFromServer(id);
    checkDownload();
  }
}

class Track {
  String id;
  String name;
  String fileid;
  String album;
  int trackNumber;
  int cdNumber;
  int length;

  Track(
      {required this.id,
      required this.name,
      required this.fileid,
      required this.album,
      required this.trackNumber,
      required this.cdNumber,
      required this.length});

  static Track fromJson(Map<String, dynamic> json) {
    return Track(
        id: json["id"],
        name: json["name"],
        fileid: json["fileid"],
        album: json["album"],
        trackNumber: json["trackNumber"],
        cdNumber: json["cdNumber"],
        length: json["length"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "fileid": fileid,
      "album": album,
      "trackNumber": trackNumber,
      "cdNumber": cdNumber,
      "length": length
    };
  }

  static Track fromServer(Document e) {
    return Track(
        id: e.$id,
        name: e.data["name"],
        fileid: e.data["fileid"],
        album: e.data["album"],
        trackNumber:  e.data["trackNumber"],
        cdNumber:  e.data["cdNumber"],
        length:  e.data["length"]);
  }

  Future<Uri> getURI() async {
    var appDir = await getApplicationDir();
    var trackFilePath = path_helper.join(appDir, album, id);
    io.File file = io.File(trackFilePath);
    return file.uri;
  }
}
