import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:yes_sir/main/components/BodyCornerWidget.dart';
import '../../main.dart';
import '../../main/screens/ChangePasswordScreen.dart';
import '../../main/screens/EditProfileScreen.dart';
import '../../main/screens/LoginScreen.dart';
import '../../main/utils/Colors.dart';
import '../../main/utils/Common.dart';
import '../../main/utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main/screens/AboutUsScreen.dart';
import '../screens/DeleteAccountScreen.dart';

class AccountFragment extends StatefulWidget {
  static String tag = '/AccountFragment';

  @override
  AccountFragmentState createState() => AccountFragmentState();
}

class AccountFragmentState extends State<AccountFragment> {

  XFile? imageProfile;
  String? userID;
  String? userImageURL;
  String? imageDB;
  String? userName;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    init();
  }

  void init() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    userID = sharedPreferences.getString('id');
    var deviceID = sharedPreferences.getString('androidID');

    LiveStream().on('UpdateLanguage', (p0) {
      setState(() {});
    });
    LiveStream().on('UpdateTheme', (p0) {
      setState(() {});
    });

    final url = Uri.parse( mBaseUrl +'userDetail/' + userID!);

    final response = await http.get(
      url,
      headers: headers, // Encode the request body to JSON
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        if(deviceID != responseData['user_device']){
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => LoginScreen()), (route) => false);

          // Handle registration error
          Fluttertoast.showToast(
            msg: "Your account has been login from another device.",
            toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
            gravity: ToastGravity.BOTTOM, // Position of the toast message
            timeInSecForIosWeb: 1, // Only for iOS and web
            backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
            textColor: Colors.white, // Text color of the toast
            fontSize: 16.0, // Font size of the text
          );
        }else {
          imageDB = responseData['user_image'];
          userName = responseData['user_name'];

          if(imageDB == null){
            userImageURL = DOMAIN_URL + "/images/profile.png";
          }else {
            userImageURL = DOMAIN_URL + "/images/" + imageDB!;
          }


          setState(() {
            isLoading = false;
          });
        }
      } else {
        // Handle HTTP request error
        Fluttertoast.showToast(
          msg: "There is an error occurred.",
          toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
          gravity: ToastGravity.BOTTOM, // Position of the toast message
          timeInSecForIosWeb: 1, // Only for iOS and web
          backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
          textColor: Colors.white, // Text color of the toast
          fontSize: 16.0, // Font size of the text
        );
      }
    } else {
      // Handle HTTP request error
      Fluttertoast.showToast(
        msg: "Something Went Wrong",
        toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
        gravity: ToastGravity.BOTTOM, // Position of the toast message
        timeInSecForIosWeb: 1, // Only for iOS and web
        backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
        textColor: Colors.white, // Text color of the toast
        fontSize: 16.0, // Font size of the text
      );
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> updateAppStatus(String status) async {
    final response = await http.post(
      Uri.parse(mBaseUrl + 'addAppOnlineStatus/' + userID!),
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      print('App status updated successfully.');
    } else {
      print('Failed to update app status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
      backgroundColor: Color(0xFF253280),
      body: Center(
        child: SpinKitWanderingCubes(
          color: Colors.white,
        ),
      ),
    ):Scaffold(
      appBar: AppBar(title: Text(language.profile)),
      body: Observer(
        builder: (_) => BodyCornerWidget(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: context.height() * 0.1, top: 30),
            child: Column(
              children: [
                commonCachedNetworkImage(userImageURL, height: 90, width: 90, fit: BoxFit.cover, alignment: Alignment.center).cornerRadiusWithClipRRect(50),
                12.height,
                Text(getStringAsync(NAME).validate(), style: boldTextStyle(size: 20)),
                6.height,
                Text(appStore.userEmail.validate(), style: secondaryTextStyle(size: 16)),
                16.height,
                ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    settingItemWidget(Icons.person_outline, language.editProfile, () {
                      EditProfileScreen().launch(context);
                    }),
                    settingItemWidget(Icons.lock_outline, language.changePassword, () {
                      ChangePasswordScreen().launch(context);
                    }),
                    settingItemWidget(Icons.assignment_outlined, language.privacyPolicy, () {
                     commonLaunchUrl(mPrivacyPolicy);
                    }),
                    settingItemWidget(Icons.assignment_outlined, language.termAndCondition, () {
                     commonLaunchUrl(mTermAndCondition);
                    }),
                    // settingItemWidget(Icons.info_outline, language.aboutUs, () {
                    //   AboutUsScreen().launch(context);
                    // }),
                    settingItemWidget(Icons.delete_forever, language.deleteAccount, () {
                      DeleteAccountScreen().launch(context);
                    }),
                    settingItemWidget(
                      Icons.logout,
                      language.logout,
                      () async {
                        await showConfirmDialogCustom(
                          context,
                          primaryColor: colorPrimary,
                          title: language.logoutConfirmationMsg,
                          positiveText: language.yes,
                          negativeText: language.no,
                          onAccept: (c) async{
                            updateAppStatus("OFFLINE");
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => LoginScreen()), (route) => false);
                          },
                        );
                      },
                      isLast: true,
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
