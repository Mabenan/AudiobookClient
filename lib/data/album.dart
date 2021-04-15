

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:path_provider/path_provider.dart';

import '../globals.dart' as globals;
class Album extends ParseObject {
  Album() : super("Album");
  Album.clone() : this();

  @override
  clone(Map<String, dynamic> map) => Album.clone()..fromJson(map);

  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

  String get cover => get<String>("Cover");

  set cover(String cover) => set<String>("Cover", cover);

  String get artist => get<String>("Artist");

  set artist(String artist) => set<String>("Artist", artist);

  Image _image50x50;

  Image get image50x50 {
    if(_image50x50 == null){
      var bytes = base64.decode(this.cover);
      _image50x50 = Image.memory(bytes, width: 50, height: 50,);
    }
    return _image50x50;
  }
  Image _image64x64;

  Image get image64x64{
    if(_image64x64 == null){
      var bytes = base64.decode(this.cover);
      _image64x64 = Image.memory(bytes, width: 64, height: 64,);
    }
    return _image64x64;
  }
  Image _image256x256;

  Image get image256x256{
    if(_image256x256 == null){
      var bytes = base64.decode(this.cover);
      _image256x256 = Image.memory(bytes, width: 256, height: 256,);
    }
    return _image256x256;
  }

  Future<Uri> get imageUri async{
    var dir = await getApplicationDocumentsDirectory();
    var path = dir.path + "/thumbs/" + name + ".thumb";
    File thumb = new File(path);
    if(!thumb.existsSync()){
      thumb.createSync(recursive: true);
      thumb.writeAsBytesSync(base64.decode(cover));
    }
    return thumb.uri;
  }
}

class Albums {
  static final Albums _singleton = Albums._internal();
  factory Albums() {
    return _singleton;
  }
  Albums._internal();

  bool _loaded = false;
  Map<String, Album> _albums = {};

  Future<Album> get(String objectId) async{
    if (!_albums.containsKey(objectId)) {
      Album track = await Album().fromPin(objectId);
      if (track == null) {
        ParseResponse resp = await (Album().getObject(objectId)
          ..catchError((err) {
            print(err);
          }));
        if (resp.success) {
          resp.result.pin();
          _albums.addAll({objectId: resp.result});
        }
      } else {
        _albums.addAll({objectId: track});
      }
    }
    return _albums[objectId];

  }

  refresh({bool fromServer = false}) async{
    _albums.clear();
    _loaded = false;
    await getAll(fromServer: fromServer);
  }

  Future<List<Album>> getAll({bool fromServer = false}) async {
    if (!_loaded) {
      if(fromServer && ! await globals.isOffline()){
        await ParseCoreData().getStore().remove("albums");
      }
      if(await ParseCoreData().getStore().containsKey("albums")) {
        List<String> albumKeys =
        await ParseCoreData().getStore().getStringList("albums");
        for (var albumKey in albumKeys) {
          Album album = await Album().fromPin(albumKey);
          if (!_albums.containsKey(albumKey) && album != null) {
            _albums.addAll({albumKey: album});
          }
        }
        _loaded = true;
      }
      if (! await globals.isOffline()) {
        ParseResponse resp = await (QueryBuilder<Album>(Album())..setLimit(100000000)).query();
        if (resp.success) {
          if (resp.results != null) {
            for (Album album in resp.results) {
              if (!_albums.containsKey(album.objectId)) {
                _albums.addAll({album.objectId: album});
              }
            }
            _loaded = true;
            cache();
          }
        }
      }
    }
    return List<Album>.from(_albums.values);
  }

  cache()  async{
    var albums = List<Album>.from(_albums.values);
    for (Album album in albums) {
      await album.pin();
    }
    await ParseCoreData().getStore().setStringList("albums", List<String>.from(_albums.keys));
  }
}
