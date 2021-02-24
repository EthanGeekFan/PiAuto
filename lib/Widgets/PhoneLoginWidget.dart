import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_auto/Configurations/NeteaseCloudMusicConfig.dart';
import 'package:pi_auto/main.dart';

class PhoneLoginWidget extends StatefulWidget {
  @override
  _PhoneLoginWidgetState createState() => _PhoneLoginWidgetState();
}

class _PhoneLoginWidgetState extends State<PhoneLoginWidget> {
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  GlobalKey _formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      child: Form(
        key: _formKey,
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
              height: 40,
            ),
            Container(
              width: 350,
              child: CupertinoTextField(
                controller: _phoneController,
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide.none),
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                maxLength: 11,
                placeholder: "Phone",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Icon(Icons.phone_rounded),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 15,
                  // horizontal: 5,
                ),
                style: TextStyle(
                  fontSize: 18,
                ),
                maxLines: 1,
                toolbarOptions: ToolbarOptions(
                  copy: true,
                  paste: true,
                  cut: true,
                  selectAll: true,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 350,
              child: CupertinoTextField(
                controller: _passwordController,
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide.none),
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                obscureText: true,
                placeholder: "Password",
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Icon(Icons.lock_rounded),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 15,
                  // horizontal: 5,
                ),
                style: TextStyle(
                  fontSize: 18,
                ),
                maxLines: 1,
                toolbarOptions: ToolbarOptions(
                  copy: true,
                  paste: true,
                  cut: true,
                  selectAll: true,
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Container(
              child: CupertinoButton.filled(
                child: Text("Login"),
                onPressed: () async {
                  var success = await neteaseCloudMusicModel.loginWithPhonePwd(
                      _phoneController.text, _passwordController.text);
                  print(NeteaseCloudMusicConfig.uid);
                  if (success) {
                    Navigator.of(context).pop();
                  } else {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text("Login Failed"),
                          content: Text(
                            "Please check your connection and credentials then try again.",
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: Text(
                                "OK",
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
