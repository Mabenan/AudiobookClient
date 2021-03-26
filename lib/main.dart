import 'package:audiobookclient/library.dart';
import 'package:audiobookclient/login.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

void main() async {
  await init();
  runApp(MyApp());
}

Future<void> init() async {
  Parse server = await Parse().initialize("ABCDEFG", "http://localhost:13371/",
      appName: "audiobook",
      appVersion: "Version 1",
      appPackageName: "com.mabenan.audiobook",
      coreStore: await CoreStoreSharedPrefsImp.getInstance(),
      debug: true,
      autoSendSessionId: true,
      liveQueryUrl: "http://localhost:13371/");
  var resp = await server.healthCheck();
  print(resp.success);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook',
  theme: ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.orange
  ),
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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: Center(child: LibraryWidget()),
    );
  }
}
