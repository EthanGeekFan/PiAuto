import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Models/BasicInformationModel.dart';
import 'package:provider/provider.dart';

class BasicInformationWidget extends StatefulWidget {
  @override
  _BasicInformationWidgetState createState() => _BasicInformationWidgetState();
}

class _BasicInformationWidgetState extends State<BasicInformationWidget> {
  String _timeString = '';
  Timer _clock;
  Timer _weather;

  @override
  void initState() {
    super.initState();
    _clock = new Timer.periodic(
      Duration(seconds: 2),
      (Timer t) => _getTime(),
    );
    _getTime();
    Intl.defaultLocale = "zh_CN";
    initializeDateFormatting("en_US");
    _weather = Timer.periodic(
      Duration(minutes: 1),
      (Timer t) => _updateWeather(),
    );
  }

  void _getTime() {
    final DateTime now = new DateTime.now();
    final formatedDateTime = _formatDateTime(now);
    setState(() {
      this._timeString = formatedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM EEE dd | hh:mm', 'en_US').format(dateTime);
  }

  void _updateWeather() {
    this.context.read<BasicInformationModel>().updateWeather();
  }

  @override
  void dispose() {
    _clock.cancel();
    _weather.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300],
              blurRadius: 10.0,
              spreadRadius: 5.0,
            )
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _timeString.split('|')[0],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          wordSpacing: 2,
                        ),
                      ),
                    ),
                    Text(
                      _timeString.split('|')[1],
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        wordSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              context
                                  .watch<BasicInformationModel>()
                                  .weather
                                  .city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w400,
                                wordSpacing: 2,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              "更新于" +
                                  context
                                      .watch<BasicInformationModel>()
                                      .weather
                                      .updateTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                wordSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      context.watch<BasicInformationModel>().weather.name,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        wordSpacing: 2,
                      ),
                    ),
                    Text(
                      context.watch<BasicInformationModel>().weather.temp + "℃",
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w200,
                        wordSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
