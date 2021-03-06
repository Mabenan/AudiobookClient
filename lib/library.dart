import 'dart:async';
import 'package:catbooks/bookdownloader.dart';
import 'package:catbooks/detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data/album.dart';

class LibraryWidget extends StatefulWidget {
  LibraryWidget({key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _LibraryWidgetState();
}

class _LibraryWidgetState extends State<LibraryWidget> {
  bool _loadInProgress = false;

  _LibraryWidgetState();
  List<Album> _albums = [];
  @override
  Widget build(BuildContext context) {
    if(_albums.length == 0
    && !_loadInProgress){
      getData();
    }
    return Container(
      child: _albums.length != 0
          ? getList(context)
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget buildChilds(BuildContext context, Album album) {
    try {
      assert(album != null);
      BookMaster().getBook(album); //To Preload Book Data
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              child: album.image64x64,
            ),
            Expanded(
              child: GestureDetector(
                child: Column(
                  children: [
                    Text(
                      album.name,
                    ),
                    BookMaster.buildDownloadProgress(album),
                  ],
                ),
                onTap: () => Navigator.of(context).pushNamed("main/detail",
                    arguments: DetailRouteArguments(album: album)),
              ),
            ),
            StreamBuilder<bool>(
              stream: BookMaster().getBook(album).canDownload,
              initialData: false,
              builder: (context, snapshot) {
                return snapshot.data
                    ? GestureDetector(
                        child: Container(
                          width: 40,
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.file_download, size: 30),
                        ),
                        onTap: () =>
                            {BookMaster().getBook(album).startDownload()},
                      )
                    : Container();
              },
            ),
            StreamBuilder<bool>(
              stream: BookMaster().getBook(album).canPlay,
              initialData: false,
              builder: (context, snapshot) {
                return snapshot.data
                    ? GestureDetector(
                        child: Container(
                          width: 40,
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.play_circle_fill, size: 30),
                        ),
                        onTap: () => {BookMaster().getBook(album).play()},
                      )
                    : Container();
              },
            ),
          ],
        ),
      );
    } catch (ex) {
      return Card(
          child: Row(
        children: [
          Text(album != null ? album.name : "Album is null"),
          Spacer(),
          Text(ex.toString())
        ],
      ));
    }
  }

  getList(BuildContext context) {
    return RefreshIndicator(
        child: ListView.builder(
          itemCount: _albums.length,
          itemBuilder: (BuildContext context, int index) {
            return buildChilds(context, _albums.elementAt(index));
          },
        ),
        onRefresh: getData);
  }

  Future<void> getData() async {
    _loadInProgress = true;
    print("refresh");
    await Albums().refresh(fromServer: true);
    var alb = await Albums().getAll();
    setState(() {
      _albums = alb;
    });
    sortAlb(alb);
  }

  Future sortAlb(List<Album> alb) async {

    Map<String, bool> downloaded = {};
    for (var a in alb) {
      downloaded[a.name] = await BookMaster().getBook(a).canPlaySync();
    }
    alb.sort((a, b) {
      if (downloaded[a.name] && !downloaded[b.name]) {
        return -1;
      } else if (!downloaded[a.name] && downloaded[b.name]) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });
    setState(() {
      _albums = alb;
    });
    _loadInProgress = false;
  }
}
