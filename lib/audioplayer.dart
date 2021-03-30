import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Audioplayer extends StatefulWidget {
  Audioplayer({key, this.player}) : super(key: key);
  final AudioPlayer player;
  @override
  State<StatefulWidget> createState() => _AudioPlayerState(player: player);
}

class _AudioPlayerState extends State<Audioplayer> {
  _AudioPlayerState({this.player});
  final AudioPlayer player;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: FractionalOffset.center,
      color: Colors.white,
      child: StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, asyncSnapshot) {
            final bool isPlaying = asyncSnapshot.data.playing;
            return Text(isPlaying ? 'Pause' : 'Play');
          }),
    );
  }
}
