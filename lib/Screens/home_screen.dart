import 'package:flutter/material.dart';
import 'package:pi_auto/Widgets/BasicInformationWidget.dart';
import 'package:pi_auto/Widgets/MediaCenterWidget.dart';
import 'package:pi_auto/Widgets/NavigationWidget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Flexible(
                    flex: 1,
                    child: BasicInformationWidget(),
                  ),
                  Flexible(
                    flex: 2,
                    child: MediaCenterWidget(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Flexible(
                    child: NavigationWidget(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
