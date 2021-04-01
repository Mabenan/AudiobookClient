import 'dart:io';
import 'dart:convert';
import 'package:audiobookclient/audioplayer.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

class BookMaster {
  Map<String, Book> bookMasters = {};
  static final BookMaster _singleton = BookMaster._internal();

  factory BookMaster() {
    return _singleton;
  }

  Book getBook(ParseObject album) {
    if (!bookMasters.containsKey(album.objectId)) {
      bookMasters.addAll({album.objectId: new Book(album)});
    }
    return bookMasters[album.objectId];
  }

  BookMaster._internal();
}

class DownloadProgress {
  final double percent;
  final int bytes;
  DownloadProgress(this.percent, this.bytes);
}

class Book {
  final ParseObject album;
  List<ParseObject> tracks;
  List<ParseObject> tracksToFetch = [];
  List<ParseObject> tracksDownloaded = [];
  final _progress = BehaviorSubject<DownloadProgress>();
  final _canDownload = BehaviorSubject<bool>();
  final _canPlay = BehaviorSubject<bool>();
  int downloadSize = 0;
  int totalDownload = 0;
  bool downloadRunning = false;
  Stream<DownloadProgress> get progressStream => _progress.stream;
  Stream<bool> get canDownload => _canDownload.stream;
  Stream<bool> get canPlay => _canPlay.stream;

  Book(this.album) {
    _canDownload.add(false);
    _canPlay.add(false);
    init();
  }

  play() async {
    Player().setAlbum(album, tracksDownloaded);
    Player().play();

  }

  init() async {
    tracksToFetch.clear();
    await this.getTracks();
    await Future.forEach(
        tracks, (element) async => {await getTrackLength(element)});
    if (tracksToFetch.length > 0) {
      _canDownload.add(true);
    }
    if (tracksDownloaded.length > 0) {
      tracksDownloaded.sort(
          (a, b) => (a.get("Order") as int).compareTo((b.get("Order") as int)));
      _canPlay.add(true);
    }
  }

  download(ParseObject track) async {
    File file;
    var fileUrl = track.get("File");
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      String path = directory.path + "/audioBooks/" + fileUrl;
      file = new File(path);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      } else {
        file.delete();
        file.createSync(recursive: true);
      }
    }
    var uri = Uri.parse(ParseCoreData().serverUrl + "/stream/" + fileUrl);
    final request = http.Request('GET', uri);
    request.headers
        .addAll({"x-parse-session-token": ParseCoreData().sessionId});
    final http.StreamedResponse resp = await http.Client().send(request);
    await for (List<int> event in resp.stream) {
      this.totalDownload = this.totalDownload + event.length;
      double progress = (this.totalDownload / this.downloadSize * 100);
      _progress.add(new DownloadProgress(progress, this.totalDownload));
      if (!kIsWeb) {
        file.writeAsBytesSync(event, mode: FileMode.append);
      }
    }
  }

  startDownload() async {
    _canDownload.add(false);
    _progress.add(new DownloadProgress(0, 0));
    await Future.forEach(
        tracksToFetch, (track) async => {await download(track)});
    this.downloadSize = 0;
    tracksToFetch.clear();
    tracksDownloaded.clear();
    await Future.forEach(
        tracks, (element) async => {await getTrackLength(element)});
    if (tracksToFetch.length > 0) {
      _canDownload.add(true);
    }
    if (tracksDownloaded.length > 0) {
      tracksDownloaded.sort(
          (a, b) => (a.get("Order") as int).compareTo((b.get("Order") as int)));
      _canPlay.add(true);
    }
    this.totalDownload = 0;
    _progress.add(new DownloadProgress(0.0, 0));
  }

  Future getTrackLength(ParseObject track) async {
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      var fileUrl = track.get("File");
      String path = directory.path + "/audioBooks/" + fileUrl;
      File file = new File(path);
      if (file.existsSync()) {
        Digest hash = sha1.convert(file.readAsBytesSync());
        if (base64.encode(hash.bytes) != track.get("Hash")) {
          downloadSize = downloadSize + track.get("Size");
          tracksToFetch.add(track);
        } else {
          tracksDownloaded.add(track);
        }
      } else {
        downloadSize = downloadSize + track.get("Size");
        tracksToFetch.add(track);
      }
    }
  }

  Future getTracks() async {
    File infoFile;
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      infoFile = File(p.join(directory.path, album.objectId + ".inf"));
      if (!infoFile.existsSync()) {
        infoFile.createSync(recursive: true);
      } else {
        String cont = infoFile.readAsStringSync();
        var list = jsonDecode(cont);
        this.tracks = List<ParseObject>.from(
            list.map((model) => ParseObject("Track").fromJson(model)));
      }
    }
    if (tracks == null) {
      var tracks = await (QueryBuilder(ParseObject("Track"))
            ..whereRelatedTo("Tracks", "Album", album.objectId)
            ..orderByAscending("Order"))
          .query();
      if (tracks.success) {
        if (tracks.results != null) {
          this.tracks = tracks.results as List<ParseObject>;
          if (!kIsWeb) {
            infoFile.writeAsStringSync(jsonEncode(this.tracks));
          }
        }
      }
    }
  }
}
