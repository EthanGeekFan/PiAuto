import 'package:shared_preferences/shared_preferences.dart';

class NeteaseCloudMusicConfig {
  // static const String phone = "";
  // static const String password = "";
  static int _uid;
  static set uid(int val) {
    _uid = val;
    var prefs = SharedPreferences.getInstance();
    prefs.then((value) => value.setInt("uid", val));
  }

  static int get uid => _uid;
  static String _username = "";
  static String get username => _username;
  static set username(String val) {
    _username = val;
    var prefs = SharedPreferences.getInstance();
    prefs.then((value) => value.setString("username", val));
  }

  static const String hostname = "ethan.local";
  static const String port = "3000";

  static const String rootUrl = "http://$hostname:$port/";
  static const String cellphoneLoginUrl =
      "http://$hostname:$port/login/cellphone";
  static const String sendCaptchaUrl = "http://$hostname:$port/captcha/sent";
  static const String captchaLoginUrl = "http://$hostname:$port/captcha/verify";
  static const String qrKeyGenUrl = "http://$hostname:$port/login/qr/key";
  static const String qrCreateUrl = "http://$hostname:$port/login/qr/create";
  static const String qrStatusUrl = "http://$hostname:$port/login/qr/check";
  static const String loginStatusUrl = "http://$hostname:$port/login/status";
  static const String refreshLoginUrl = "http://$hostname:$port/login/refresh";
  static const String logoutUrl = "http://$hostname:$port/logout";

  static const String userInfoUrl = "http://$hostname:$port/user/account";

  // login required
  static String get userPlaylistsUrl =>
      "http://$hostname:$port/user/playlist?uid=$uid";

  // args:
  // id - playlist id
  static const String playlistDetailUrl =
      "http://$hostname:$port/playlist/detail?id=";

  // args:
  // id - songs' ids seperated by commas
  static const String songUrlUrl = "http://$hostname:$port/song/url?id=";

  // args:
  // id - songs' ids seperated by commas
  static const String songDetailUrl = "http://$hostname:$port/song/detail?ids=";

  // args:
  // id - song's id
  static const String checkAvailabilityUrl =
      "http://$hostname:$port/check/music?id=";

  // args:
  // none
  // login required
  static const String fetchDailyRecommendedPlaylistsUrl =
      "http://$hostname:$port/recommend/resource";

  // args:
  // none
  // login required
  static const String fetchDailyRecommendedSongsUrl =
      "http://$hostname:$port/recommend/songs";

  // args:
  // none
  // login required
  static const String fetchPersonalFMUrl = "http://$hostname:$port/personal_fm";

  // args:
  // id - song's id
  // like - boolean like/dislike => url += "&like=false"
  // login required
  static const String likeSongUrl = "http://$hostname:$port/like?id=";

  // args:
  // none
  // login required
  static String get fetchUserLikelistUrl =>
      "http://$hostname:$port/likelist?uid=$uid";

  // args:
  // limit - number of playlists fetched, default 30 => url += "?limit=20"
  // login required
  static String get fetchRecommendedPlaylistUrl =>
      "http://$hostname:$port/personalized";

  // args:
  // id - @required song id
  // pid - @required playlist id => url += "&pid=..."
  // sid - start song id
  // login required
  static String get intelligenceModeUrl =>
      "http://$hostname:$port/playmode/intelligence/list?id=";
}
