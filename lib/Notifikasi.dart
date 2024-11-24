import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotifikasiHandler {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> inisialisasiNotifikasi(BuildContext context) async {
    // Inisialisasi lokal notifikasi
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);

    await _localNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            // Handle payload jika diperlukan
            print("Payload: ${details.payload}");
          }
        });

    // Izin untuk notifikasi
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Izin notifikasi diberikan.");
    } else {
      print("Izin notifikasi ditolak.");
    }

    // Mendengarkan pesan masuk
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan masuk: ${message.notification?.title}");
      tampilkanNotifikasi(message);
    });

    // Mendengarkan ketika notifikasi ditekan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notifikasi ditekan: ${message.notification?.title}");
    });

    // Mengambil token untuk perangkat
    String? token = await _fcm.getToken();
    print("Token FCM: $token");
  }

  static Future<void> tampilkanNotifikasi(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Channel ini digunakan untuk notifikasi penting.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}