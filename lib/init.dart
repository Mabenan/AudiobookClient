import 'package:flutter/material.dart';

import 'data/album.dart';
import 'data/track.dart';

class InitWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InitWidgetState();
}


class _InitWidgetState extends State<InitWidget> {
  int albumSum = 0;
  int albumLoaded = 0;

  _InitWidgetState() : super(){
    Future.microtask(() async {
      List<Album> albums = await Albums().getAll();
      setState(() {
        albumSum = albums.length;
      });
      for (var album in albums) {
        await Tracks().getAlbum(album);
        setState(() {
          albumLoaded++;
        });
      }
      Navigator.pushReplacementNamed(context, "main");
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("APP Initialisation"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 130,
            ),
            Text("Loaded ${albumLoaded} from ${albumSum}"),
            LinearProgressIndicator(
              value: albumLoaded / albumSum,
            ),

          ],
        ),
      ),
    );
  }
}
