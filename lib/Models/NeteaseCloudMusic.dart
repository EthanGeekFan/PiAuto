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
import 'package:shared_preferences/shared_preferences.dart';

class NeteaseCloudMusicModel with ChangeNotifier {
  bool _loggedin = false;
  bool loginInProgress = false;

  bool qrLoginInProgress = false;

  set loggedin(bool value) {
    _loggedin = value;
    notifyListeners();
  }

  bool get loggedin => _loggedin;

  Dio dio = Dio();
  // Future<PersistCookieJar> cookieJar;
  Future<SharedPreferences> cookies;

  NeteaseCloudMusicModel() {
    // cookieJar = initCookieManager();
    cookies = SharedPreferences.getInstance();
    autoLogin();
  }

  Future<PersistCookieJar> initCookieManager() async {
    var docDir = await getApplicationDocumentsDirectory();
    var jar = new PersistCookieJar(
      dir: docDir.path + "/.cookies/",
      ignoreExpires: true,
    );
    dio.interceptors.add(CookieManager(jar));
    var c = jar.loadForRequest(Uri.parse(NeteaseCloudMusicConfig.rootUrl));
    print(c);
    c = jar
        .loadForRequest(Uri.parse(NeteaseCloudMusicConfig.cellphoneLoginUrl));
    print("c2:");
    print(c);
    return jar;
  }

  Future<bool> hasCookie() async {
    var result = false;
    // for (var item in (// await cookieJar).domains) {
    //   for (var entry in item.entries) {
    //     print(entry.key);
    //     if (entry.key == NeteaseCloudMusicConfig.hostname) {
    //       result = true;
    //     }
    //   }
    // }
    if ((await cookies).getString("cookie") != null) {
      result = true;
    }
    return result;
  }

