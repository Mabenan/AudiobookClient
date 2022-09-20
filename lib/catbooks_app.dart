import 'package:catbooks/windows/album_detail_window.dart';
import 'package:catbooks/windows/login_window.dart';
import 'package:catbooks/windows/main_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'globals.dart';

class CatbooksApp extends MaterialApp {
  CatbooksApp()
      : super(
          navigatorKey: globalNavigatorKey,
          routes: <String, WidgetBuilder>{
            "/main": (ctx) => MainWindow(),
            "/login": (ctx) => LoginWindow(),
            "/albumDetail": (ctx) => AlbumDetailWindow(),
          },
          initialRoute: "/login",
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(
          ).copyWith(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                primary: Colors.orange,
                onPrimary: Colors.black,
                textStyle: TextStyle(
                    fontWeight: FontWeight.bold
                )
              )
            )
          ),
        );
}
