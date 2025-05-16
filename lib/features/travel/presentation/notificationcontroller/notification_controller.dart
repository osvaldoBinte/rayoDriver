import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class NotificationController extends GetxController with WidgetsBindingObserver {
  RxBool tripAccepted = false.obs;
  var lastNotification = Rxn<RemoteMessage>();
  var lastNotificationTitle = ''.obs;
  var lastNotificationBody = ''.obs;
  var lastNotificationType = ''.obs;
  var lastTravelId = ''.obs;
  
  // Agregamos un indicador de procesamiento
  bool _isProcessing = false;
  // Agregamos un indicador de notificación pendiente
  var hasPendingNotification = false.obs;

  static const String _lastNotificationKey = 'lastNotification';
  static const String _lastTravelIdKey = 'lastTravelId';
  static const String _notificationTimestampKey = 'notificationTimestamp';
  
  @override
  void onInit() {
    super.onInit();
    
    // Cargar notificación al inicio
    _initializeNotifications();
    
    WidgetsBinding.instance.addObserver(this);
  }
  
  Future<void> _initializeNotifications() async {
    // Cargar notificación almacenada
    await loadLastNotification();
    
    // Configurar listeners para notificaciones
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('DEBUG: Recibida notificación inicial');
        updateNotification(message);
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      print('DEBUG: Recibida notificación en primer plano');
      updateNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('DEBUG: App abierta desde notificación');
      updateNotification(message);
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App resumed - Verificando notificaciones');
      
      // Cargar notificación con pequeño retraso para asegurar que se procese después
      // de que la interfaz esté completamente inicializada
      Future.delayed(Duration(milliseconds: 500), () async {
        await _checkAndLoadNotification();
      });
    } else if (state == AppLifecycleState.paused) {
      print('DEBUG: App pasó a segundo plano');
    }
  }
  
  Future<void> _checkAndLoadNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Forzar recarga de datos
      
      // Verificar si hay notificación almacenada
      final storedMessage = prefs.getString(_lastNotificationKey);
      final storedTimestamp = prefs.getInt(_notificationTimestampKey) ?? 0;
      
      // Verificar si la notificación se recibió hace menos de 60 segundos
      final now = DateTime.now().millisecondsSinceEpoch;
      final isRecent = (now - storedTimestamp) < 60000; // 60 segundos
      
      if (storedMessage != null && isRecent) {
        print('DEBUG: Encontrada notificación reciente, cargando...');
        await loadLastNotification();
        hasPendingNotification.value = true;
      } else if (storedMessage != null) {
        print('DEBUG: Encontrada notificación antigua (${(now - storedTimestamp) / 1000} seg)');
        await loadLastNotification();
        hasPendingNotification.value = true;
      } else {
        print('DEBUG: No hay notificaciones pendientes');
        hasPendingNotification.value = false;
      }
    } catch (e) {
      print('ERROR en _checkAndLoadNotification: $e');
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Guardar la notificación en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar la notificación completa
      final messageJson = message.toMap();
      await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
      
      // Guardar el ID del viaje como valor separado
      if (message.data.containsKey('travel')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel']);
      } else if (message.data.containsKey('travel_id')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel_id']);
      }
      
      // Guardar timestamp para verificar cuán reciente es la notificación
      await prefs.setInt(_notificationTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('DEBUG: Notificación background guardada (${message.notification?.title})');
      
      // Verificar que se guardó correctamente
      final storedData = prefs.getString(_lastNotificationKey);
      if (storedData != null) {
        print('DEBUG: Verificado: notificación guardada correctamente');
      }
    } catch (e) {
      print('ERROR en background handler: $e');
    }
  }
  
  Future<void> updateNotification(RemoteMessage message) async {
    if (_isProcessing) {
      print('DEBUG: Ya procesando una notificación, esperando...');
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    _isProcessing = true;
    
    try {
      final notification = message.notification;
      if (notification != null) {
        print('DEBUG: Procesando notificación: ${notification.title}');
        
        lastNotificationTitle.value = notification.title ?? 'Notificación';
        lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
        lastNotification.value = message;
        
        // Extraer el ID del viaje (probar ambas claves)
        if (message.data.containsKey('travel')) {
          lastTravelId.value = message.data['travel'];
          print('DEBUG: ID de viaje encontrado (travel): ${lastTravelId.value}');
        } else if (message.data.containsKey('travel_id')) {
          lastTravelId.value = message.data['travel_id'];
          print('DEBUG: ID de viaje encontrado (travel_id): ${lastTravelId.value}');
        } else {
          print('DEBUG: No se encontró ID de viaje. Claves disponibles: ${message.data.keys.join(", ")}');
        }
        
        // Determinar tipo de notificación
        if (notification.title == 'Nuevo precio para tu viaje') {
          lastNotificationType.value = 'new_price';
        } else if (notification.title == 'Tu viaje fue aceptado' ||
                notification.title == "Contraoferta aceptada por el conductor") {
          lastNotificationType.value = 'trip_accepted';
        } else {
          lastNotificationType.value = 'general';
        }
        
        // Marcar que hay notificación pendiente
        hasPendingNotification.value = true;
        
        // Guardar la notificación
        await _saveLastNotification(message);
        
        print('DEBUG: Notificación procesada y guardada correctamente');
      }
    } catch (e) {
      print('ERROR en updateNotification: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> clearNotification() async {
    try {
      lastNotificationTitle.value = '';
      lastNotificationBody.value = '';
      lastNotificationType.value = '';
      lastNotification.value = null;
      lastTravelId.value = '';
      hasPendingNotification.value = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove(_lastTravelIdKey);
      await prefs.remove(_notificationTimestampKey);
      
      print('DEBUG: Notificación limpiada completamente');
    } catch (e) {
      print('ERROR en clearNotification: $e');
    }
  }

  Future<void> _saveLastNotification(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar mensaje completo
      final messageJson = message.toMap();
      await prefs.setString(_lastNotificationKey, jsonEncode(messageJson));
      
      // Guardar ID del viaje por separado
      if (message.data.containsKey('travel')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel']);
      } else if (message.data.containsKey('travel_id')) {
        await prefs.setString(_lastTravelIdKey, message.data['travel_id']);
      }
      
      // Guardar timestamp para verificar cuán reciente es la notificación
      await prefs.setInt(_notificationTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('DEBUG: Notificación guardada en SharedPreferences');
    } catch (e) {
      print('ERROR en _saveLastNotification: $e');
    }
  }

  Future<void> loadLastNotification() async {
    if (_isProcessing) {
      print('DEBUG: Ya procesando, saltando carga');
      return;
    }
    
    _isProcessing = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      // Verificar todas las claves disponibles
      final keys = prefs.getKeys();
      print('DEBUG: Claves en SharedPreferences: $keys');
      
      // Cargar notificación
      final storedMessage = prefs.getString(_lastNotificationKey);
      if (storedMessage != null) {
        try {
          final Map<String, dynamic> messageMap = jsonDecode(storedMessage);
          final message = RemoteMessage.fromMap(messageMap);
          lastNotification.value = message;
          
          final notification = message.notification;
          if (notification != null) {
            lastNotificationTitle.value = notification.title ?? 'Notificación';
            lastNotificationBody.value = notification.body ?? 'Tienes una nueva notificación';
          }
          
          // Intentar cargar ID del viaje de la notificación
          if (message.data.containsKey('travel')) {
            lastTravelId.value = message.data['travel'];
            print('DEBUG: ID de viaje cargado (travel): ${lastTravelId.value}');
          } else if (message.data.containsKey('travel_id')) {
            lastTravelId.value = message.data['travel_id'];
            print('DEBUG: ID de viaje cargado (travel_id): ${lastTravelId.value}');
          } else {
            // Si no está en la notificación, intentar cargar desde almacenamiento separado
            final separateTravelId = prefs.getString(_lastTravelIdKey);
            if (separateTravelId != null && separateTravelId.isNotEmpty) {
              lastTravelId.value = separateTravelId;
              print('DEBUG: ID de viaje cargado (valor separado): ${lastTravelId.value}');
            } else {
              print('DEBUG: No se encontró ID de viaje');
            }
          }
          
          // Verificar timestamp
          final timestamp = prefs.getInt(_notificationTimestampKey) ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          final seconds = (now - timestamp) / 1000;
          
          print('DEBUG: Notificación cargada con éxito (hace $seconds seg)');
          hasPendingNotification.value = true;
        } catch (e) {
          print('ERROR al parsear notificación: $e');
        }
      } else {
        // Si no hay notificación completa, intentar cargar solo el ID
        final travelId = prefs.getString(_lastTravelIdKey);
        if (travelId != null && travelId.isNotEmpty) {
          lastTravelId.value = travelId;
          print('DEBUG: No hay notificación completa, pero se cargó ID: $travelId');
          hasPendingNotification.value = true;
        } else {
          print('DEBUG: No se encontró notificación guardada');
          hasPendingNotification.value = false;
        }
      }
    } catch (e) {
      print('ERROR en loadLastNotification: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  // Método para depuración
  Future<void> forceStoreTestNotification() async {
    try {
      final testData = {
        'notification': {
          'title': 'Notificación de prueba',
          'body': 'Este es un mensaje de prueba'
        },
        'data': {
          'travel': '12345'
        }
      };
      
      final testMessage = RemoteMessage.fromMap(testData);
      await updateNotification(testMessage);
      
      print('DEBUG: Notificación de prueba guardada');
    } catch (e) {
      print('ERROR en forceStoreTestNotification: $e');
    }
  }
}