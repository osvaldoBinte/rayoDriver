// notification_controller.dart
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
  var lastTravelId = ''.obs; // Agregamos esta variable para almacenar el ID

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
      await loadLastNotification();
    }
  }

  Future<void> updateNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      lastNotificationTitle.value = notification.title ?? 'Notificación';
      lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
      lastNotification.value = message;
      
      // Extraer el ID del viaje de los datos de la notificación
      if (message.data.containsKey('travel_id')) {
        lastTravelId.value = message.data['travel_id'];
        print('DEBUG: Travel ID from notification: ${lastTravelId.value}');
      }

      // Determinar el tipo de notificación
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
    lastTravelId.value = ''; // Limpiar también el ID
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
        
        // Cargar el ID del viaje desde los datos almacenados
        if (message.data.containsKey('travel_id')) {
          lastTravelId.value = message.data['travel_id'];
        }
        
        print('DEBUG: Loaded last notification - Title: ${message.notification?.title}, Body: ${message.notification?.body}, TravelID: ${lastTravelId.value}');
      } else {
        print('DEBUG: No stored notification found in SharedPreferences.');
      }
    } catch (e) {
      print('ERROR in loadLastNotification: $e');
    }
  }
}
