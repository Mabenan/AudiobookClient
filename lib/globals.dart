import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:audio_service/audio_service.dart';
import 'package:catbooks/app_ids.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

FlutterBackgroundService? _service;
Client? _client;
Logger?  _logger;
String _app = "";
bool _storage = false;

Future<void> init() async{
  WidgetsFlutterBinding.ensureInitialized();
  _app = "de.mabenan.catbooks";
  await Hive.initFlutter(_app);
  _logger = Logger();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'de.mabenan.catbooks',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await initSleepTimer();
  _client = Client();
  _client!
      .setEndpoint("https://apps.mabenan.de/v1")
      .setProject(PROJECT_ID)
      .setSelfSigned(status: false);
}

initSleepTimer()  async{
  WidgetsFlutterBinding.ensureInitialized();
  _service = FlutterBackgroundService();

  _service!.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: false,

      notificationChannelId: 'de.mabenan.catbooks.timer',
      initialNotificationTitle: 'Catbooks',
      initialNotificationContent: 'Sleep Timer',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,
    ),);

  _service!.startService();
}

Client get client => _client!;
Logger get logger => _logger!;
FlutterBackgroundService get service => _service!;

Future<String> getApplicationDir() async{
  var appDir = await getApplicationDocumentsDirectory();
  return path.join(appDir.path, _app);
}

final _navigatorKey = GlobalKey<NavigatorState>();
final _navigatorKey2 = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
NavigatorState get libNavigator => _navigatorKey.currentState!;
GlobalKey<NavigatorState> get globalNavigatorKey => _navigatorKey2;
NavigatorState get globalNavigator => _navigatorKey2.currentState!;

Timer? _actualTimer;
@pragma('vm:entry-point')
onStart(ServiceInstance lservice) async {
  print("service started");
  lservice.on("setTimer").listen((event) {
    print("timer Set");
    if(_actualTimer != null){
      _actualTimer!.cancel();
    }
    _actualTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      print("time:${timer.tick}");
      if(timer.tick < (event!["duration"] as int)){
        lservice.invoke("timerTick", { "tick": timer.tick});
      }else{
        lservice.invoke("sleepTimerReached");
        timer.cancel();
      }
    });
  });

}
