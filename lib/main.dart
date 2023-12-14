import 'package:flutter/material.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/home_page.dart';
import 'package:laporcepat/laporan_detail_page.dart';
import 'package:laporcepat/login_page.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseMessaging.instance.subscribeToTopic('all');
  FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  runApp(const MyApp());
}

//final audioPlayer = AudioPlayer();

Future<void> _backgroundHandler(RemoteMessage message) async {
  //playSound(message.data['status'] + '.mp3');
  // _showLocalNotification(message);
  debugPrint("Handling background message: ${message.data}");
}

// Future<void> playSound(status) async {
//   try {
//     await audioPlayer.play(AssetSource('sound/$status'));
//   } catch (e) {
//     debugPrint('Error playing audio: $e');
//   }
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DataUsers? loadedLogin;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
    _initializeLocalNotification();
  }

  Future<void> _configureFCMListeners() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //playSound(message.data['status'] + '.mp3');
      if (loadedLogin?.userId != message.data['userId']) {
        if (int.parse(message.data['type']) == 1) {
          _showLocalNotification(message, true);
        } else {
          _showLocalNotification(message, false);
        }
      }
      // Handle incoming data message when the app is in the foreground
      debugPrint("Data message received: ${message.data}");
    });
  }

  Future<void> _showLocalNotification(
      RemoteMessage message, bool soundEffect) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    late AndroidNotificationDetails androidPlatformChannelSpecifics;
    if (soundEffect == true) {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'laporcepat', 'laporcepat',
          channelDescription: 'laporcepat',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(message.data['status']),
          icon: '@mipmap/ic_launcher',
          playSound: true,
          priority: Priority.high);
    } else {
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'laporcepats', 'laporcepats',
          channelDescription: 'laporcepats',
          importance: Importance.high,
          icon: '@mipmap/ic_launcher',
          playSound: false,
          priority: Priority.high);
    }
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      message.data['title'],
      message.data['body'],
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint("Data message opened: ${message.data}");
    if (message.data.containsKey('laporanId')) {
      navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (context) =>
              LaporanDetailPage(laporanId: message.data['laporanId'])));
    }
  }

  Future<void> _initializeFCM() async {
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.getToken().then((token) {
      debugPrint("FCM Token: $token");
      // Store the token on your server for sending targeted messages
    });
  }

  Future<void> _initializeLocalNotification() async {
    // Create a notification channel
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
            'laporcepat', // Channel ID
            'laporcepat', // Channel Name
            description: 'laporcepat', // description
            importance: Importance.high,
            playSound: true);

    // Register the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      String trimmedPayload = payload!.substring(1, payload.length - 1);

      // Split the string by commas to create a List of key-value pairs
      List<String> keyValuePairs = trimmedPayload.split(', ');

      // Create a Map from the key-value pairs
      Map<String, dynamic> payloadMap = {};
      for (String pair in keyValuePairs) {
        List<String> parts = pair.split(': ');
        String key = parts[0];
        String value = parts[1];
        // Remove leading and trailing quotes for string values
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
        payloadMap[key] = value;
      }
      if (payloadMap.containsKey('laporanId')) {
        navigatorKey.currentState!.push(MaterialPageRoute(
            builder: (context) =>
                LaporanDetailPage(laporanId: payloadMap['laporanId'])));
      }
    }
  }

  Future<DataUsers?> checkSharedPreferences() async {
    StorageService storageService = StorageService();
    return storageService.loadData('dataLogin');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lapor Cepat',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<DataUsers?>(
        future:
            checkSharedPreferences(), // Check if the user is already logged in
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // If the Future is still running, show a loading indicator
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If there's an error, display an error message
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.data!.name != '') {
            // If the data has been successfully loaded, use it
            loadedLogin = snapshot.data;
            _configureFCMListeners();
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
      // routes: {
      //   '/home': (context) => const HomePage(),
      //   '/login': (context) => const LoginPage(),
      // },
      // initialRoute: '/home'
    );
  }
}
