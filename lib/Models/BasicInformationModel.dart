import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class BasicInformationModel with ChangeNotifier {
  //  Weather information
  Weather weather;

  BasicInformationModel() {
    this.weather = new Weather();
    this.updateWeather();
  }

  static const String WEATHER_API_KEY = "";
  static const String WEATHER_API_URL =
      "https://api.seniverse.com/v3/weather/now.json?key=$WEATHER_API_KEY&location=ip&language=zh-Hans&unit=c";

  Future<void> updateWeather() async {
    http.Response response = await http.get(WEATHER_API_URL);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var weatherData = jsonResponse["results"][0];
      this.weather.name = weatherData["now"]["text"];
      this.weather.temp = weatherData["now"]["temperature"];
      this.weather.city = weatherData["location"]["name"];
      this.weather.updateTime =
          weatherData["last_update"].toString().substring(11, 16);
      notifyListeners();
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }
}

class Weather {
  String name;
  String temp;
  String city;
  String updateTime;

  Weather() {
    this.name = '';
    this.temp = '';
    this.city = '';
    this.updateTime = '';
  }
}
