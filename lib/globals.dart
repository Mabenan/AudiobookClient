import 'package:appwrite/appwrite.dart';
import 'package:audio_service/audio_service.dart';
import 'package:catbooks/app_ids.dart';
import 'package:catbooks/audio_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

CatbooksAudioHandler? _audioHandler;
Client? _client;
Logger?  _logger;
String _app = "";
bool _storage = false;

Future<void> init() async{
  _app = "de.mabenan.catbooks";
  await Hive.initFlutter(_app);
  _logger = Logger();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'de.mabenan.catbooks',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  _client = Client();
  _client!
      .setEndpoint("https://apps.mabenan.de/v1")
      .setProject(PROJECT_ID)
      .setSelfSigned(status: false);
}


Client get client => _client!;
Logger get logger => _logger!;

Future<String> getApplicationDir() async{
  var appDir = await getApplicationDocumentsDirectory();
  return path.join(appDir.path, _app);
}
CatbooksAudioHandler get audioHandler => _audioHandler!;

final _navigatorKey = GlobalKey<NavigatorState>();
final _navigatorKey2 = GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
NavigatorState get libNavigator => _navigatorKey.currentState!;
GlobalKey<NavigatorState> get globalNavigatorKey => _navigatorKey2;
NavigatorState get globalNavigator => _navigatorKey2.currentState!;