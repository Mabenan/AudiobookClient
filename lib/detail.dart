
import 'package:audiobookclient/bookdownloader.dart';
import 'package:flutter/material.dart';

import 'data/album.dart';

class DetailRouteArguments {
  DetailRouteArguments({this.album});
  final Album album;
}

class DetailWidget extends StatefulWidget {
  DetailWidget({Key key, this.album}) : super(key: key);
  final Album album;
  @override
  State<StatefulWidget> createState() => _DetailWidgetState(album: this.album);
}

class _DetailWidgetState extends State<DetailWidget> {
  _DetailWidgetState({this.album});
  final Album album;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(album.name),
          album.image256x256,
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
                return ElevatedButton (
                  child: new Text("Delete"),
                  onPressed: () =>
                  {BookMaster().getBook(album)..delete()},
                );
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
          BookMaster.buildDownloadProgress(album),
        ],
      ),
    );
  }
}
