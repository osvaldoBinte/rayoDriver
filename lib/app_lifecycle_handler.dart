import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler> with WidgetsBindingObserver {
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  final NotificationController notificationController = Get.find<NotificationController>();
  final TravelByIdAlertGetx travelByIdController = Get.find<TravelByIdAlertGetx>();
  
  static const String _lastNotificationKey = 'lastNotification';
  bool _isUpdating = false;
  int _lastUpdateTimestamp = 0;
  
  // Variable para controlar si hay un QuickAlert abierto
  bool _isQuickAlertOpen = false;
  String? _currentAlertType;
  
  // Mapa para controlar cuántos alertas se han mostrado por tipo de notificación
  final Map<String, int> _alertCountByType = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    ever(notificationController.hasPendingNotification, (hasPending) {
      if (hasPending) {
        print('DEBUG: Se detectó notificación pendiente, programando actualización');
        _scheduleDataUpdate();
      }
    });
    
    ever(notificationController.lastTravelId, (travelId) {
      if (travelId.isNotEmpty) {
        print('DEBUG: ID de viaje cambiado a: $travelId');
        _scheduleDataUpdate();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationController.hasPendingNotification.value) {
        print('DEBUG: Notificación pendiente detectada en inicio, programando actualización');
        _scheduleDataUpdate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _scheduleDataUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTimestamp < 2000) {
      print('DEBUG: Omitiendo actualización duplicada (demasiado cercana a la anterior)');
      return;
    }
    
    Future.delayed(Duration(milliseconds: 300), () {
      _handleNotificationUpdate();
    });
  }

  // Método adaptado de NotificationService para esperar a que todas las operaciones completen
  Future<void> _waitForOperationsToComplete({
    required CurrentTravelGetx currentTravelGetx,
    required TravelByIdAlertGetx travelByIdController,
    required TravelsAlertGetx travelAlertGetx,
    required int? travelId,
    bool skipTravelById = false,
  }) async {
    final currentTravelCompleter = Completer();
    final travelByIdCompleter = Completer();
    final travelAlerCompleter = Completer();

    // Observador para viaje actual
    final currentDisposer = ever(currentTravelGetx.state, (state) {
      if (state is TravelAlertLoaded || state is TravelAlertFailure) {
        if (!currentTravelCompleter.isCompleted) {
          currentTravelCompleter.complete();
        }
      }
    });

    // Observador para viaje específico por ID
    final byIdDisposer = ever(travelByIdController.state, (state) {
      if (state is TravelByIdAlertLoaded || state is TravelByIdAlertFailure) {
        if (!travelByIdCompleter.isCompleted) {
          travelByIdCompleter.complete();
        }
      }
    });

    // Observador para todos los viajes
    final alertDisposer = ever(travelAlertGetx.state, (state) {
      if (state is TravelsAlertLoaded || state is TravelsAlertFailure) {
        if (!travelAlerCompleter.isCompleted) {
          travelAlerCompleter.complete();
        }
      }
    });

    // Iniciar las peticiones
    currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
    
    // Solo consultamos por ID si no estamos explícitamente saltándonos esta operación
    // y si tenemos un ID válido
    if (!skipTravelById && travelId != null) {
      print('DEBUG: Solicitando detalles para viaje ID: $travelId');
      travelByIdController.fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: travelId));
    } else {
      print('DEBUG: Omitiendo consulta de viaje por ID');
      travelByIdCompleter.complete(); // Si no hay ID o se debe omitir, completar directamente
    }
    
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

    // Esperar a que todas terminen
    await Future.wait([
      currentTravelCompleter.future,
      travelByIdCompleter.future,
      travelAlerCompleter.future
    ]);
    
    // Limpiar los observadores para evitar memory leaks
    currentDisposer();
    byIdDisposer();
    alertDisposer();
  }

  // Muestra alertas según los títulos de notificación
  void _processNotificationAlerts(String? title, String? body) {
    if (title == null || body == null) return;
    
    print('DEBUG: Procesando alerta para notificación: $title');
    
    // Omitir completamente la notificación "Nuevo viaje!!"
    if (title == 'Nuevo viaje!!') {
      print('DEBUG: Ignorando notificación "Nuevo viaje!!" según lo solicitado');
      return; // Simplemente retornar sin hacer nada
    }
    
    if (title == 'Propuesta de viaje rechazada') {
      _showAlertWithCheck(title, body, 'info');
    } else if (body == 'El cliente ha aceptado la propuesta para el viaje.' || 
              title == "Contraoferta aceptada por el cliente") {
      _showAlertWithCheck(title, body, 'success');
    }
  }

  void _showNewTravelAlert(String title, String body, int? travelId) {
    // Simplemente registrar que se intentó mostrar la alerta pero no hacer nada
    print('DEBUG: Se intentó mostrar alerta de Nuevo Viaje pero está desactivada');
    // No incrementamos el contador ni mostramos nada
    return;
  }
  
  void _showNewTravelAlertInternal(String title, String body, int? travelId, int count) {
    // Este método ya no se usa pero lo mantenemos por compatibilidad
    print('DEBUG: _showNewTravelAlertInternal no se utiliza más');
    return;
  }
  
  // Método centralizado para mostrar alertas controlando duplicados
  void _showAlertWithCheck(String title, String body, String type) {
    // Incrementar contador para este tipo de alerta
    _alertCountByType[title] = (_alertCountByType[title] ?? 0) + 1;
    int currentCount = _alertCountByType[title]!;
    
    print('DEBUG: Mostrando alerta: $title (contador: $currentCount)');
    
    // Si ya hay un diálogo abierto del mismo tipo
    if (_isQuickAlertOpen && _currentAlertType == title) {
      print('DEBUG: Ya hay un diálogo abierto para $title, cerrándolo primero');
      // Cerrar el diálogo actual si podemos
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // Esperar un momento antes de mostrar el nuevo
      Future.delayed(Duration(milliseconds: 300), () {
        _showQuickAlertInternal(title, body, type, currentCount);
      });
    } else {
      // Si no hay diálogo abierto o es de otro tipo, mostrar directamente
      _showQuickAlertInternal(title, body, type, currentCount);
    }
  }
  
  // Implementación interna para mostrar el diálogo
  void _showQuickAlertInternal(String title, String body, String type, int count) {
    try {
      _isQuickAlertOpen = true;
      _currentAlertType = title;
      
      // En el caso de múltiples alertas del mismo tipo, actualizar el cuerpo
      String displayBody = count > 1 
          ? '$body\n\n(Notificación $count)' 
          : body;
      
      final context = Get.context;
      if (context == null) {
        print('DEBUG: Contexto no disponible para mostrar QuickAlert');
        _isQuickAlertOpen = false;
        return;
      }
      
      // Usar un Future.delayed para asegurar que se actualiza el estado en caso de cierre por back button
      Future.delayed(Duration(milliseconds: 100), () {
        QuickAlert.show(
          context: context,
          type: type == 'success' ? QuickAlertType.success : QuickAlertType.info,
          title: title,
          text: displayBody,
          confirmBtnText: 'OK',
          barrierDismissible: true, // Permitir cerrar tocando fuera del diálogo
          onConfirmBtnTap: () async {
            // Marcar como cerrado
            _isQuickAlertOpen = false;
            _currentAlertType = null;
            
            if (title == 'Nuevo precio del viaje' || title == 'Propuesta de viaje rechazada') {
              await AuthService().clearCurrenttravel();
              await Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
            } else if (title == 'Contraoferta aceptada por el cliente' || 
                      body.contains('El cliente ha aceptado la propuesta para el viaje')) {
              await AuthService().clearCurrenttravel();
              currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
              navigateToHome();
            } else {
              Navigator.of(context).pop();
            }
          },
        ).then((_) {
          // Se ejecuta cuando el diálogo se cierra por cualquier razón
          _isQuickAlertOpen = false;
          _currentAlertType = null;
          print('DEBUG: QuickAlert cerrado para: $title');
        });
      });
      
      // Configurar un timer para cerrar automáticamente el diálogo si permanece abierto demasiado tiempo
      Timer(Duration(seconds: 30), () {
        if (_isQuickAlertOpen && _currentAlertType == title && Get.isDialogOpen == true) {
          print('DEBUG: Cerrando automáticamente QuickAlert después de timeout para: $title');
          Get.back();
          _isQuickAlertOpen = false;
          _currentAlertType = null;
        }
      });
      
    } catch (e) {
      print('ERROR al mostrar QuickAlert: $e');
      _isQuickAlertOpen = false;
      _currentAlertType = null;
    }
  }

  // Navegar a la página principal
  void navigateToHome() {
    Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
  }

  Future<void> _handleNotificationUpdate() async {
    if (_isUpdating) {
      print('DEBUG: Ya se está ejecutando una actualización, saltando esta petición');
      return;
    }
    
    _isUpdating = true;
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
    
    try {
      // Obtener tipo de notificación y ID de viaje
      final notificationInfo = await _getNotificationInfo();
      final title = notificationInfo['title'];
      final body = notificationInfo['body'];
      final travelId = int.tryParse(notificationController.lastTravelId.value);
      
      // Ignorar completamente la notificación "El viaje ha sido calificado"
      if (title == "El viaje ha sido calificado") {
        print('DEBUG: Ignorando notificación "El viaje ha sido calificado" según lo solicitado');
        // Limpiamos la notificación sin hacer ninguna actualización
        await _clearLastNotification();
        _isUpdating = false;
        return;
      }
      
      // Ignorar completamente la notificación "Nuevo viaje!!"
      if (title == "Nuevo viaje!!") {
        print('DEBUG: Ignorando notificación "Nuevo viaje!!" según lo solicitado');
        // No hacemos nada especial, solo actualizamos datos si es necesario
        await _waitForOperationsToComplete(
          currentTravelGetx: currentTravelGetx,
          travelByIdController: travelByIdController,
          travelAlertGetx: travelAlertGetx,
          travelId: null,
          skipTravelById: true
        );
      } 
      // Si es una notificación de rechazo, NO actualizar los detalles del viaje específico
      else if (title == "Propuesta de viaje rechazada") {
        print('DEBUG: Notificación de rechazo detectada, omitiendo fetchCoDetails para viaje específico');
        
        await _clearTravelData();
        
        // Solo actualizar datos generales
        await _waitForOperationsToComplete(
          currentTravelGetx: currentTravelGetx,
          travelByIdController: travelByIdController,
          travelAlertGetx: travelAlertGetx,
          travelId: null,
          skipTravelById: true
        );
        
        // Mostrar la alerta correspondiente
        _showAlertWithCheck(title!, body!, 'info');
      } else {
        // Para otros tipos de notificación, actualizar todo normalmente
        await _waitForOperationsToComplete(
          currentTravelGetx: currentTravelGetx,
          travelByIdController: travelByIdController,
          travelAlertGetx: travelAlertGetx,
          travelId: travelId,
          skipTravelById: false
        );
        
        print('DEBUG: Datos actualizados correctamente, procesando alertas');
        
        // Una vez que tengamos todos los datos, mostrar las alertas correspondientes
        _processNotificationAlerts(title, body);
      }
      
      // Limpiamos la notificación después de procesar
      await _clearLastNotification();
    } catch (e) {
      print('ERROR durante la actualización: $e');
      CustomSnackBar.showError('', 'Error al procesar la notificación: $e');
    } finally {
      _isUpdating = false;
    }
  }

  // Método mejorado para obtener información de la notificación
  Future<Map<String, String?>> _getNotificationInfo() async {
    Map<String, String?> result = {
      'title': null,
      'body': null,
    };
    
    try {
      // Primero verificar en el controlador de notificaciones
      if (notificationController.lastNotification.value != null) {
        final notification = notificationController.lastNotification.value!;
        result['title'] = notification.notification?.title;
        result['body'] = notification.notification?.body;
        return result;
      }
      
      // Si no está disponible en el controlador, intentar obtenerlo de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final notificationString = prefs.getString(_lastNotificationKey);
      
      if (notificationString != null && notificationString.isNotEmpty) {
        try {
          final notificationData = Map<String, dynamic>.from(
            (notificationString.startsWith('{')) 
              ? Map<String, dynamic>.from(await json.decode(notificationString))
              : {}
          );
          
          // Intenta obtener el título y cuerpo de diferentes ubicaciones posibles
          result['title'] = notificationData['notification']?['title'] ?? 
                 notificationData['title'] ?? 
                 notificationData['data']?['title'];
                 
          result['body'] = notificationData['notification']?['body'] ?? 
                 notificationData['body'] ?? 
                 notificationData['data']?['body'];
        } catch (e) {
          print('ERROR al parsear notificación guardada: $e');
        }
      }
      
      return result;
    } catch (e) {
      print('ERROR al obtener información de notificación: $e');
      return result;
    }
  }

  // Método para limpiar los datos del viaje
  Future<void> _clearTravelData() async {
    try {
      print('DEBUG: Limpiando datos de viaje en SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('getalltravelid');
      // Puedes agregar aquí cualquier otra clave que necesites limpiar
    } catch (e) {
      print('ERROR al limpiar datos de viaje: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App regresó a primer plano');
      
      // Al volver a primer plano, esperamos a que la UI se estabilice
      // y luego verificamos si hay notificaciones pendientes
      Future.delayed(Duration(milliseconds: 500), () async {
        if (notificationController.hasPendingNotification.value || await _checkForPendingNotification()) {
          print('DEBUG: Se encontró notificación pendiente al volver a primer plano');
          _scheduleDataUpdate();
        } else {
          print('DEBUG: No hay notificaciones pendientes al volver a primer plano');
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // Al pasar a segundo plano, reiniciar contadores de alertas
      _alertCountByType.clear();
      _isQuickAlertOpen = false;
      _currentAlertType = null;
    }
  }
  
  Future<bool> _checkForPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final storedMessage = prefs.getString(_lastNotificationKey);
      
      // Si hay un mensaje almacenado, verificar si es "El viaje ha sido calificado"
      if (storedMessage != null && storedMessage.isNotEmpty) {
        try {
          final notificationData = Map<String, dynamic>.from(
            (storedMessage.startsWith('{')) 
              ? Map<String, dynamic>.from(await json.decode(storedMessage))
              : {}
          );
          
          final title = notificationData['notification']?['title'] ?? 
                 notificationData['title'] ?? 
                 notificationData['data']?['title'];
                 
          // Si es "El viaje ha sido calificado", limpiar la notificación y devolver false
          if (title == "El viaje ha sido calificado") {
            print('DEBUG: Ignorando notificación pendiente "El viaje ha sido calificado"');
            await _clearLastNotification();
            return false;
          }
        } catch (e) {
          print('ERROR al parsear notificación guardada en checkForPendingNotification: $e');
        }
      }
      
      return storedMessage != null;
    } catch (e) {
      print('ERROR al verificar notificación pendiente: $e');
      return false;
    }
  }

  Future<void> _clearLastNotification() async {
    try {
      await notificationController.clearNotification();
      print('DEBUG: Notificación limpiada después de procesar');
    } catch (e) {
      print('ERROR al limpiar notificación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}