  Future<bool> autoLogin() async {
    print("autoLogin");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await hasCookie()) {
      var storedUid = prefs.getInt("uid");
      if (storedUid == null) {
        // needs login
        // loggedin = false;
        // return false;
        print("null id");
      } else {
        print('read uid');
        NeteaseCloudMusicConfig.uid = storedUid;
        NeteaseCloudMusicConfig.username = prefs.getString("username");
        print("storedUid: " +
            storedUid.toString() +
            " " +
            prefs.getString("username"));
      }
      refreshLogin();
      print("login refresh complete");
      loggedin = true;
      return true;
    }
    // needs login
    return false;
  }

  Future<bool> loginWithPhonePwd(String phone, String pwd) async {
    loginInProgress = true;
    var cookie = (await cookies).getString("cookie");
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.cellphoneLoginUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "phone": phone,
        "password": pwd,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        var account = jsonResponse["account"];
        if (account == null) {
          // not logged in
          loggedin = false;
          loginInProgress = false;
          return false;
        }
        (await cookies).setString("cookie", jsonResponse["cookie"]);
        var uid = account["id"];
        var username = jsonResponse["profile"]["nickname"];
        NeteaseCloudMusicConfig.uid = uid;
        NeteaseCloudMusicConfig.username = username;
        loggedin = true;
      } else {
        print("login not successful");
        loggedin = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    loginInProgress = false;
    return loggedin;
  }

  Future<bool> getCaptcha(String phone) async {
    var url = NeteaseCloudMusicConfig.sendCaptchaUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "phone": phone,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> loginWithPhoneCaptcha(String phone, String captcha) async {
    loginInProgress = true;
    // // await cookieJar;
    var cookie = await hasCookie();
    if (cookie) {
      var refresh = await refreshLogin();
      loginInProgress = false;
      return refresh;
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.captchaLoginUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "phone": phone,
        "captcha": captcha,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        var account = jsonResponse["account"];
        if (account == null) {
          // not logged in
          loggedin = false;
          loginInProgress = false;
          return false;
        }
        var uid = account["id"];
        var username = jsonResponse["profile"]["nickname"];
        NeteaseCloudMusicConfig.uid = uid;
        NeteaseCloudMusicConfig.username = username;
        print("Login uid: " + NeteaseCloudMusicConfig.uid.toString());
        loggedin = true;
      } else {
        print("login not successful");
        loggedin = false;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    loginInProgress = false;
    return loggedin;
  }

  Future<String> loginWithQR() async {
    loginInProgress = true;
    // // await cookieJar;
    var cookie = await hasCookie();
    if (cookie) {
      var refresh = await refreshLogin();
      loginInProgress = false;
    }

    // Generate QR Key:
    String key = "";
    var url = NeteaseCloudMusicConfig.qrKeyGenUrl;
    Response<Map> response = await dio.get(
      url,
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data["data"];
      bool success = jsonResponse["code"] == 200;
      if (success) {
        key = jsonResponse["unikey"];
      } else {
        print("qrKeyGen not successful");
        loginInProgress = false;
        return null;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
      loginInProgress = false;
      return null;
    }

    // Create QR Code:
    String base64QR;
    url = NeteaseCloudMusicConfig.qrCreateUrl;
    response = await dio.get(
      url,
      queryParameters: {
        "key": key,
        "qrimg": true,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        var data = jsonResponse["data"];
        base64QR = data["qrimg"];
      } else {
        print("qrKeyCreate not successful");
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    loginInProgress = false;
    qrLoginInProgress = true;
    qrLoginStatusCheck(key).then((value) => qrLoginInProgress = false);
    return base64QR;
  }

  Future<void> qrLoginStatusCheck(String key) async {
    var status = 801;
    Response<Map> response;
    while (status != 800) {
      Future.delayed(Duration(milliseconds: 500));
      var url = NeteaseCloudMusicConfig.qrStatusUrl;
      response = await dio.get(
        url,
        queryParameters: {
          "key": key,
        },
        options: Options(
          headers: {
            "xhrFields": {
              "withCredentials": true,
            },
          },
        ),
      );
      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        status = jsonResponse["code"] as int;
        if (status == 803) {
          break;
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return;
      }
    }
    print('login successfull');
    var uid = response.data["account"]["id"];
    var username = response.data["profile"]["nickname"];
    NeteaseCloudMusicConfig.uid = uid;
    NeteaseCloudMusicConfig.username = username;
    loggedin = true;
    return;
  }

  Future<bool> loginStatus() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.loginStatusUrl;
    Response response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    print("refreshLogin");
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url =
        NeteaseCloudMusicConfig.refreshLoginUrl + "?timestamp=" + t.toString();
    // (// await cookieJar).loadForRequest(Uri.parse(url));
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        print("login refreshed");
      } else {
        print("refresh failed");
        return false;
      }
    } else {
      print('refresh failed with status: ${response.statusCode}.');
    }
    return loggedin;
  }

  Future<bool> logout() async {
    // await cookieJar;
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.logoutUrl + "?timestamp=" + t.toString();
    Response<Map> response = await dio.get(
      url,
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      bool success = jsonResponse["code"] == 200;
      if (success) {
        NeteaseCloudMusicConfig.uid = null;
        loggedin = false;
        return true;
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    return false;
  }

  // Login
  Future<List<PlaylistPreview>> fetchUserPlaylists() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    if (NeteaseCloudMusicConfig.uid == null) {
      print('userplaylist without uid: ${NeteaseCloudMusicConfig.uid}');
      return [];
    }
    var url = NeteaseCloudMusicConfig.userPlaylistsUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var url = NeteaseCloudMusicConfig.playlistDetailUrl + id;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var url = NeteaseCloudMusicConfig.songUrlUrl;
    for (var i = 0; i < ids.length; i++) {
      url += ids[i];
      if (i != ids.length - 1) {
        url += ",";
      }
    }
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var url = NeteaseCloudMusicConfig.songDetailUrl;
    for (var i = 0; i < ids.length; i++) {
      url += ids[i];
      if (i != ids.length - 1) {
        url += ",";
      }
    }
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var url = NeteaseCloudMusicConfig.checkAvailabilityUrl + id;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<PlaylistPreview>> fetchDailyRecommendedPlaylists() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.fetchDailyRecommendedPlaylistsUrl;
    // print((// await cookieJar).loadForRequest(Uri.parse(url)));
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<Song>> fetchDailyRecommendedSongs() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.fetchDailyRecommendedSongsUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<Song>> fetchPersonalFM() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.fetchPersonalFMUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<bool> likeSong(String id, {bool like}) async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    int t = new DateTime.now().millisecondsSinceEpoch;
    var url = NeteaseCloudMusicConfig.likeSongUrl + id + "&t=$t";
    if (like != null) {
      url += "&like=" + like.toString();
    }
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<String>> fetchUserLikelist() async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    if (NeteaseCloudMusicConfig.uid == "") {
      return [];
    }
    var retryCount = 0;
    if (!loggedin) {
      Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.fetchUserLikelistUrl;
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<PlaylistPreview>> fetchRecommendedPlaylists({int limit}) async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.fetchRecommendedPlaylistUrl;
    if (limit != null) {
      url += "?limit=" + limit.toString();
    }
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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

  // Login
  Future<List<Song>> intelligenceMode(String songId, String playlistId,
      {String startId}) async {
    // await cookieJar;
    var cookie = (await cookies).getString("cookie");
    var retryCount = 0;
    if (!loggedin) {
      await Future.doWhile(() {
        Future.delayed(Duration(seconds: 1));
        retryCount += 1;
        return !loggedin && retryCount <= 30;
      });
    }
    var url = NeteaseCloudMusicConfig.intelligenceModeUrl;
    url += songId;
    url += "&pid=" + playlistId;
    if (startId != null) {
      url += "&sid=" + startId;
    }
    Response<Map> response = await dio.get(
      url,
      queryParameters: {
        "cookie": cookie,
      },
      options: Options(
        headers: {
          "xhrFields": {
            "withCredentials": true,
          },
        },
      ),
    );
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
    startServices();
  }

  void startServices() async {
    neteaseCloudMusicModel.addListener(() {
      fetchPageData();
    });
    await fetchPageData();
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

  Future<void> fetchPageData() async {
    print("Fetching data");
    await updateRecommendedPlaylists();
    await updateDailyRecommendedPlaylists();
    await updateUserPlaylists();
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
