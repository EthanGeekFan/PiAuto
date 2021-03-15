import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pi_auto/Models/NeteaseCloudMusic.dart';
import 'package:pi_auto/main.dart';
import 'dart:convert';

class QRCodeLoginWidget extends StatefulWidget {
  @override
  _QRCodeLoginWidgetState createState() => _QRCodeLoginWidgetState();
}

class _QRCodeLoginWidgetState extends State<QRCodeLoginWidget> {
  String codeData;
  Image code;
  QRStatus status;
  Timer qrStatusChecker;

  @override
  void initState() {
    super.initState();
    neteaseCloudMusicModel.loginWithQR().then((value) {
      codeData = value;
      code = Image.memory(
        base64Decode(
          (codeData ?? "").substring("data:image/png;base64,".length),
        ),
        fit: BoxFit.fill,
      );
    });
    qrStatusChecker =
        Timer.periodic(Duration(milliseconds: 500), (timer) async {
      status = await neteaseCloudMusicModel.qrLoginStatusCheck();
      setState(() {});
      if (status == QRStatus.success) {
        qrStatusChecker.cancel();
        Navigator.of(this.context).pop();
      }
      if (status == QRStatus.expired) {
        neteaseCloudMusicModel.loginWithQR().then((value) {
          codeData = value;
          code = Image.memory(
            base64Decode(
              (codeData ?? "").substring("data:image/png;base64,".length),
            ),
            fit: BoxFit.fill,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    qrStatusChecker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      child: Column(
        children: [
          Text(
            "Netease Music",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () async {
              codeData = await neteaseCloudMusicModel.loginWithQR();
              setState(() {});
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  // color: Color.fromRGBO(200, 200, 200, 1),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 5,
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                    )
                  ]),
              clipBehavior: Clip.antiAlias,
              child: code,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "${status.toStatusString()}",
            style: TextStyle(
              fontSize: 18,
            ),
          )
        ],
      ),
    );
  }
}
