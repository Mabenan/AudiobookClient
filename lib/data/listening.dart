import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:uuid/uuid.dart';

import '../globals.dart' as globals;
import 'album.dart';

class LocalListening {
  String _objectId;
  String _album;
  String _user;
  String _track;
  int _progress;
  int _updated;
  int _serverSynced;

  String get objectId => _objectId;

  set objectId(String objectIdVal) {
    _objectId = objectIdVal;
    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
    }
  }

  String get album => _album;

  set album(String albumVal) {
    _album = albumVal;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
      updated = DateTime.now();
    }
  }

  String get user => _user;

  set user(String userVal) {
    _user = userVal;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
      updated = DateTime.now();
    }
  }

  String get track => _track;

  set track(String trackVal) {
    _track = trackVal;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
      updated = DateTime.now();
    }
  }

  int get progress => _progress;

  set progress(int progressVal) {
    _progress = progressVal;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
      updated = DateTime.now();
    }
  }

  DateTime get updated => DateTime.fromMicrosecondsSinceEpoch(_updated ?? 0);

  set updated(DateTime updatedVal) {
    _updated = updatedVal.microsecondsSinceEpoch;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
    }
  }

  DateTime get serverSynced =>
      DateTime.fromMicrosecondsSinceEpoch(_serverSynced ?? 0);

  set serverSynced(DateTime serverSyncedVal) {
    _serverSynced = serverSyncedVal.microsecondsSinceEpoch;

    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
    }
  }

  LocalListening(
      {progress, objectId, album, serverSynced, track, updated, user})
      : _objectId = objectId,
        _user = user,
        _updated = updated,
        _track = track,
        _album = album,
        _serverSynced = serverSynced,
        _progress = progress {
    if (_objectId != null) {
      ParseCoreData().getStore().setString(_objectId, jsonEncode(toJson()));
    }
  }

  LocalListening.fromJson(Map<String, dynamic> json)
      : _objectId = json["objectId"],
        _album = json["album"],
        _user = json["user"],
        _track = json["track"],
        _progress = json["progress"],
        _updated = json["updated"],
        _serverSynced = json["serverSynced"];

  Map<String, dynamic> toJson() => {
        "objectId": _objectId,
        "album": _album,
        "user": _user,
        "track": _track,
        "progress": _progress,
        "updated": _updated,
        "serverSynced": _serverSynced
      };
}

class Listening extends ParseObject {
  Listening() : super("Listening");

  Listening.clone() : this();

  @override
  clone(Map<String, dynamic> map) => Listening.clone()..fromJson(map);

  String get user => get<String>("User");

  set user(String user) {
    set<String>("User", user);
    this.set("updatedAt", DateTime.now());
  }

  String get track => get<String>("Track");

  set track(String listening) {
    set<String>("Track", listening);
    this.set("updatedAt", DateTime.now());
  }

  String get album => get<String>("Album");

  set album(String album) {
    set<String>("Album", album);
    this.set("updatedAt", DateTime.now());
  }

  int get progress => get<int>("Progress");

  set progress(int progress) {
    set<int>("Progress", progress);
    this.set("updatedAt", DateTime.now());
  }

  DateTime get serverSynced => get<DateTime>("ServerSynced");

  set serverSynced(DateTime serverSynced) =>
      set<DateTime>("ServerSynced", serverSynced);
}

class Listenings {
  static final Listenings _singleton = Listenings._internal();

  Future<Null> initProc;

  StreamSubscription<Future<Null>> syncProc;

  factory Listenings() {
    return _singleton;
  }
  Listenings._internal() {
    this.initProc = _init();
  }

  stop() async {
    await this.syncProc.cancel();
    this.syncProc = null;
    _listenings.clear();
    _loaded = false;
  }

  start() async {
    await _init();
  }

  Future<Null> _init() async {
    await _load();

    if (this.syncProc == null && globals.isBack) {
      this.syncProc = Stream.periodic(Duration(seconds: 10), (comp) async {
        await _sync();
      }).listen((comp) {
        return;
      });
    }
  }

