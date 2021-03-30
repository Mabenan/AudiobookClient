import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

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
    return Column(
      children: [
        Expanded(
          child: ParseLiveListWidget(
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
          ),
        ),
      ],
    );
  }

  Widget buildChilds(BuildContext context,
      ParseLiveListElementSnapshot<ParseObject> snapshot) {
    if (snapshot.failed) {
      return const Text('something went wrong!');
    } else if (snapshot.hasData) {
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
          // Navigator.of(context).pushNamed("main/detail", arguments: DetailRouteArguments(album : snapshot.loadedData))
          openAlbum(snapshot.loadedData)
        },
        child: Card(
          child: Row(children: [
            image,
            Text(
              snapshot.loadedData.get("Name"),
            )
          ]),
        ),
      );
    } else {
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }

  openAlbum(ParseObject album) async {
    QueryBuilder query = QueryBuilder<ParseObject>(ParseObject("Listening"));
    query.whereEqualTo("Album", album);
    var resp = await query.query();
    if (resp.success) {
      if (resp.results != null) {
      } else {
        var tracks = await (QueryBuilder(ParseObject("Track"))
              ..whereRelatedTo("Tracks", "Album", album.objectId)
              ..orderByAscending("Order"))
            .query();
        if (tracks.success) {
          if (tracks.results != null) {
            final directory = await getApplicationDocumentsDirectory();
            for (var track in tracks.results) {
              var file =
                  File(directory.path + "/audioBooks/" + track.get("File"));
              if (! await file.exists()) {
                var client = ParseCoreData().clientCreator(
                    sendSessionId: true,
                    securityContext: ParseCoreData().securityContext);
                var response = await client.getBytes(
                    getSanitisedUri(client, '/stream/' + track.get("File"))
                        .toString());
                file.writeAsBytes(response.bytes);
              }
            }
            var track = tracks.results.first as ParseObject;
            player.setFilePath(
                directory.path + "/audioBooks/" + track.get("File"));
            //player.setUrl('https://audiobook.mabenan.de/stream/' + track.get("File"), headers:  {"x-parse-session-token": user.sessionToken});
            player.play();
          }
        }
      }
    } else {
      Navigator.of(context).pushNamed("main/detail",
          arguments: DetailRouteArguments(album: album));
    }
  }
}
