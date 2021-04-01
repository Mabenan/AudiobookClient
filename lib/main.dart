import 'dart:io';

import 'package:audiobookclient/audioplayer.dart';
import 'package:audiobookclient/detail.dart';
import 'package:audiobookclient/library.dart';
import 'package:audiobookclient/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(MyApp());
}

Future<void> init() async {
  if (const bool.fromEnvironment("DEBUG_SERVER")) {
    Parse server = await Parse().initialize("ABCDEFG",
        kIsWeb ? "http://localhost:13371/" : "http://10.0.2.2:13371/",
        appName: "audiobook",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.audiobook",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: true,
        autoSendSessionId: true,
        liveQueryUrl:
            kIsWeb ? "http://localhost:13371/" : "http://10.0.2.2:13371/");
    var resp = await server.healthCheck();
    print(resp.success);
  } else {
    Parse server = await Parse().initialize(
        "VZVLcsw29sjuF0QHui7v", "http://node:13391/",
        appName: "audiobook",
        appVersion: "Version 1",
        appPackageName: "com.mabenan.audiobook",
        coreStore: await CoreStoreSharedPrefsImp.getInstance(),
        debug: true,
        autoSendSessionId: true,
        liveQueryUrl: "http://node:13391/");
    var resp = await server.healthCheck();
    if (!resp.success) {
      server = await Parse().initialize(
          "VZVLcsw29sjuF0QHui7v", "https://audiobook.mabenan.de/",
          appName: "audiobook",
          appVersion: "Version 1",
          appPackageName: "com.mabenan.audiobook",
          coreStore: await CoreStoreSharedPrefsImp.getInstance(),
          debug: true,
          autoSendSessionId: true,
          liveQueryUrl: "https://audiobook.mabenan.de/");
      resp = await server.healthCheck();
    }
    print(resp.success);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook',
      theme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.orange),
      home: LoginWidget(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  final String title = "Audiobook";

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Visib extends StatefulWidget {
  Visib({key, this.subRoute}) : super(key: key);
  final GlobalKey<NavigatorState> subRoute;
  @override
  State<StatefulWidget> createState() => _VisibState(subRoute: this.subRoute);
}

class _VisibState extends State<Visib> {
  bool visiblity = false;

  _VisibState({this.subRoute});
  final GlobalKey<NavigatorState> subRoute;

  refresh() {
    this.setState(() {
      visiblity = subRoute.currentContext != null &&
          Navigator.of(subRoute.currentContext).canPop();
    });
  }

  @override
  Widget build(BuildContext context) {
    visiblity = subRoute.currentContext != null &&
        Navigator.of(subRoute.currentContext).canPop();
    return Visibility(
      visible: this.visiblity,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: 56.0),
        child: BackButton(
          onPressed: () => {Navigator.of(subRoute.currentContext).maybePop()},
        ),
      ),
    );
  }
}

class NavObs extends NavigatorObserver {
  NavObs({this.toObs, this.context});
  final GlobalKey<_VisibState> toObs;
  final GlobalKey<NavigatorState> context;

  @override
  void didPop(Route route, Route previousRoute) {
    super.didPop(route, previousRoute);
    if (this.toObs.currentState != null) this.toObs.currentState.refresh();
  }

  @override
  void didPush(Route route, Route previousRoute) {
    super.didPush(route, previousRoute);
    if (this.toObs.currentState != null) this.toObs.currentState.refresh();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer player = new AudioPlayer();
  final GlobalKey<NavigatorState> subRoute = GlobalKey();
  final GlobalKey<_VisibState> visib = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () => Navigator.of(subRoute.currentContext).maybePop(),
      child: Scaffold(
        appBar: AppBar(
          leading: Visib(key: visib, subRoute: subRoute),
          title: Text(widget.title),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: ElevatedButton(
                onPressed: () => {
                  ParseUser.currentUser().then((user) => {
                        user.logout(),
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => LoginWidget()))
                      })
                },
                child: Icon(
                  Icons.logout,
                  size: 26.0,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Navigator(
                key: subRoute,
                initialRoute: "main/library",
                onGenerateRoute: routes,
                observers: [NavObs(toObs: visib, context: subRoute)],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AudioplayerWidget(),
      ),
    );
  }

  MaterialPageRoute routes(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case "main/library":
        builder = (BuildContext _) => LibraryWidget(player: this.player);
        break;
      case "main/detail":
        builder = (BuildContext _) => DetailWidget(
            album: (settings.arguments as DetailRouteArguments).album);
        break;
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
