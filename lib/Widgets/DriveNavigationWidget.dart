import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriveNavigationWidget extends StatefulWidget {
  @override
  _DriveNavigationWidgetState createState() => _DriveNavigationWidgetState();
}

class _DriveNavigationWidgetState extends State<DriveNavigationWidget> {
  @override
  Widget build(BuildContext context) {
    final String viewType = "com.ethan.PiAuto/views/navigationview";
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return Center(
      child: Stack(
        children: [
          Center(
            child: UiKitView(
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ],
      ),
    );
  }
}
