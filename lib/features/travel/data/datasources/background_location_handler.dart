import 'dart:async';
import 'dart:isolate';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHandler {
  static final loc.Location _location = loc.Location();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<loc.LocationData>? _locationSubscription;
  static final socketDriver = SocketDriverDataSourceImpl();
  static bool _isTracking = false;
  static int? _notificationId;

  static Future<void> initialize() async {
    try {
      // Configuración de notificaciones
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _notifications.initialize(initializationSettings);

      // Crear canal de notificaciones silencioso
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'location_service',
        'Location Service',
        description: 'Shows when tracking location',
        importance: Importance.low, // Cambiado a low para reducir la intrusión
        playSound: false,  // Deshabilitar sonido
        enableVibration: false,  // Deshabilitar vibración
        showBadge: false,  // No mostrar badge
      );

      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

      // Configuración restante...
      await _setupLocationService();
    } catch (e) {
      print('Error inicializando LocationHandler: $e');
    }
  }

  static Future<void> _setupLocationService() async {
    var locationStatus = await Permission.location.request();
    if (locationStatus.isGranted) {
      var backgroundStatus = await Permission.locationAlways.request();
      if (backgroundStatus.isGranted) {
        await _location.changeSettings(
          accuracy: loc.LocationAccuracy.high,
          interval: 1000,
          distanceFilter: 0,
        );
        await _location.enableBackgroundMode(enable: true);
      }
    }
  }

  static Future<void> startTracking(String travelId) async {
    if (_isTracking) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_travel_id', travelId);

    // Conectar socket
    socketDriver.connect();
    socketDriver.joinTravel(travelId);

    // Configuración de notificación silenciosa
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'location_service',
      'Location Service',
      channelDescription: 'Shows when tracking location',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.private,
    );

    // Mostrar notificación inicial
    if (_notificationId == null) {
      _notificationId = 888;
      await _notifications.show(
        _notificationId!,
        'Rastreo activo',
        'Enviando ubicación en tiempo real',
        NotificationDetails(android: androidDetails),
      );
    }

    // Iniciar seguimiento de ubicación
    _locationSubscription = _location.onLocationChanged.listen((locationData) async {
      // Actualizar socket
      socketDriver.updateLocation(
        travelId,
        {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'speed': locationData.speed,
          'bearing': locationData.heading,
        },
      );

      // Actualizar texto de notificación sin sonido
      await _notifications.show(
        _notificationId!,
        'Rastreo activo',
        'Velocidad: ${((locationData.speed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
        NotificationDetails(android: androidDetails),
      );
    });

    _isTracking = true;
  }

  static Future<void> stopTracking() async {
    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_travel_id');

      socketDriver.disconnect();
      
      if (_notificationId != null) {
        await _notifications.cancel(_notificationId!);
        _notificationId = null;
      }
    } catch (e) {
      print('Error al detener el tracking: $e');
    }
  }

  static bool get isTracking => _isTracking;
}