  Future _sync() async {
    if (!await globals.isOffline()) {
      List<LocalListening> listings =
          List<LocalListening>.from(_listenings.values);
      List<String> removeFromLocal = [];
      for (var listing in listings) {
        if (!listing.objectId.startsWith("local")) {
          //was already Synced at some point
          ParseResponse resp =
              await Listening().getObject(listing.objectId);
          if (resp.success) {
            Listening serverVersion = resp.result as Listening;
            if (listing.serverSynced.isBefore(serverVersion.serverSynced)) {
              // someone else sended progress information
              listing.track = serverVersion.track;
              listing.progress = serverVersion.progress;
              listing.updated = DateTime.now();
              listing.serverSynced = serverVersion.serverSynced;
            } else if (listing.serverSynced.isBefore(listing.updated)) {
              serverVersion.track = listing.track;
              serverVersion.progress = listing.progress;
              serverVersion.serverSynced =
                  listing.serverSynced = DateTime.now();
              await serverVersion.save();
            }
          } else {
            removeFromLocal.add(listing.objectId);
          }
        } else {
          Listening serverVersion = Listening();
          serverVersion.album = listing.album;
          serverVersion.user = listing.user;
          serverVersion.track = listing.track;
          serverVersion.progress = listing.progress;
          var serverSynced = serverVersion.serverSynced = DateTime.now();
          ParseResponse resp = await serverVersion.save();
          if (resp.success) {
            listing.objectId = resp.result.objectId;
            listing.serverSynced = serverSynced;
          }
        }
      }
      for (var idToRemove in removeFromLocal) {
        _listenings.remove(idToRemove);
      }
      await _cache();
    }
  }

  bool _loaded = false;
  Map<String, LocalListening> _listenings = {};

  Future<LocalListening> getLast() async {
    await _load();
    if (_listenings.length > 0) {
      return (List<LocalListening>.from(_listenings.values)
            ..sort((a, b) => b.updated.compareTo(a.updated)))
          .first;
    } else {
      return null;
    }
  }

  Future<LocalListening> getAlbum(Album album) async {
    await _load();
    if (_listenings.length > 0) {
      return _listenings.values.firstWhere(
          (element) => element.album == album.objectId,
          orElse: () => null);
    } else {
      return null;
    }
  }

  refresh() async {
    _listenings.clear();
    _loaded = false;
    await _load();
  }

  _load() async {
    if (!_loaded) {
      _loaded = true;
      List<String> keys =
          await ParseCoreData().getStore().getStringList("listenings");
      if (keys != null) {
        for (var key in keys) {
          LocalListening listening = LocalListening.fromJson(
              jsonDecode(await ParseCoreData().getStore().getString(key)));
          if (listening != null) {
            if (!_listenings.containsKey(listening.objectId))
              _listenings.addAll({listening.objectId: listening});
          }
        }
      }
      var query = await (QueryBuilder<Listening>(Listening())
            ..whereEqualTo("User", (await ParseUser.currentUser()).objectId))
          .query();
      if (query.success && query.results != null) {
        for (Listening serverListing in query.results) {
          if (!_listenings.containsKey(serverListing.objectId)) {
            LocalListening localListing = LocalListening(
                objectId: serverListing.objectId,
                user: serverListing.user,
                album: serverListing.album,
                track: serverListing.track,
                progress: serverListing.progress,
                serverSynced: serverListing.serverSynced.microsecondsSinceEpoch,
                updated: serverListing.updatedAt.microsecondsSinceEpoch);
            _listenings.addAll({localListing.objectId: localListing});
          }
        }
      }
      await _cache();
    } else {
      if (initProc != null) {
        await initProc;
        initProc = null;
      }
    }
  }

  _cache() async {
    await ParseCoreData()
        .getStore()
        .setStringList("listenings", List<String>.from(_listenings.keys));
  }

  add(LocalListening listening) async {
    if (listening.objectId == null) {
      listening.objectId = "local_" + Uuid().v1();
    }
    if (!_listenings.containsKey(listening.objectId))
      _listenings.addAll({listening.objectId: listening});
  }

  void set(LocalListening listening) {
    if (_listenings.containsKey(listening.objectId)) {
      _listenings[listening.objectId] = listening;
    }
  }
}
