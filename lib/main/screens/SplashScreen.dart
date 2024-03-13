import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yes_sir/user/screens/DashboardScreen.dart';
import '../../delivery/screens/DeliveryDashBoard.dart';
import '../../main/screens/LoginScreen.dart';
import '../../main/utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;

String? userID;
String? userName;
String? androidID;

class SplashScreen extends StatefulWidget {
  static String tag = '/SplashScreen';

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  String? deviceID;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future getID() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    userID = sharedPreferences.getString('id');
    userName = sharedPreferences.getString('name');
    androidID = sharedPreferences.getString('androidID');
  }

  Future<void> init() async {
    setStatusBarColor(appStore.isDarkMode ? Colors.black : Colors.white, statusBarBrightness: appStore.isDarkMode ? Brightness.light : Brightness.dark);
    print(userID);
    getID().whenComplete(() async {
      if(userID != null){

        final url = Uri.parse( mBaseUrl +'getUserDeviceID/' + userID!);
        final response = await http.get(
          url,
          headers: headers, // Encode the request body to JSON
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            deviceID = responseData['user_device'];

            Future.delayed(
              Duration(seconds: 0),
                  () {
                if (userID != null && userName != null && androidID == deviceID) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              },
            );
          } else {
            print('Not Working');
          }
        } else {
          print(response.statusCode);
        }
      }else{
        Future.delayed(
          Duration(seconds: 0),
              () {
            if (userID != null && userName != null && androidID == deviceID) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            }
          },
        );
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
    );
  }
}
