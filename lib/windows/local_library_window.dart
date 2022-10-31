import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:catbooks/data/album.dart';
import 'package:catbooks/service_provider/audio_service_provider.dart';
import 'package:catbooks/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'dart:io' as io;

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
          .asyncMap((item) async => await getAlbum(item, true))
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
          leading: FutureBuilder<Uri>(
            future: doc.getArtUri(),
            builder: (context, snapData) => snapData.hasData
                ? Image.file(io.File.fromUri(snapData.data!))
                : Container(width: 48, height: 48),
          ),
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
                    onPressed: () async{
                      await AudioServiceProvider().loadAlbum(doc);
                      AudioServiceProvider().player.play();
                      setState((){

                      });
                    },
                  );
                case 2:
                  return StreamBuilder<int>(
                      stream: doc.downloadProgress,
                      initialData: 0,
                      builder: (ctx, result) {
                        if (result.data == 0) {
                          return IconButton(
                            icon: Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              doc.download();
                            },
                          );
                        } else {
                          return Container(
                            width: 300,
                            child: Row(
                              children: [
                                Text(
                                    "${(result.data! / 1000 / 1000).toStringAsFixed(2)} MB / ${(doc.downloadMass / 1000 / 1000).toStringAsFixed(2)} MB"),
                                Spacer(),
                                CircularProgressIndicator(
                                  value: (result.data! / doc.downloadMass),
                                ),
                              ],
                            ),
                          );
                        }
                      });
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
        .asyncMap((item) async => await getAlbum(item, true))
        .toList();
    _data!.remove(null);
    setState(() {});
  }

  openAlbumDetail(Album doc) {
    globalNavigator.pushNamed("/albumDetail", arguments: doc);
  }
}
