import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:catbooks/globals.dart';
import 'package:catbooks/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginWindow extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginWindowState();
}

class LoginWindowState extends State<LoginWindow> {
  TextEditingController _username = TextEditingController();

  TextEditingController _password = TextEditingController();

  var _loginRunning = false;

  bool _calledAutologin = false;

  @override
  Widget build(BuildContext context) {
    if (!_calledAutologin) {
      _calledAutologin = true;
      autoLogin();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Catbooks"),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 30, right: 30, top: 50),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _username,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: ElevatedButton(
                  onPressed: _loginRunning ? null : () => {login()},
                  child: _loginRunning
                      ? CircularProgressIndicator()
                      : Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> autoLogin() async {
    try {
      setState(() {
        _loginRunning = true;
      });
      var box = await Hive.openBox("user");
      if (box.containsKey(STORAGE_SESSION_ID)) {
        String? sessionId = box.get(STORAGE_SESSION_ID);
        Session? session =
            await Account(client).getSession(sessionId: sessionId!);
        Navigator.pushReplacementNamed(this.context, "/main");
      }
    } catch (e) {
      setState(() {
        _loginRunning = false;
      });
    }
    setState(() {
      _loginRunning = false;
    });
  }

  Future<void> login() async {
    try {
      setState(() {
        _loginRunning = true;
      });
      Session? session = await Account(client)
          .createSession(email: _username.text, password: _password.text);
      var box = await Hive.openBox("user");
      box.put(STORAGE_SESSION_ID, session.$id);
      Navigator.pushReplacementNamed(this.context, "/main");
      setState(() {
        _loginRunning = false;
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Login Failed"),
          content: Text(
            e.toString(),
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      );
      setState(() {
        _loginRunning = false;
      });
    }
    setState(() {
      _loginRunning = false;
    });
  }
}
