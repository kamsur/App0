import 'package:flutter/material.dart';
import 'package:app0/Screens/Welcome/components/background.dart';
import 'package:app0/components/rounded_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app0/DB/database_provider.dart';

class Body extends StatelessWidget {
  static final Config configB2Ca = new Config(
      "93ea5ca9-6dbc-4e15-99d1-2ae0d20b19a9",
      "ccfd9597-76f1-4246-8f5c-7bca14013308",
      "ccfd9597-76f1-4246-8f5c-7bca14013308 offline_access",
      "https://barqat.b2clogin.com/oauth2/nativeclient",
      clientSecret: null,
      isB2C: true,
      azureTenantName: "barqat",
      userFlow: "B2C_1A_SignUpOrSignInWithPhone",
      tokenIdentifier: "UNIQUE IDENTIFIER A");

  //You can have as many B2C flows as you want

  final AadOAuth oauthB2Ca = AadOAuth(configB2Ca);

  @override
  Widget build(BuildContext context) {
    // adjust window size for browser login
    //var screenSize = MediaQuery.of(context).size;
    //oauthB2Cb.setWebViewScreenSize(rectSize);
    Size size = MediaQuery.of(context).size;
    // This size provide us total height and width of our screen
    var rectSize = Rect.fromLTWH(0.0, 25.0, size.width, size.height - 25);
    oauthB2Ca.setWebViewScreenSize(rectSize);
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "WELCOME TO LAZARUS",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.05),
            SvgPicture.asset(
              "assets/icons/stethescope.svg",
              height: size.height * 0.45,
            ),
            SizedBox(height: size.height * 0.05),
            RoundedButton(
                text: "LOGIN / SIGN UP",
                press: () {
                  login(oauthB2Ca, context);
                }),
          ],
        ),
      ),
    );
  }

  void showError(dynamic ex, BuildContext context) {
    showMessage(ex.toString(), context);
  }

  void showMessage(String text, BuildContext context) {
    var alert = new AlertDialog(content: new Text(text), actions: <Widget>[
      new TextButton(
          child: const Text("Ok"),
          onPressed: () {
            //Navigator.pop(context);
          })
    ]);
    showDialog(context: context, builder: (BuildContext context) => alert);
  }

  Future<void> login(AadOAuth oAuth, BuildContext context) async {
    try {
      await oAuth.login();
      String accessToken = await oAuth.getAccessToken();
      int flag = 0;
      try {
        //print(parseJwtPayLoad(accessToken));
        await DatabaseProvider.db
            .setupDatabase(parseJwtPayLoad(accessToken), 'P');
        await DatabaseProvider.db.registerFamily();
        await _setLoggedIn(true);
        await _setEntered(false);
        flag = 1;
      } catch (e) {
        showError(e, context);
      }
      if (flag == 1) {
        //showMessage("Logged in successfully!", context);
        await oAuth.logout();
        Navigator.pushReplacementNamed(context, '/home',
            arguments: parseJwtPayLoad(accessToken));
      }
    } catch (e) {
      showError(e, context);
    }
  }

  static Map<String, dynamic> parseJwtPayLoad(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }
    return payloadMap;
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  } //String

  Future<void> _setLoggedIn(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('loggedIn', status);
    print("Logged In set");
  }

  Future<void> _setEntered(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('entered', status);
    print("Entered set");
  }
}
