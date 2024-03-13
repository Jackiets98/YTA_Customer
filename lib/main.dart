import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:yes_sir/main/screens/LoginScreen.dart';
import '../main/models/models.dart';
import '../main/screens/SplashScreen.dart';
import '../main/utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';
import 'AppTheme.dart';
import 'main/services/NotificationService.dart';
import 'main/language/AppLocalizations.dart';
import 'main/language/BaseLanguage.dart';
import 'main/models/FileModel.dart';
import 'main/screens/NoInternetScreen.dart';
import 'main/store/AppStore.dart';
import 'main/utils/Common.dart';
import 'main/utils/DataProviders.dart';
import 'package:http/http.dart' as http;

AppStore appStore = AppStore();
late BaseLanguage language;

NotificationService notificationService = NotificationService();
late List<FileModel> fileList = [];
bool isCurrentlyOnNoInternet = false;

bool mIsEnterKey = false;
String mSelectedImage = "assets/default_wallpaper.png";

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initialize(aLocaleLanguageList: languageList());

  appStore.setLogin(getBoolAsync(IS_LOGGED_IN), isInitializing: true);
  appStore.setUserEmail(getStringAsync(USER_EMAIL), isInitialization: true);
  appStore.setUserProfile(getStringAsync(USER_PROFILE_PHOTO), isInitializing: true);
  appStore.setLanguage(getStringAsync(SELECTED_LANGUAGE_CODE, defaultValue: defaultLanguage));
  FilterAttributeModel? filterData = FilterAttributeModel.fromJson(getJSONAsync(FILTER_DATA));
  appStore.setFiltering(filterData.orderStatus != null || !filterData.fromDate.isEmptyOrNull || !filterData.toDate.isEmptyOrNull);

  int themeModeIndex = getIntAsync(THEME_MODE_INDEX);
  if (themeModeIndex == appThemeMode.themeModeLight) {
    appStore.setDarkMode(false);
  } else if (themeModeIndex == appThemeMode.themeModeDark) {
    appStore.setDarkMode(true);
  }
  // await OneSignal.shared.setAppId(mOneSignalAppId);
  //
  // saveOneSignalPlayerId();
  // OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult notification) async {
  //   var notId = notification.notification.additionalData!["id"];
  //   if (notId != null) {
  //     if (!appStore.isLoggedIn) {
  //       LoginScreen().launch(getContext);
  //     } else if (notId.toString().contains('CHAT')) {
  //
  //     } else {
  //       // OrderDetailScreen(orderId: int.parse(notId.toString())).launch(getContext);
  //     }
  //   }
  // });
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver{
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  String? userID;
  String? userName;
  String? androidID;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    init();

    // Obtain and send the FCM token to the backend
    // _getAndSendFCMToken();

    // Handle incoming notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message data: ${message.data}");
      print("Message notification: ${message.notification}");

      // Handle the incoming message as needed, e.g., display a notification
      _showNotification(message);
    });

      getID().whenComplete(() => {
        // Update app status to "ONLINE" when the app starts
        updateAppStatus('ONLINE')
      });
  }

  Future getID() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    userID = sharedPreferences.getString('id');
    userName = sharedPreferences.getString('name');
    androidID = sharedPreferences.getString('androidID');
  }


  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      updateAppStatus("OFFLINE");
    }else if(state == AppLifecycleState.resumed){
      updateAppStatus('ONLINE');
    }
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

  // Future<void> _getAndSendFCMToken() async {
  //   String? token = await _firebaseMessaging.getToken();
  //   print("FCM Token: $token");
  //
  //   // Send the FCM token to the Laravel backend
  //   final url = 'https://app.yessirgps.com/api/registering-fcm-token';
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse(url),
  //       body: {
  //         'device_token': token,
  //       },
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print('FCM Token registered successfully with Laravel backend');
  //     } else {
  //       print('Failed to register FCM Token with Laravel backend');
  //     }
  //   } catch (e) {
  //     print('Error sending FCM Token: $e');
  //   }
  // }

  void _showNotification(RemoteMessage message) {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    final String title = message.notification?.title ?? 'Title';
    final String body = message.notification?.body ?? 'Body';

    flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics,
      payload: 'item x', // Optional payload
    );
  }

  void init() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((e) {
      if (e == ConnectivityResult.none) {
        log('not connected');
        isCurrentlyOnNoInternet = true;
        push(NoInternetScreen());
      } else {
        if (isCurrentlyOnNoInternet) {
          pop();
          isCurrentlyOnNoInternet = false;
          toast(language.internetIsConnected);
        }
        log('connected');
      }
    });

    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void setState(VoidCallback fn) {
    _connectivitySubscription.cancel();
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: MyBehavior(),
            child: child!,
          );
        },
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: SplashScreen(),
        supportedLocales: LanguageDataModel.languageLocales(),
        localizationsDelegates: [AppLocalizations(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        localeResolutionCallback: (locale, supportedLocales) => locale,
        locale: Locale(appStore.selectedLanguage.validate(value: defaultLanguage)),
      );
    });
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
