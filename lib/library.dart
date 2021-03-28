import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class LibraryWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LibraryWidgetState();
}

class _LibraryWidgetState extends State<LibraryWidget> {
  @override
  Widget build(BuildContext context) {
    QueryBuilder query = QueryBuilder<ParseObject>(ParseObject("Album"))
      ..orderByAscending('Name');
    return Column(
      children: [
        Text("Test"),
        Expanded(
          child: ParseLiveListWidget(
            query: query,
            childBuilder: (BuildContext context,
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
      if (snapshot.loadedData.get("Cover") != null) {
        Uint8List bytes = base64.decode(
            snapshot.loadedData.get("Cover").toString().split(',').last);
        return Card(
          child: Row(children: [
            Image.memory(
              bytes,
              width: 64,
              height: 64,
            ),
            Text(
              snapshot.loadedData.get("Name"),
            )
          ]),
        );
      }
      return ListTile(
        title: Text(
          snapshot.loadedData.get("Name"),
        ),
      );
    } else {
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }
}
