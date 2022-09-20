import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:catbooks/globals.dart';
import 'package:catbooks_data/storage.dart';
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
        models.Account session =
            await Account(client).get();
        Navigator.pushReplacementNamed(this.context, "/main");
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
      models.Session session = await Account(client)
          .createEmailSession(email: _username.text, password: _password.text);
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
