import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Widgets/PhoneLoginWidget.dart';
import 'package:pi_auto/Widgets/QRCodeLoginWidget.dart';

class NeteaseLoginPage extends StatefulWidget {
  @override
  _NeteaseLoginPageState createState() => _NeteaseLoginPageState();
}

class _NeteaseLoginPageState extends State<NeteaseLoginPage> {
  String _groupValue = "phone";

  Widget phoneLoginWidget = PhoneLoginWidget();
  Widget qrCodeLoginWidget = QRCodeLoginWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 300,
                margin: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: CupertinoSlidingSegmentedControl<String>(
                  thumbColor: Colors.white,
                  groupValue: _groupValue,
                  children: {
                    "phone": Text("Phone"),
                    "qr": Text("QR Code"),
                  },
                  onValueChanged: (value) {
                    print(value);
                    setState(() {
                      _groupValue = value;
                    });
                  },
                ),
              ),
              if (_groupValue == "phone")
                phoneLoginWidget
              else if (_groupValue == "qr")
                qrCodeLoginWidget
            ],
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            color: CupertinoColors.activeBlue,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
