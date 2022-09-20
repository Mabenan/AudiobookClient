import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:catbooks/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../storage.dart';

class ShopWindow extends StatefulWidget {
  const ShopWindow({Key? key}) : super(key: key);

  @override
  _ShopWindowState createState() => _ShopWindowState();
}

class _ShopWindowState extends State<ShopWindow> {
  @override
  DocumentList? _data;

  Widget build(BuildContext context) {
    loadInitData();
    return _data == null
        ? CircularProgressIndicator()
        : RefreshIndicator(
            strokeWidth: 5,
            child: ListView.builder(
                padding: EdgeInsets.all(20.0),
                itemBuilder: (ctx, index) {
                  var doc = _data!.documents[index];
                  return buildAlbum(doc);
                },
                itemCount: _data!.sum),
            onRefresh: onRefresh,
          );
  }

  Future<void> onRefresh() async {
    Database(client)
        .listDocuments(collectionId: "619b333ab673a")
        .then((value) => setState(() {
              _data = value;
            }))
        .catchError((err) {
      print(err);
    });
  }

  Widget buildAlbum(Document doc) {
    return Card(
      child: ListTile(
        title: Text(doc.data["name"]),
        subtitle: Text(doc.data["author"]),
        leading: Image.memory(base64Decode(doc.data["cover"])),
        trailing: IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            String album = doc.$id;
            await getAlbum(album);
            libNavigator.pushNamed("/local");
          },
        ),
      ),
    );
  }

  void loadInitData() async {
    if (_data == null) {
      Database(client)
          .listDocuments(collectionId: "619b333ab673a")
          .then((value) => setState(() {
                _data = value;
              }))
          .catchError((err) {
        print(err);
      });
    }
  }
}
