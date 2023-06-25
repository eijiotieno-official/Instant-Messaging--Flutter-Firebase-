import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_chat/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_chat/services/auth_services.dart';
import 'package:my_chat/services/notification_services.dart';

import 'pages/home.dart';
import 'package:flutter/services.dart';

Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage remoteMessage) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //DISPLAY NOTIFICATION
  await NotificationServices.showNotification(remoteMessage: remoteMessage);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationServices.initializeLocalNotification();
  await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: "high_importance_channel");
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage remoteMessage) async {
      await Fluttertoast.showToast(
        msg: "@${remoteMessage.data['name']} : ${remoteMessage.data['text']}",
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
      );
    },
  );
  runApp(const MyApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String homeRoute = '/home';

  @override
  void initState() {
    NotificationServices.startListeningNotificationEvents();
    super.initState();
  }

  List<Route<dynamic>> onGenerateInitialRoutes(String initialRouteName) {
    List<Route<dynamic>> pageStack = [];

    pageStack.add(MaterialPageRoute(builder: (_) => const CheckAuthStatus()));

    if (NotificationServices.initialAction != null) {
      pageStack.add(MaterialPageRoute(
          builder: (_) => Home(
                receivedAction: NotificationServices.initialAction,
              )));
    }

    return pageStack;
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        ReceivedAction receivedAction = settings.arguments as ReceivedAction;
        return MaterialPageRoute(
            builder: (_) => Home(
                  receivedAction: receivedAction,
                ));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      onGenerateInitialRoutes: onGenerateInitialRoutes,
      onGenerateRoute: onGenerateRoute,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white.withOpacity(0.9),
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.black.withOpacity(0.5),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class CheckAuthStatus extends StatefulWidget {
  const CheckAuthStatus({super.key});

  @override
  State<CheckAuthStatus> createState() => _CheckAuthStatusState();
}

class _CheckAuthStatusState extends State<CheckAuthStatus> {
  AuthServices authServices = AuthServices();
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) async {
        if (user == null) {
          //AUTHENTICATE USER
          await authServices.authenticateUser(context: context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const Home(receivedAction: null);
              },
            ),
          );
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
