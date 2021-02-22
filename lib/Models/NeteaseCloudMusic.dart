import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pi_auto/Configurations/NeteaseCloudMusicConfig.dart';
import 'package:pi_auto/main.dart';

class NeteaseCloudMusicModel with ChangeNotifier {
  bool _loggedin = false;

  set loggedin(bool value) {
    _loggedin = value;
    notifyListeners();
  }

  bool get loggedin => _loggedin;

  Dio dio = Dio();
  PersistCookieJar cookieJar;
  Directory docDir;
  bool cookieManagerInited = false;

  NeteaseCloudMusicModel() {
    initCookieManager();
    login();
  }

  Future<void> initCookieManager() async {
    docDir = await getApplicationDocumentsDirectory();
    cookieJar = new PersistCookieJar(
      dir: docDir.path + "/.cookies/",
      ignoreExpires: true,
    );
    dio.interceptors.add(CookieManager(cookieJar));
    cookieManagerInited = true;
  }

  Future<bool> login() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.cellphoneLoginUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        var account = jsonResponse["account"];
        if (account == null) {
          // not logged in
          loggedin = false;
          return false;
        }
        var uid = account["id"];
        print("Login uid: " + uid.toString());
        loggedin = true;
      } else {
        print("login not successful");
        loggedin = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return loggedin;
  }

  Future<bool> loginStatus() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.loginStatusUrl;
    Response response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["data"]["code"] == 200;
      print(jsonResponse);
      if (success) {
        var account = jsonResponse["data"]["account"];
        if (account == null) {
          // not logged in
          loggedin = false;
          print("ss");
          return false;
        }
        var uid = account["id"];
        print("Login uid: " + uid.toString());
        loggedin = true;
      } else {
        print("not logged in");
        loggedin = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return loggedin;
  }

  Future<bool> refreshLogin() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.refreshLoginUrl + "?t=" + t.toString();
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        loggedin = true;
      } else {
        print("not logged in");
        loggedin = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return loggedin;
  }

  Future<bool> logout() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.logoutUrl + "?t=" + t.toString();
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        loggedin = false;
        return true;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return false;
  }

  Future<List<PlaylistPreview>> fetchUserPlaylists() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    if (!loggedin) {
      await login();
    }
    var url = NeteaseCloudMusicConfig.userPlaylistsUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got playlists
        var rawPlaylistPreviews = jsonResponse["playlist"];
        List<PlaylistPreview> result = [];
        try {
          for (var i = 0; i < rawPlaylistPreviews.length; i++) {
            var rawPlaylistPreview = rawPlaylistPreviews[i];
            PlaylistPreview cache = new PlaylistPreview(
              id: rawPlaylistPreview["id"].toString(),
              name: rawPlaylistPreview["name"],
              coverImgUrl: rawPlaylistPreview["coverImgUrl"],
            );
            result.add(cache);
          }
          return result;
        } catch (e) {
          // json response parse error
          print("response parse error while fetching user playlists");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<Playlist> fetchPlaylistDetail(String id) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    var url = NeteaseCloudMusicConfig.playlistDetailUrl + id;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got playlist detail
        var rawPlaylistDetail = jsonResponse["playlist"];
        try {
          var rawTracks = rawPlaylistDetail["tracks"];
          String id = rawPlaylistDetail["id"].toString();
          String name = rawPlaylistDetail["name"];
          String coverImgUrl = rawPlaylistDetail["coverImgUrl"];
          List<Song> tracks = [];
          for (var i = 0; i < rawTracks.length; i++) {
            var rawSong = rawTracks[i];
            Song songCache = new Song(
              name: rawSong["name"],
              id: rawSong["id"].toString(),
              duration: Duration(milliseconds: rawSong["dt"]),
              artist: Artist(
                id: rawSong["ar"][0]["id"].toString(),
                name: rawSong["ar"][0]["name"],
              ),
              album: Album(
                name: rawSong["al"]["name"],
                id: rawSong["al"]["id"].toString(),
                picUrl: rawSong["al"]["picUrl"],
              ),
            );
            tracks.add(songCache);
          }
          return Playlist(
            id: id,
            name: name,
            coverImgUrl: coverImgUrl,
            tracks: tracks,
          );
        } catch (e) {
          // json response parse error
          print("response parse error while fetching playlist detail");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<Map<String, String>> parseSongsUrl(List<String> ids) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    var url = NeteaseCloudMusicConfig.songUrlUrl;
    for (var i = 0; i < ids.length; i++) {
      url += ids[i];
      if (i != ids.length - 1) {
        url += ",";
      }
    }
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got song urls
        try {
          Map<String, String> result = Map<String, String>();
          var songs = jsonResponse["data"];
          for (var i = 0; i < songs.length; i++) {
            var rawSong = songs[i];
            result[rawSong["id"].toString()] = rawSong["url"];
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching Song url");
          return null;
        }
      }
      return null;
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<String> parseSongUrl(String id) async {
    return (await parseSongsUrl([id]))[id];
  }

  Future<List<Song>> fetchSongsDetail(List<String> ids) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    var url = NeteaseCloudMusicConfig.songDetailUrl;
    for (var i = 0; i < ids.length; i++) {
      url += ids[i];
      if (i != ids.length - 1) {
        url += ",";
      }
    }
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got song details
        try {
          List<Song> result = List<Song>();
          var songs = jsonResponse["songs"];
          for (var i = 0; i < songs.length; i++) {
            var rawSong = songs[i];
            Song songCache = new Song(
              name: rawSong["name"],
              id: rawSong["id"].toString(),
              duration: Duration(milliseconds: rawSong["dt"]),
              artist: Artist(
                id: rawSong["ar"][0]["id"].toString(),
                name: rawSong["ar"][0]["name"],
              ),
              album: Album(
                name: rawSong["al"]["name"],
                id: rawSong["al"]["id"].toString(),
                picUrl: rawSong["al"]["picUrl"],
              ),
            );
            result.add(songCache);
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching Song Detail");
          return null;
        }
      }
      return null;
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<Song> fetchSongDetail(String id) async {
    return (await fetchSongsDetail([id]))[0];
  }

  Future<bool> checkSongAvailability(String id) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    var url = NeteaseCloudMusicConfig.checkAvailabilityUrl + id;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool available =
          jsonResponse["success"] == true && jsonResponse["message"] == "ok";
      if (available) {
        return true;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return false;
  }

  Future<List<PlaylistPreview>> fetchDailyRecommendedPlaylists() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    if (!loggedin) {
      print("Not loggedin. This action requires login");
      // return null;
    }
    var url = NeteaseCloudMusicConfig.fetchDailyRecommendedPlaylistsUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got playlists
        var rawPlaylistPreviews = jsonResponse["recommend"];
        List<PlaylistPreview> result = [];
        try {
          for (var i = 0; i < rawPlaylistPreviews.length; i++) {
            var rawPlaylistPreview = rawPlaylistPreviews[i];
            PlaylistPreview cache = new PlaylistPreview(
              id: rawPlaylistPreview["id"].toString(),
              name: rawPlaylistPreview["name"],
              coverImgUrl: rawPlaylistPreview["picUrl"],
            );
            result.add(cache);
          }
          return result;
        } catch (e) {
          // json response parse error
          print(
              "response parse error while fetching daily recommended playlists");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<List<Song>> fetchDailyRecommendedSongs() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    if (!loggedin) {
      await login();
    }
    if (!loggedin) {
      print("Not loggedin. This action requires login");
      // return null;
    }
    var url = NeteaseCloudMusicConfig.fetchDailyRecommendedSongsUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got songs
        try {
          List<Song> result = List<Song>();
          var songs = jsonResponse["data"]["dailySongs"];
          for (var i = 0; i < songs.length; i++) {
            var rawSong = songs[i];
            Song songCache = new Song(
              name: rawSong["name"],
              id: rawSong["id"].toString(),
              duration: Duration(milliseconds: rawSong["dt"]),
              artist: Artist(
                id: rawSong["ar"][0]["id"].toString(),
                name: rawSong["ar"][0]["name"],
              ),
              album: Album(
                name: rawSong["al"]["name"],
                id: rawSong["al"]["id"].toString(),
                picUrl: rawSong["al"]["picUrl"],
              ),
            );
            result.add(songCache);
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching recommended songs");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<List<Song>> fetchPersonalFM() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    if (!loggedin) {
      print("Not loggedin. This action requires login");
      // return null;
    }
    var url = NeteaseCloudMusicConfig.fetchPersonalFMUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got songs
        try {
          List<Song> result = List<Song>();
          var songs = jsonResponse["data"];
          for (var i = 0; i < songs.length; i++) {
            var rawSong = songs[i];
            Song songCache = new Song(
              name: rawSong["name"],
              id: rawSong["id"].toString(),
              duration: Duration(
                milliseconds: (rawSong["bMusic"] ??
                    rawSong["hMusic"] ??
                    rawSong["mMusic"] ??
                    rawSong["lMusic"])["playTime"],
              ),
              artist: Artist(
                id: rawSong["artists"][0]["id"].toString(),
                name: rawSong["artists"][0]["name"],
              ),
              album: Album(
                name: rawSong["album"]["name"],
                id: rawSong["album"]["id"].toString(),
                picUrl: rawSong["album"]["picUrl"],
              ),
            );
            result.add(songCache);
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching personal FM");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<bool> likeSong(String id, {bool like}) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.likeSongUrl + id + "&t=$t";
    if (like != null) {
      url += "&like=" + like.toString();
    }
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        return true;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return false;
  }

  Future<List<String>> fetchUserLikelist() async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    var url = NeteaseCloudMusicConfig.fetchUserLikelistUrl;
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got songs id list
        try {
          List<String> result = List<String>();
          var songs = jsonResponse["ids"];
          for (var i = 0; i < songs.length; i++) {
            result.add(songs[i].toString());
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching likelist songs");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<List<PlaylistPreview>> fetchRecommendedPlaylists({int limit}) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    var url = NeteaseCloudMusicConfig.fetchRecommendedPlaylistUrl;
    if (limit != null) {
      url += "?limit=" + limit.toString();
    }
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got playlists
        var rawPlaylistPreviews = jsonResponse["result"];
        List<PlaylistPreview> result = [];
        try {
          for (var i = 0; i < rawPlaylistPreviews.length; i++) {
            var rawPlaylistPreview = rawPlaylistPreviews[i];
            PlaylistPreview cache = new PlaylistPreview(
              id: rawPlaylistPreview["id"].toString(),
              name: rawPlaylistPreview["name"],
              coverImgUrl: rawPlaylistPreview["picUrl"],
            );
            // print("raw: " + rawPlaylistPreview.toString());
            result.add(cache);
          }
          return result;
        } catch (e) {
          // json response parse error
          print("response parse error while fetching recommended playlists");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }

  Future<List<Song>> intelligenceMode(String songId, String playlistId,
      {String startId}) async {
    if (!cookieManagerInited) {
      await initCookieManager();
    }
    // if (!loggedin) {
    //   await login();
    // }
    var url = NeteaseCloudMusicConfig.intelligenceModeUrl;
    url += songId;
    url += "&pid=" + playlistId;
    if (startId != null) {
      url += "&sid=" + startId;
    }
    Response<Map> response = await dio.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        // got songs
        try {
          List<Song> result = List<Song>();
          var songs = jsonResponse["data"];
          for (var i = 0; i < songs.length; i++) {
            var rawSong = songs[i]["songInfo"];
            Song songCache = new Song(
              name: rawSong["name"],
              id: rawSong["id"].toString(),
              duration: Duration(milliseconds: rawSong["dt"]),
              artist: Artist(
                id: rawSong["ar"][0]["id"].toString(),
                name: rawSong["ar"][0]["name"],
              ),
              album: Album(
                name: rawSong["al"]["name"],
                id: rawSong["al"]["id"].toString(),
                picUrl: rawSong["al"]["picUrl"],
              ),
            );
            result.add(songCache);
          }
          return result;
        } catch (e) {
          // json parse error
          print("response parse error while fetching personal FM");
          return null;
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return null;
  }
}

class PlaylistPreview {
  String id;
  String name;
  String coverImgUrl;

  PlaylistPreview({
    @required this.id,
    @required this.name,
    @required this.coverImgUrl,
  });
}

class Playlist {
  String id;
  String name;
  String coverImgUrl;
  List<Song> tracks;

  PlaylistPreview get preview => new PlaylistPreview(
        id: this.id,
        name: this.name,
        coverImgUrl: this.coverImgUrl,
      );

  Playlist({
    @required this.id,
    @required this.name,
    @required this.coverImgUrl,
    @required this.tracks,
  });
}

class Song {
  String name;
  String id;
  Duration duration;
  Artist artist;
  Album album;

  Song({
    @required this.name,
    @required this.id,
    @required this.duration,
    @required this.artist,
    @required this.album,
  });

  MediaItem toMediaItem() {
    return MediaItem(
      id: this.id,
      title: this.name,
      album: this.album.name,
      artUri: this.album.picUrl,
      artist: this.artist.name,
      duration: this.duration,
    );
  }
}

class Artist {
  String name;
  String id;

  Artist({
    @required this.name,
    @required this.id,
  });
}

class Album {
  String name;
  String id;
  String picUrl;

  Album({
    @required this.name,
    @required this.id,
    @required this.picUrl,
  });
}

enum NeteaseCloudMusicPlayMode {
  loopAll,
  loopOne,
  list,
  shuffle,
}

class NeteaseCloudMusicClient with ChangeNotifier {
  NeteaseCloudMusicPlayMode playMode = NeteaseCloudMusicPlayMode.list;
  List<MediaItem> currentBackgroundPlaylist = [];
  List<PlaylistPreview> _recommendedPlaylists = [];
  List<PlaylistPreview> _dailyRecommendedPlaylists = [];
  List<PlaylistPreview> _userPlaylists = [];
  List<String> _userLikeList = [];
  Timer _userLikeListUpdater;

  set userPlaylists(List<PlaylistPreview> value) {
    _userPlaylists = value;
    notifyListeners();
  }

  List<PlaylistPreview> get userPlaylists => _userPlaylists;

  set dailyRecommendedPlaylists(List<PlaylistPreview> value) {
    _dailyRecommendedPlaylists = value;
    notifyListeners();
  }

  List<PlaylistPreview> get dailyRecommendedPlaylists =>
      _dailyRecommendedPlaylists;

  set recommendedPlaylists(List<PlaylistPreview> value) {
    _recommendedPlaylists = value;
    notifyListeners();
  }

  List<PlaylistPreview> get recommendedPlaylists => _recommendedPlaylists;

  NeteaseCloudMusicClient() {
    neteaseCloudMusicModel.login();
    updateRecommendedPlaylists();
    updateDailyRecommendedPlaylists();
    updateUserPlaylists();
    this._userLikeListUpdater = Timer.periodic(
      Duration(minutes: 2),
      (timer) {
        updateUserLikeList();
      },
    );
  }

  @override
  void dispose() {
    this._userLikeListUpdater.cancel();
    super.dispose();
  }

  Future<void> updateRecommendedPlaylists() async {
    recommendedPlaylists =
        await neteaseCloudMusicModel.fetchRecommendedPlaylists(limit: 10);
  }

  Future<void> updateDailyRecommendedPlaylists() async {
    dailyRecommendedPlaylists =
        await neteaseCloudMusicModel.fetchDailyRecommendedPlaylists();
  }

  Future<void> updateUserPlaylists() async {
    userPlaylists = await neteaseCloudMusicModel.fetchUserPlaylists();
  }

  void causeRebuild() {
    notifyListeners();
  }

  Future<void> usePlaylist(String playlistId) async {
    currentBackgroundPlaylist =
        (await neteaseCloudMusicModel.fetchPlaylistDetail(playlistId))
            .tracks
            .map(
              (e) => MediaItem(
                id: e.id,
                title: e.name ?? "No Title",
                album: e.album.name ?? "",
                artist: e.artist.name ?? "Unknown Artist",
                artUri: e.album.picUrl,
                duration: e.duration,
              ),
            )
            .toList();
    // print("this playlist: $currentBackgroundPlaylist");
    // Load and broadcast the queue
    AudioService.updateQueue(currentBackgroundPlaylist).then((value) {
      notifyListeners();
      print("loaded");
    });
  }

  void switchPlayMode() async {
    switch (playMode) {
      case NeteaseCloudMusicPlayMode.list:
        playMode = NeteaseCloudMusicPlayMode.loopAll;
        await AudioService.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case NeteaseCloudMusicPlayMode.loopAll:
        playMode = NeteaseCloudMusicPlayMode.loopOne;
        await AudioService.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case NeteaseCloudMusicPlayMode.loopOne:
        playMode = NeteaseCloudMusicPlayMode.shuffle;
        await AudioService.setShuffleMode(AudioServiceShuffleMode.all);
        break;
      case NeteaseCloudMusicPlayMode.shuffle:
        playMode = NeteaseCloudMusicPlayMode.list;
        await AudioService.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      default:
        await AudioService.setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
    notifyListeners();
  }

  Future<void> updateUserLikeList() async {
    _userLikeList = await neteaseCloudMusicModel.fetchUserLikelist();
  }

  Future<bool> checkIfLiked(String id) async {
    return _userLikeList.contains(id);
  }

  Future<void> dislike(String id) async {
    var result = await neteaseCloudMusicModel.likeSong(id, like: false);
    if (result) {
      _userLikeList.remove(id);
    }
    print("disliked: $result");
    notifyListeners();
  }

  Future<void> like(String id) async {
    var result = await neteaseCloudMusicModel.likeSong(id, like: true);
    if (result) {
      _userLikeList.add(id);
    }
    print("liked: $result");
    notifyListeners();
  }
}
