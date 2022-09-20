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
  String cover;
  List<Track> tracks;

  final BehaviorSubject<int> _isDownloaded = BehaviorSubject<int>();
  Future<Null>? _downloadFuture;
  Stream<int> get isDownloaded {
    if (_isDownloaded.value == 0 && _downloadFuture == null) {
      checkDownload();
    }
    return _isDownloaded.stream;
  }

  Album(
      {required this.id,
      required this.name,
      required this.author,
      required this.cover,
      required this.tracks}) {
    _isDownloaded.add(0);
  }

  static Album fromJson(Map<String, dynamic> json) {
    return new Album(
      id: json["id"],
      name: json["name"],
      author: json["author"],
      cover: json["cover"],
      tracks: List<Track>.from(
          (json["tracks"] as Iterable).map((e) => Track.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "author": author,
      "cover": cover,
      "tracks": List.from(tracks.map((e) => e.toJson()))
    };
  }

  static Future<Album> fromServer(Document doc) async {
    return new Album(
      id: doc.$id,
      name: doc.data["name"],
      author: doc.data["author"],
      cover: doc.data["cover"],
      tracks: await getTracksFromServer(doc),
    );
  }

  dispose() {
    _isDownloaded.close();
  }

  static Future<List<Track>> getTracksFromServer(Document doc) async {
    try {
      var serverTracks = await Database(client).listDocuments(
          collectionId: COLLECTION_TRACK, filters: ["album=" + doc.$id]);
      return List<Track>.from(
          serverTracks.documents.map((e) => Track.fromServer(e)));
    } catch (e) {
      print(e);
      return List.empty(growable: true);
    }
  }

  download() async {
    var appDir = await getApplicationDocumentsDirectory();
    var albumDir = path_helper.join(appDir.path, id);
    if (!await io.Directory(albumDir).exists()) {
      io.Directory(albumDir).create(recursive: true);
    }
    for (var track in tracks) {
      var trackFilePath = path_helper.join(appDir.path, id, track.id);
      io.File file = io.File(trackFilePath);
      if (!(await file.exists())) {
        var data = await Storage(client).getFileDownload(fileId: track.fileid);
        await file.create();
        await file.writeAsBytes(data);
      }
    }
    checkDownload();
  }

  void checkDownload() async {
    if (_downloadFuture != null) await _downloadFuture;

    var completer = Completer<Null>();
    _downloadFuture = completer.future;

    if (await checkIfTracksDownloaded()) {
      _isDownloaded.add(1);
    } else {
      _isDownloaded.add(2);
    }

    completer.complete();
  }

  Future<bool> checkIfTracksDownloaded() async {
    var appDir = await getApplicationDocumentsDirectory();
    var notDownloaded = false;
    for (var track in tracks) {
      var trackFilePath = path_helper.join(appDir.path, id, track.id);
      io.File file = io.File(trackFilePath);
      if (!(await file.exists())) {
        notDownloaded = true;
        break;
      }
    }
    return !notDownloaded;
  }

  Future<void> deleteDownload() async {
    var appDir = await getApplicationDocumentsDirectory();

    for (var track in tracks) {
      var trackFilePath = path_helper.join(appDir.path, id, track.id);
      io.File file = io.File(trackFilePath);
      if (await file.exists()) {
        await file.delete();
        break;
      }
    }
    checkDownload();
  }

  Future<Uri> getArtUri() async {
    var appDir = await getApplicationDocumentsDirectory();
    var artFilePath = path_helper.join(appDir.path, id, "art.jpeg");
    io.File file = io.File(artFilePath);
    if (!await file.exists()) {
      await file.writeAsBytes(base64Decode(cover));
    }
    return file.uri;

  }
}

class Track {
  String id;
  String name;
  String fileid;
  String album;

  Track(
      {required this.id,
      required this.name,
      required this.fileid,
      required this.album});

  static Track fromJson(Map<String, dynamic> json) {
    return new Track(
        id: json["id"],
        name: json["name"],
        fileid: json["fileid"],
        album: json["album"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "fileid": fileid,
      "album": album,
    };
  }

  static Track fromServer(Document e) {
    return new Track(
        id: e.$id,
        name: e.data["name"],
        fileid: e.data["fileid"],
        album: e.data["album"]);
  }

  Future<Uri> getURI() async {
    var appDir = await getApplicationDocumentsDirectory();
    var trackFilePath = path_helper.join(appDir.path, album, id);
    io.File file = io.File(trackFilePath);
    return file.uri;
  }
}
