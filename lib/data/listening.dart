class Listening {
  int track;
  Duration duration;
  DateTime lastChanged;
  String albumId;


  Listening({required this.track, required this.duration, required this.lastChanged, required this.albumId});


  static Listening fromJson(Map<String, dynamic> json){
    return Listening(
      track: json["track"],
      albumId: json["albumId"],
      lastChanged: json.containsKey("lastChanged") ? DateTime.parse(json["lastChanged"]) : DateTime.utc(0),
      duration: Duration(seconds: json["duration"])
    );
  }


  Map<String, dynamic> toJson(){
    return {
      "track": track,
      "duration": duration.inSeconds,
      "lastChanged": lastChanged.toIso8601String(),
      "albumId": albumId
    };
  }

}