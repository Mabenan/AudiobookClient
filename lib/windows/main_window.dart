import 'package:catbooks/globals.dart';
import 'package:catbooks/windows/local_library_window.dart';
import 'package:catbooks/windows/shop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
    if(_currentIndex != index) {
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
        return MaterialPageRoute(settings: settings,builder: (ctx) => Center(child: ShopWindow()));
      case "/local":
        return MaterialPageRoute(settings: settings,builder: (ctx) => Center(child:  LocalLibraryWindow()));
    }
  }
}
