import 'package:flutter/material.dart';
import 'package:pi_auto/Models/BasicInformationModel.dart';
import 'package:pi_auto/Models/MediaCenterModel.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';
import 'package:pi_auto/Screens/home_screen.dart';
import 'package:pi_auto/Widgets/MediaCenterWidget.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

NeteaseCloudMusicModel neteaseCloudMusicModel = NeteaseCloudMusicModel();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BasicInformationModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => neteaseCloudMusicModel,
        ),
        ChangeNotifierProvider(
          create: (_) => MediaCenterCardControllerModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => NeteaseCloudMusicClient(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pi Auto',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AudioServiceWidget(child: HomeScreen()),
    );
  }
}
