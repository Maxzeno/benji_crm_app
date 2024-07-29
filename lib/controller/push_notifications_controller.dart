import 'dart:io';

import 'package:benji_aggregator/controller/api_processor_controller.dart';
import 'package:benji_aggregator/controller/user_controller.dart';
import 'package:benji_aggregator/services/api_url.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MyPushNotification {
  final firebase = FirebaseMessaging.instance;

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotify() async {
    await firebase.requestPermission();

    var token = await firebase.getToken();

    if (token != null) {
      try {
        final user = UserController.instance.user.value;
        var url = Api.baseUrl + Api.createPushNotification;

        Map data = {"user_id": user.id, "token": token};

        http.Response? response =
            await HandleData.postApi(url, user.token, data);

        debugPrint("Response status code: ${response?.statusCode}");
        if (response?.statusCode == 200) {
          debugPrint("Response body: ${response?.body}");
        } else {
          debugPrint("Response body: ${response?.body}");
        }
      } on SocketException {
        ApiProcessorController.errorSnack("Please connect to the internet");
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> setup() async {
    const androidInitializationSetting =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSetting = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
        android: androidInitializationSetting, iOS: iosInitializationSetting);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void showLocalNotification(String title, String body) {
    const androidNotificationDetail = AndroidNotificationDetails(
      '0', // channel Id
      'general', // channel Name,
      sound: RawResourceAndroidNotificationSound('benji'),
    );
    const iosNotificatonDetail = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      iOS: iosNotificatonDetail,
      android: androidNotificationDetail,
    );
    _flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  Future<void> showForegroundNotification() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await firebase.setForegroundNotificationPresentationOptions(
        alert: true, sound: true);
  }

  Future messaging() async {
    firebase.getInitialMessage().then((message) {
      if (message != null) {
        showLocalNotification(
          message.notification?.title ?? "",
          message.notification?.body ?? "",
        );
      }
    });

    // To initialise when app is not terminated
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        showLocalNotification(
          message.notification?.title ?? "",
          message.notification?.body ?? "",
        );
      }
    });

    FirebaseMessaging.onBackgroundMessage((message) async {
      showLocalNotification(
        message.notification?.title ?? "",
        message.notification?.body ?? "",
      );
    });

    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   // do something like navigate to a page
    // });
  }
}
