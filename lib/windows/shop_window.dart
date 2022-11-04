import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:catbooks/app_ids.dart';
import 'package:catbooks/data/album.dart';
import 'package:catbooks/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io' as io;
import 'package:catbooks/storage.dart';

class ShopWindow extends StatefulWidget {
  const ShopWindow({Key? key}) : super(key: key);

  @override
  _ShopWindowState createState() => _ShopWindowState();
}

class _ShopWindowState extends State<ShopWindow> {
  @override
  List<Album?>? _data;

  Widget build(BuildContext context) {
    loadInitData();
    return _data == null
        ? CircularProgressIndicator()
        : RefreshIndicator(
            strokeWidth: 5,
            child: ListView.builder(
                padding: EdgeInsets.all(20.0),
                itemBuilder: (ctx, index) {
                  var doc = _data![index];
                  return buildAlbum(doc!);
                },
                itemCount: _data!.length),
            onRefresh: onRefresh,
          );
  }

  Future<void> onRefresh() async {
    DocumentList albs = await Databases(client)
      .listDocuments(databaseId: DATABASE, collectionId: "619b333ab673a");
    List<Document> albDocs = List.empty(growable: true);
    albDocs.addAll(albs.documents);
    while(albDocs.length < albs.total && albDocs.isNotEmpty){
      albs = await Databases(client)
          .listDocuments(databaseId: DATABASE, collectionId: "619b333ab673a", queries: [Query.cursorAfter(albDocs.last.$id)]);
      albDocs.addAll(albs.documents);
    }
    _data = await Future.wait(albDocs.map((alb) async{
      return await getAlbum(alb.$id, false);
    }));
    setState(() {

    });
  }

  Widget buildAlbum(Album doc) {
    return Card(
      child: ListTile(
        title: Text(doc.name),
        subtitle: Text(doc.author),
        leading: FutureBuilder<Uri>(
          future: doc.getArtUri(),
          builder: (context, snapData) => snapData.hasData ? Image.file(io.File.fromUri(snapData.data!)) : Container(width: 48, height: 48,),
        ),
        trailing: IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            String album = doc.id;
            await addToLocalLibrary(album);
            libNavigator.pushNamed("/local");
          },
        ),
      ),
    );
  }

  void loadInitData() async {
    if (_data == null) {
      onRefresh();
    }
  }
}
