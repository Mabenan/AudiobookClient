import 'package:audio_service/audio_service.dart';
import 'package:audiobookclient/background.dart';
import 'package:audiobookclient/data/listening.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'data/album.dart';
import 'data/track.dart';
final navigatorKey = GlobalKey<NavigatorState>();
bool _offline = false;
bool forcedOffline = true;
bool get offline => _offline;
set offline(value) {
  if ((_offline == true && value != _offline) || forcedOffline == true) {
    Future.microtask(() async {
      if ((await (Parse().healthCheck()
            ..catchError((err) {
              forcedOffline = true;
            })))
          .success) {
        forcedOffline = false;
      }
      if((await ParseUser.currentUser()) != null) {
        await Albums().refresh();
        await Tracks().refresh();
        Tracks().getAll();
      }
    });
  }
  if (value != null) {
    ParseCoreData().getStore().setBool("offline", value);
    _offline = value;
    if(AudioService.running) {
      AudioPlayerFrontendService().offline(value);
    }
  } else {
    ParseCoreData().getStore().setBool("offline", false);
    _offline = false;
  }
}

Future<bool> isOffline() async {
  if (offline) {
    return true;
  } else {
    if (forcedOffline) {
      return true;
    } else {
      return false;
    }
  }
}

initParse({bool back = false}) async {
  Map<String, ParseObjectConstructor> subclassMap = {
    "Album": () => Album(),
    "Track": () => Track(),
  };
  if (back) subclassMap.addAll({"Listening": () => Listening()}); //This is to ensure that only in Backend the Listenings are loaded
  Future<ParseResponse> resp;
  if (const bool.fromEnvironment("DEBUG_SERVER")) {
    Parse server = await Parse().initialize("ABCDEFG",
        kIsWeb ? "http://localhost:13371/" : "http://10.0.2.2:13371/",
        appName: "audiobook",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.audiobook",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: true,
        autoSendSessionId: true,
        registeredSubClassMap: subclassMap,
        liveQueryUrl:
            kIsWeb ? "http://localhost:13371/" : "http://10.0.2.2:13371/");
    resp = server.healthCheck();
  } else {
    Parse server = await Parse().initialize(
        "VZVLcsw29sjuF0QHui7v", "http://node:13391/",
        appName: "audiobook",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.audiobook",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: false,
        autoSendSessionId: true,
        registeredSubClassMap: subclassMap,
        liveQueryUrl: "http://node:13391/");
    resp = server.healthCheck();
    var resp2 = await resp;
    if (!resp2.success) {
      server = await Parse().initialize(
          "VZVLcsw29sjuF0QHui7v", "https://audiobook.mabenan.de/",
          appName: "audiobook",
          appVersion: "Version 1",
          appPackageName: "com.mabenan.audiobook",
          coreStore: await CoreStoreSharedPrefsImp.getInstance(),
          debug: false,
          autoSendSessionId: true,
          registeredSubClassMap: subclassMap,
          liveQueryUrl: "https://audiobook.mabenan.de/");
      resp = server.healthCheck();
    }
  }
  resp.then((value) {
    if (value.success) forcedOffline = false;
    if(!back){
      Albums().getAll();
      Tracks().getAll();
    }
  });
  resp.catchError((err) {
    forcedOffline = true;
    showDialog(
        context: navigatorKey.currentContext,
        builder: (context) => AlertDialog(
        title: Text(err)

        )
    );
  });
  offline = await ParseCoreData().getStore().getBool("offline");
}
