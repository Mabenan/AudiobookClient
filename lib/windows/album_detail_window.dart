import 'dart:convert';

import 'package:catbooks/data/album.dart';
import 'package:catbooks/storage.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import '../globals.dart';

class AlbumDetailWindow extends StatefulWidget {
  const AlbumDetailWindow({Key? key}) : super(key: key);

  @override
  _AlbumDetailWindowState createState() => _AlbumDetailWindowState();
}

class _AlbumDetailWindowState extends State<AlbumDetailWindow> {
  @override
  Widget build(BuildContext context) {
    final Album album = ModalRoute.of(context)!.settings.arguments as Album;
    final theme = Theme.of(context);
    final descriptionStyle = theme.textTheme.subtitle1;
    return Scaffold(
      appBar: AppBar(
        title: Text("Catbooks"),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  // This ensures that the Card's children are clipped correctly.
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 128,
                          height: 128,
                          child: FutureBuilder<Uri>(
                            future: album.getArtUri(),
                            builder: (context, snapData) => snapData.hasData
                                ? Image.file(io.File.fromUri(snapData.data!))
                                : Text("Loading ..."),
                          ),
                        ),
                      ),
                      // Description and share/explore buttons.
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // This array contains the three line description on each card
                              // demo.
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  album.name,
                                ),
                              ),
                              Text(
                                album.author,
                                style: descriptionStyle!.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: StreamBuilder<int>(
                          stream: album.isDownloaded,
                          initialData: 0,
                          builder: (ctx, downloaded) => ButtonBar(
                            alignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: downloaded.data == 1
                                      ? () {
                                          album.deleteDownload();
                                        }
                                      : null,
                                  child: Text("Delete Downloads"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: downloaded.data == 2
                                      ? () async {
                                          await removeAlbumFromLocalStorage(
                                              album.id);
                                          globalNavigator.pop();
                                        }
                                      : null,
                                  child: Text("Remove from Library"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await album.refreshTracks();
                                    album.checkDownload();
                                  },
                                  child: Text("Refresh Tracks"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
