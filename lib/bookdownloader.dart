import 'dart:io';
import 'package:catbooks/background.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'data/album.dart';
import 'data/track.dart';

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


  static StreamBuilder<DownloadProgress> buildDownloadProgress(Album album) {
    return StreamBuilder(
      stream: BookMaster().getBook(album).progressStream,
      initialData: new DownloadProgress(0.0, 0),
      builder: (BuildContext context,
          AsyncSnapshot<DownloadProgress> snapshot) {
        if (snapshot.data.percent == 0.0) {
          return Container();
        } else {
          return Column(children: [
            Text(
                "${(snapshot.data.percent).toStringAsFixed(1)} Downloaded: ${(snapshot.data.bytes / 1000 / 1000).toStringAsFixed(1)} MB from ${(BookMaster().getBook(album).downloadSize / 1000 / 1000).toStringAsFixed(1)}"),
            LinearProgressIndicator(
              value: snapshot.data.percent / 100,
              semanticsLabel: 'Progress Indicator',
            )
          ]);
        }
      },
    );
  }

}

class DownloadProgress {
  final double percent;
  final int bytes;
  DownloadProgress(this.percent, this.bytes);
}

class Book {
  final Album album;
  List<Track> tracks;
  List<Track> tracksToFetch = [];
  List<Track> tracksDownloaded = [];
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
    await AudioPlayerFrontendService().playAlbum(album);
  }

  init() async {
    tracksToFetch.clear();
    await this.getTracks();
    await Future.forEach(
        tracks, (element) async => {await getTrackLength(element)});
    if (tracksToFetch.length > 0) {
      _canDownload.add(true);
    } else {
      tracksDownloaded.sort(
          (a, b) => (a.get("Order") as int).compareTo((b.get("Order") as int)));
      _canPlay.add(true);
    }
  }

  download(Track track) async {
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
    try {
      final http.StreamedResponse resp = await http.Client().send(request);
      await for (List<int> event in resp.stream) {
        this.totalDownload = this.totalDownload + event.length;
        double progress = (this.totalDownload / this.downloadSize * 100);
        _progress.add(new DownloadProgress(progress, this.totalDownload));
        if (!kIsWeb) {
          file.writeAsBytesSync(event, mode: FileMode.append);
        }
      }
    } catch (ex) {}
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

  Future getTrackLength(Track track) async {
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      var fileUrl = track.get("File");
      String path = directory.path + "/audioBooks/" + fileUrl;
      File file = new File(path);
      if (file.existsSync()) {
        if (file.lengthSync() == track.size) {
          tracksDownloaded.add(track);
        } else {
          downloadSize = downloadSize + track.get("Size");
          tracksToFetch.add(track);
        }
      } else {
        downloadSize = downloadSize + track.get("Size");
        tracksToFetch.add(track);
      }
    }
  }

  Future getTracks() async {
    this.tracks = await Tracks().getAlbum(this.album);
  }

  delete() async {
    _canPlay.add(false);
    final directory = await getApplicationDocumentsDirectory();
    if (tracksDownloaded.length > 0) {
      for (Track track in tracksDownloaded) {
        var fileUrl = track.file;
        String path = directory.path + "/audioBooks/" + fileUrl;
        File file = File(path);
        file.delete();
      }
    }
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
}
