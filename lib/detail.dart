import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class DetailRouteArguments{
  DetailRouteArguments({this.album});
  final ParseObject album;
}

class DetailWidget extends StatefulWidget {
  DetailWidget({Key key, this.album}) : super(key: key);
  final ParseObject album;
  @override
  State<StatefulWidget> createState() => _DetailWidgetState(album : this.album);
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
    return Column(
      children: [image],
    );
  }
}
