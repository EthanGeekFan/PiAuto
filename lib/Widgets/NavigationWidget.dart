import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Widgets/DestinationSearchWidget.dart';
import 'package:pi_auto/Widgets/DriveNavigationWidget.dart';

class NavigationWidget extends StatefulWidget {
  @override
  _NavigationWidgetState createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 10.0,
              spreadRadius: 5.0,
            ),
          ],
        ),
        child: Navigator(
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            print(settings.name);
            switch (settings.name) {
              case '/':
                builder = (context) => DestinationSearchWidget();
                break;
              case '/navigation':
                builder = (context) => DriveNavigationWidget();
                break;
            }
            return MaterialPageRoute(builder: builder);
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(builder: (context) {
              return Center(
                child: Text(
                  "Page Route Error: Unknown Route - ${settings.name}",
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
