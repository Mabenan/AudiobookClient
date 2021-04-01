import 'dart:convert';
import 'dart:typed_data';

import 'package:audiobookclient/bookdownloader.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class DetailRouteArguments {
  DetailRouteArguments({this.album});
  final ParseObject album;
}

class DetailWidget extends StatefulWidget {
  DetailWidget({Key key, this.album}) : super(key: key);
  final ParseObject album;
  @override
  State<StatefulWidget> createState() => _DetailWidgetState(album: this.album);
}

class _DetailWidgetState extends State<DetailWidget> {
  _DetailWidgetState({this.album});
  final ParseObject album;
  @override
  Widget build(BuildContext context) {
    Widget image = Icon(
      Icons.image,
      size: 250,
    );
    if (album.get("Cover") != null) {
      Uint8List bytes = base64.decode(album.get("Cover"));
      image = Image.memory(
        bytes,
        width: 250,
        height: 250,
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          image,
          StreamBuilder(
            stream: BookMaster().getBook(album).canDownload,
            initialData: false,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data) {
                return ElevatedButton (
                  child: new Text("Download"),
                  onPressed: () =>
                      {BookMaster().getBook(album)..startDownload()},
                );
              } else {
                return Container();
              }
            },
          ),
          StreamBuilder(
            stream: BookMaster().getBook(album).canPlay,
            initialData: false,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data) {
                return ElevatedButton (
                  child: new Text("Play"),
                  onPressed: () => {BookMaster().getBook(album).play()},
                );
              } else {
                return Container();
              }
            },
          ),
          StreamBuilder(
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
          )
        ],
      ),
    );
  }
}
