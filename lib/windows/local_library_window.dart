import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:catbooks_data/data/album.dart';
import 'package:catbooks/service_provider/audio_service_provider.dart';
import 'package:catbooks_data/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../globals.dart';

class LocalLibraryWindow extends StatefulWidget {
  const LocalLibraryWindow({Key? key}) : super(key: key);

  @override
  _LocalLibraryWindowState createState() => _LocalLibraryWindowState();
}

class _LocalLibraryWindowState extends State<LocalLibraryWindow> {
  List<Album?>? _data;

  @override
  Widget build(BuildContext context) {
    loadInitData();
    return _data == null
        ? CircularProgressIndicator()
        : RefreshIndicator(
            strokeWidth: 5,
            child: ListView.builder(
                padding: EdgeInsets.all(20.0),
                itemBuilder: (ctx, index) {
                  var doc = _data![index];
                  return buildAlbum(doc);
                },
                itemCount: _data!.length),
            onRefresh: onRefresh,
          );
  }

  Future<void> loadInitData() async {
    if (_data == null) {
      List<String> albums = await getLocalLibrary();
      _data = await Stream.fromIterable(albums)
          .asyncMap((item) async => await getAlbum(item))
          .toList();
      _data!.remove(null);

      var box = await Hive.openBox(STORAGE_LOCAL_ALBUM);
      box.watch().listen((event) {
        onRefresh();
      });
      setState(() {});
    }
  }

  Widget buildAlbum(Album? doc) {
    return Card(
      child: GestureDetector(
        onTap: () => openAlbumDetail(doc!),
        child: ListTile(
          title: Text(doc!.name),
          subtitle: Text(doc.author),
          leading: Image.memory(base64Decode(doc.cover)),
          trailing: StreamBuilder<int>(
            stream: doc.isDownloaded,
            initialData: 0,
            builder: (ctx, result) {
              switch (result.data) {
                case 1:
                  return IconButton(
                    icon: Icon(
                      Icons.play_circle,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      AudioServiceProvider().startAlbum(doc);
                    },
                  );
                case 2:
                  return IconButton(
                    icon: Icon(
                      Icons.download,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      doc.download();
                    },
                  );
                default:
                  return Container(
                      width: 40, child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> onRefresh() async {

    List<String> albums = await getLocalLibrary();
    _data = await Stream.fromIterable(albums)
        .asyncMap((item) async => await getAlbum(item))
        .toList();
    _data!.remove(null);
    setState(() {

    });
  }

  openAlbumDetail(Album doc) {

    globalNavigator.pushNamed("/albumDetail", arguments: doc);

  }
}
