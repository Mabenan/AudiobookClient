import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audiobookclient/bookdownloader.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audiobookclient/detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';

class LibraryWidget extends StatefulWidget {
  LibraryWidget({key, this.player}) : super(key: key);
  final AudioPlayer player;
  @override
  State<StatefulWidget> createState() => _LibraryWidgetState(player: player);
}

class _LibraryWidgetState extends State<LibraryWidget> {
  _LibraryWidgetState({this.player});
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) {
    QueryBuilder query = QueryBuilder<ParseObject>(ParseObject("Album"))
      ..orderByAscending('Name');
    return  ParseLiveListWidget(
            query: query,
            lazyLoading: false,
            childBuilder: (BuildContext context,
                ParseLiveListElementSnapshot<ParseObject> snapshot) {
              return buildChilds(context, snapshot);
            },
            removedItemBuilder: (BuildContext context,
                ParseLiveListElementSnapshot<ParseObject> snapshot) {
              return buildChilds(context, snapshot);
            },
    );
  }

  Widget buildChilds(BuildContext context,
      ParseLiveListElementSnapshot<ParseObject> snapshot) {
    if (snapshot.failed) {
      return const Text('something went wrong!');
    } else if (snapshot.hasData) {
      BookMaster().getBook(snapshot.loadedData); //To Preload Book Data
      Widget image = Icon(
        Icons.image,
        size: 64,
      );
      if (snapshot.loadedData.get("Cover") != null) {
        Uint8List bytes = base64.decode(snapshot.loadedData.get("Cover"));
        image = Image.memory(
          bytes,
          width: 64,
          height: 64,
        );
      }
      return GestureDetector(
        onTap: () => {
          Navigator.of(context).pushNamed("main/detail",
              arguments: DetailRouteArguments(album: snapshot.loadedData))
          // openAlbum(context, snapshot.loadedData)
        },
        child: Card(
          child: Row(
            children: [
              image,
              Expanded(
                child: Text(
                  snapshot.loadedData.get("Name"),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }
}
