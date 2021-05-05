import 'package:catbooks/data/album.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../globals.dart' as globals;

class Track extends ParseObject {
  Track() : super("Track");
  Track.clone() : this();

  @override
  clone(Map<String, dynamic> map) => Track.clone()..fromJson(map);

  String get name => get<String>("Name");

  set name(String name) => set<String>("Name", name);

  int get order => get<int>("Order");

  set order(int order) => set<int>("Order", order);

  String get file => get<String>("File");

  set file(String file) => set<String>("File", file);

  String get hash => get<String>("Hash");

  set hash(String hash) => set<String>("Hash", hash);

  int get size => get<int>("Size");

  set size(int size) => set<int>("Size", size);

  double get length {
   dynamic length = this["Length"];
   if(length is int){
     return length.toDouble();
   }else if(length is double){
     return length;
   }else{
     return 0;
   }
  }

  set length(double length) => set<double>("Length", length);
}

class Tracks {
  static final Tracks _singleton = Tracks._internal();
  factory Tracks() {
    return _singleton;
  }
  Tracks._internal();

  bool _loaded = false;
  Map<String, Track> _tracks = {};

  Future<Track> get(String objectId) async {
    if (!_tracks.containsKey(objectId)) {
      Track track = await Track().fromPin(objectId);
      if (track == null) {
        ParseResponse resp = await (Track().getObject(objectId)
          ..catchError((err) {
            print(err);
          }));
        if (resp.success) {
          resp.result.pin();
          _tracks.addAll({objectId: resp.result});
        }
      } else {
        _tracks.addAll({objectId: track});
      }
    }
    return _tracks[objectId];
  }

  refresh() async {
    _tracks.clear();
    _loaded = false;
  }

  Future<List<Track>> getAll() async {
    if (!_loaded) {
      if (await ParseCoreData().getStore().containsKey("tracks")) {
        List<String> trackKeys =
            await ParseCoreData().getStore().getStringList("tracks");
        for (var trackKey in trackKeys) {
          Track track = await Track().fromPin(trackKey);
          if (track != null && !_tracks.containsKey(track.objectId)) {
            track.pin();
            _tracks.addAll({trackKey: track});
          }
        }
        _loaded = true;
      }
      if (!await globals.isOffline()) {
        ParseResponse resp = await (QueryBuilder<Track>(Track())..setLimit(100000000)).query();
        if (resp.success) {
          if (resp.results != null) {
            for (Track track in resp.results) {
              if (!_tracks.containsKey(track.objectId)) {
                track.pin();
                _tracks.addAll({track.objectId: track});
              }
            }
            _loaded = true;
            cache();
          }
        }
      }
    }
    return List<Track>.from(_tracks.values);
  }

  cache() async {
    var tracks = List<Track>.from(_tracks.values);
    for (Track track in tracks) {
      await track.pin();
    }
    await ParseCoreData()
        .getStore()
        .setStringList("tracks", List<String>.from(_tracks.keys));
  }

  Future<List<Track>> getAlbum(Album album) async {
    List<Track> returnedTracks;
    List<String> trackIds = await ParseCoreData()
        .getStore()
        .getStringList(album.objectId + "tracks");
    if (trackIds != null
    && trackIds.length > 0) {
      returnedTracks = [];
      await Future.forEach(trackIds, (e) async {
        returnedTracks.add(await get(e));
      });
    }
    if (returnedTracks == null) {
      var tracks = await (QueryBuilder<Track>(Track())
            ..whereRelatedTo("Tracks", "Album", album.objectId)
            ..orderByAscending("Order"))
          .query();
      if (tracks.success) {
        if (tracks.results != null) {
          returnedTracks = List<Track>.from(tracks.results);
          await ParseCoreData().getStore().setStringList(
              album.objectId + "tracks",
              List<String>.from(returnedTracks.map((e) => e.objectId)));
        }
      }
    }
    if (returnedTracks == null) {returnedTracks = [];}

    return returnedTracks;
  }
}
