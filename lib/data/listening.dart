class Listening {
  int track;
  Duration duration;


  Listening({required this.track, required this.duration});


  static Listening fromJson(Map<String, dynamic> json){
    return Listening(
      track: json["track"],
      duration: Duration(seconds: json["duration"])
    );
  }


  Map<String, dynamic> toJson(){
    return {
      "track": track,
      "duration": duration.inSeconds
    };
  }

}