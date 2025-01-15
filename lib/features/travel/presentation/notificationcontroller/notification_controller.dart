// notificationcontroller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class NotificationController extends GetxController with WidgetsBindingObserver {
  RxBool tripAccepted = false.obs;
  var lastNotification = Rxn<RemoteMessage>();
  var lastNotificationTitle = ''.obs;
  var lastNotificationBody = ''.obs;
  var lastNotificationType = ''.obs;

  static const String _lastNotificationKey = 'lastNotification';


  @override
  void onInit() {
    super.onInit();
    loadLastNotification(); 

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        updateNotification(message);
      }
    });

    // Ya que en onBackgroundMessage sólo guardamos en prefs,
    // al volver a foreground, volveremos a cargar lo que haya allí.
    // onMessage y onMessageOpenedApp ya actualizan normalmente.
    FirebaseMessaging.onMessage.listen((message) {
      updateNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      updateNotification(message);
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
  }

 @override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  if (state == AppLifecycleState.resumed) {
    print('DEBUG: App resumed. Loading last notification from SharedPreferences.');
    await loadLastNotification(); // Forzar la carga desde SharedPreferences
  }
}

  

Future<void> updateNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification != null) {
    lastNotificationTitle.value = notification.title ?? 'Notificación';
    lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
    lastNotification.value = message; // Ensure this is set
print('DEBUG: updateNotification ${notification.title}');
    // Force set notification type
    if (notification.title == 'Nuevo precio para tu viaje') {
      lastNotificationType.value = 'new_price';
    } else if (notification.title == 'Tu viaje fue aceptado' ||
               notification.title == "Contraoferta aceptada por el conductor") {
      lastNotificationType.value = 'trip_accepted';
    } else {
      lastNotificationType.value = 'general';
    }

    await _saveLastNotification(message);
  }

}

  Future<void> clearNotification() async {
    lastNotificationTitle.value = '';
    lastNotificationBody.value = '';
    lastNotificationType.value = '';
    lastNotification.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastNotificationKey);
  }

  Future<void> _saveLastNotification(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final messageJson = message.toMap();
    await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
  }
  Future<void> loadLastNotification() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); 
    final storedMessage = prefs.getString(_lastNotificationKey);

    if (storedMessage != null) {
      final Map<String, dynamic> messageMap = jsonDecode(storedMessage);
      final message = RemoteMessage.fromMap(messageMap);
      lastNotification.value = message; 
      print('DEBUG: Loaded last notification - Title: ${message.notification?.title}, Body: ${message.notification?.body}');
    } else {
      print('DEBUG: No stored notification found in SharedPreferences.');
    }
  } catch (e) {
    print('ERROR in loadLastNotification: $e');
  }
}


}

