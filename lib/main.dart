import 'package:audio_service/audio_service.dart';
import 'package:audiobookclient/detail.dart';
import 'package:audiobookclient/library.dart';
import 'package:audiobookclient/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'audioplayer.dart';
import 'background.dart';
import 'globals.dart' as globals;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(MyApp());
}

Future<void> init() async {
  await globals.initParse();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook',
      theme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.orange),
      home: AudioServiceWidget(child: PageWrapper()),
      navigatorKey: globals.navigatorKey,
    );
  }
}

class PageWrapper extends StatefulWidget {
  PageWrapper({Key key}) : super(key: key);
  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: "login",
      onGenerateRoute: routes,
    );
  }

  MaterialPageRoute routes(RouteSettings settings) {
    WidgetBuilder builder;
    switch (settings.name) {
      case "main":
        builder = (BuildContext _) => MyHomePage();
        break;
      case "login":
        builder = (BuildContext _) => LoginWidget();
        break;
    }
    return MaterialPageRoute(builder: builder, settings: settings);
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
  final GlobalKey<NavigatorState> subRoute = GlobalKey();
  final GlobalKey<_VisibState> visib = GlobalKey();
  bool offline = false;
  @override
  Widget build(BuildContext context) {
    globals.isOffline().then((value) => {
          setState(() {
            offline = value;
          })
        });
    return new WillPopScope(
      onWillPop: () => Navigator.of(subRoute.currentContext).maybePop(),
      child: Scaffold(
        appBar: AppBar(
          leading: Visib(key: visib, subRoute: subRoute),
          title: Text(widget.title),
          actions: [
            Row(children: [
              Text(offline ? "Offline" : "Online"),
              Switch(
                value: offline,
                onChanged: (value) {
                  setState(() {
                    globals.offline = value;
                    globals.isOffline().then((value) {
                      setState(() {
                        offline = value;
                      });
                      if (value) {
                        showDialog(
                            context: context,
                            builder: (cntx) =>
                                AlertDialog(title: Text("is Offline: " + globals.forcedOffline.toString())));
                      }
                    });
                  });
                },
              ),
            ]),
            IconButton(
              onPressed: () => {
                ParseUser.currentUser().then((user) => {
                      user.logout(),
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => LoginWidget()))
                    })
              },
              icon: Icon(
                Icons.logout,
                size: 26.0,
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
        builder = (BuildContext _) => LibraryWidget();
        break;
      case "main/detail":
        builder = (BuildContext _) => DetailWidget(
            album: (settings.arguments as DetailRouteArguments).album);
        break;
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
