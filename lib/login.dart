import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'globals.dart' as globals;

class LoginWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();

  void login() async {
    ParseUser user = ParseUser.createUser(username.text, password.text);

    ParseResponse resp = await user.login();
    if (resp.success) {
      Navigator.pushReplacementNamed(context, "init");
    }
  }

  void checkLogin() async {
    ParseUser user = await ParseUser.currentUser();
    if (user != null) {
      if (!await globals.isOffline()) {
        globals.forcedOffline = true;
        Navigator.pushReplacementNamed(context, "init");
        ParseResponse resp = await user.getUpdatedUser();
        if (resp.success) {
          globals.forcedOffline = false;
        }else{
          globals.forcedOffline = true;
        }
      }else{
        Navigator.pushReplacementNamed(context, "init");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    checkLogin();
    return Scaffold(
      appBar: AppBar(
        title: Text("Login Page"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 130,
            ),
            Padding(
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'User',
                    hintText: 'Enter valid user'),
                controller: username,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Enter secure password'),
                controller: password,
              ),
            ),
            TextButton(
              onPressed: () {
                //TODO FORGOT PASSWORD SCREEN GOES HERE
              },
              child: Text(
                'Forgot Password',
                style: TextStyle(color: Colors.blue, fontSize: 15),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  this.login();
                },
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            SizedBox(
              height: 130,
            ),
          ],
        ),
      ),
    );
  }
}
