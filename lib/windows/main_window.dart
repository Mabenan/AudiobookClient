import 'package:catbooks/data/album.dart';
import 'package:catbooks/globals.dart';
import 'package:catbooks/service_provider/audio_service_provider.dart';
import 'package:catbooks/windows/local_library_window.dart';
import 'package:catbooks/windows/shop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io' as io;

import 'package:marquee/marquee.dart';

class MainWindow extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainWindowState();
}

class NavHelper extends NavigatorObserver {
  final MainWindowState mainWindowState;
  NavHelper(this.mainWindowState);

  @override
  void didPop(Route route, Route? previousRoute) {
    switch (route.settings.name) {
      case "/":
        mainWindowState.upateIndex(0);
        break;
      case "/local":
        mainWindowState.upateIndex(1);
        break;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    switch (route.settings.name) {
      case "/":
        mainWindowState.upateIndex(0);
        break;
      case "/local":
        mainWindowState.upateIndex(1);
        break;
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    switch (route.settings.name) {
      case "/":
        mainWindowState.upateIndex(0);
        break;
      case "/local":
        mainWindowState.upateIndex(1);
        break;
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    switch (newRoute!.settings.name) {
      case "/":
        mainWindowState.upateIndex(0);
        break;
      case "/local":
        mainWindowState.upateIndex(1);
        break;
    }
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    switch (route.settings.name) {
      case "/":
        mainWindowState.upateIndex(0);
        break;
      case "/local":
        mainWindowState.upateIndex(1);
        break;
    }
  }
}

class MainWindowState extends State<MainWindow> {
  int _currentIndex = 0;
  upateIndex(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var scaffold = Scaffold(
      appBar: AppBar(
        title: Text("Catbooks"),
      ),
      body: Navigator(
        key: navigatorKey,
        initialRoute: "/",
        observers: [new NavHelper(this)],
        onGenerateRoute: _onGenerateRoute,
      ),
      bottomSheet: StreamBuilder<Album?>(
          stream: AudioServiceProvider().currentAlbum,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Container(
                height: 64,
                width: double.infinity,
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    FutureBuilder<Uri>(
                      future: snapshot.data!.getArtUri(),
                      builder: (context, snapData) => snapData.hasData
                          ? Image.file(
                              io.File.fromUri(snapData.data!),
                              width: 48,
                              height: 48,
                            )
                          : Container(width: 48, height: 48),
                    ),
                    Flexible(
                      child: Column(children: [
                        Marquee(
                          text: snapshot.data!.name,
                          blankSpace: 20.0,
                          velocity: 30.0,
                          pauseAfterRound: Duration(seconds: 1),
                        ),
                        StreamBuilder<Duration?>(
                          stream: AudioServiceProvider().durationLeft,
                          builder: (context, durationData){
                            if(durationData.hasData) {
                              return Text(getFormatDuration(durationData.data!));
                            }else{
                              return Text("");
                            }
                          },
                        )
                      ]),
                    ),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        Icons.replay_30,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        AudioServiceProvider().replay(Duration(seconds: 30));
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: AudioServiceProvider().player.playingStream,
                      builder: (context, playingData) =>
                          playingData.hasData && playingData.data!
                              ? IconButton(
                                  iconSize: 48,
                                  icon: Icon(
                                    Icons.pause_circle,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    AudioServiceProvider().player.pause();
                                  },
                                )
                              : IconButton(
                                  iconSize: 48,
                                  icon: Icon(
                                    Icons.play_circle,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    AudioServiceProvider().player.pause();
                                  },
                                ),
                    )
                  ],
                ),
              );
            } else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          }),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shop_2_outlined),
            label: "Shop",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            label: "Local Library",
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
            libNavigator.pushNamed(() {
              switch (idx) {
                case 0:
                  return "/";
                case 1:
                  return "/local";
                default:
                  return "/";
              }
            }());
          });
        },
      ),
    );
    return scaffold;
  }

  Route? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case "/":
        return MaterialPageRoute(
            settings: settings, builder: (ctx) => Center(child: ShopWindow()));
      case "/local":
        return MaterialPageRoute(
            settings: settings,
            builder: (ctx) => Center(child: LocalLibraryWindow()));
    }
  }

  String getFormatDuration(Duration duration) {
    String durationFormat = "";
    if(duration.inHours > 0){
      durationFormat += "${duration.inHours}Std";
    }
    if((duration.inMinutes - duration.inHours * 60) > 0){
      durationFormat += "${duration.inMinutes - duration.inHours * 60}min";
    }
    if((duration.inSeconds - duration.inMinutes * 60) > 0){
      durationFormat += "${duration.inSeconds - duration.inMinutes * 60}sec";
    }
    return durationFormat;
  }
}
