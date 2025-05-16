import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
import 'package:rayo_taxi/features/travel/data/datasources/background_location_handler.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/direction_step.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/DriverArrival/driverArrival_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/EndTravel/endTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/StartTravel/startTravel_getx.dart';
import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/cancelTravel/cancelTravel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/rejectTravelOffer/reject_travel_offer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel_id/map_data_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'dart:math' show asin, atan2, cos, pi, sin, sqrt;
import 'dart:math' show sin, cos, sqrt, atan2, pi, max;
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

enum TravelStage { heLlegado, iniciarViaje, terminarViaje }

class TravelRouteController extends GetxController with WidgetsBindingObserver {
  final List<TravelAlertModel> travelList;
  RxBool useMapbox = true.obs;

  TravelRouteController({required this.travelList});
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();
  RxBool isLoadingNavigation = false.obs;
  Rx<TravelStage> travelStage = TravelStage.heLlegado.obs;
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Rx<LatLng?> startLocation = Rx<LatLng?>(null);
  Rx<LatLng?> endLocation = Rx<LatLng?>(null);
  Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  RxBool journeyStarted = false.obs;
  RxBool journeyCompleted = false.obs;
  RxBool hellegado = false.obs;
  RxBool isIdStatusSix = false.obs;
  RxString waitingFor = ''.obs;
  final ChangeavailabilityGetx _driverGetx = Get.find<ChangeavailabilityGetx>();
  final double driverZoomLevel = 20;
  final double navigationZoom = 15.0;
  final double navigationTilt = 60.0;
  RxBool isFollowingDriver = true.obs;
  RxBool isLoadingStartJourney = false.obs;
  final RxBool startIconLoaded = false.obs;
  final RxBool destinationIconLoaded = false.obs;
  final RxBool driverIconLoaded = false.obs;
  
  GoogleMapController? mapController;
  final LatLng center = const LatLng(20.676666666667, -103.39182);

  StreamSubscription<Position>? positionStreamSubscription;
  LatLng? lastDriverPositionForRouteUpdate;

  final StarttravelGetx startTravelController = Get.find<StarttravelGetx>();
  final EndtravelGetx endTravelController = Get.find<EndtravelGetx>();
  final DriverarrivalGetx driverArrivalGetx = Get.find<DriverarrivalGetx>();
  final CanceltravelGetx _cancelTravel = Get.find<CanceltravelGetx>();
  final RejectTravelOfferGetx rejectTravelOfferGetx =
      Get.find<RejectTravelOfferGetx>();
  LatLng? _lastKnownDriverPosition;

  RxBool shouldTrackDriver = false.obs;
  Rx<BitmapDescriptor> startIcon = BitmapDescriptor.defaultMarker.obs;
  Rx<BitmapDescriptor> destinationIcon = BitmapDescriptor.defaultMarker.obs;
  Rx<BitmapDescriptor> driverIcon = BitmapDescriptor.defaultMarker.obs;
  RxBool markersLoaded = false.obs;
  Rx<DirectionStep?> currentStep = Rx<DirectionStep?>(null);
  RxList<DirectionStep> routeSteps = <DirectionStep>[].obs;
  final MapDataController driverTravelLocalDataSource = Get.find<MapDataController>();
  late SocketDriverDataSourceImpl socketDriver;
  static const String _isolateName = 'locationIsolate';
  RxBool isBackgroundServiceRunning = false.obs;
  
  // Variables para el control de socket
  RxBool _isSocketConnected = false.obs;
  RxBool _isRoomJoined = false.obs;
  RxBool _isSocketOperationInProgress = false.obs;
  int _connectionAttempts = 0;
  Timer? _socketReconnectTimer;
  DateTime? _lastUpdateTime;
  bool _forceReconnectOnNextResume = false;

  @override
  void onInit() async {
    super.onInit();
    
    WidgetsBinding.instance.addObserver(this);
    
    final prefs = await SharedPreferences.getInstance();
    useMapbox.value = prefs.getBool('use_mapbox') ?? true;
    _setupLocationIsolateListener();

    await _loadCustomMarkerIcons(); 
    _initializeData();
    getCurrentLocation();
    _initializeSocket();

    ever(driverLocation, (_) {
      try {
        if (mapController != null && isFollowingDriver.value) {
          _focusOnDriver();
        }
      } catch (e) {
        print('Error al actualizar la cámara: $e');
      }
    });
    
    if (travelList.isNotEmpty) {
      String status = travelList[0].id_status.toString();
      isFollowingDriver.value = (status == "3" || status == "4");

      // Solo gestionar socket si el estado es 3
      if (status == "3") {
        _manageSocketBasedOnStatus(status);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('TaxiSocket: App resumed - Verificando estado de socket');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        print('TaxiSocket: App paused - Desconectando socket');
        _handleAppPaused();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    if (travelList.isEmpty) return;
    
    String status = travelList[0].id_status.toString();
    
    bool needsForcedReconnect = false;
    if (_lastUpdateTime != null) {
      final elapsed = DateTime.now().difference(_lastUpdateTime!);
      needsForcedReconnect = elapsed.inSeconds > 10;
      print('TaxiSocket: ${elapsed.inSeconds} segundos desde última actualización');
    }

    if (status == "3") {
      print('TaxiSocket: Reconectando en estado 3');
      
      if (needsForcedReconnect || _forceReconnectOnNextResume) {
        _forceReconnectOnNextResume = false;
        
        print('TaxiSocket: Forzando reconexión completa');
        _isSocketConnected.value = false;
        _isRoomJoined.value = false;
        
        socketDriver.disconnect();
        socketDriver = SocketDriverDataSourceImpl();
      }
      
      _reconnectSocketIfNeeded();
    } else {
      _disconnectSocket();
    }
  }

  void _handleAppPaused() {
    _forceReconnectOnNextResume = true;
    print('TaxiSocket: Marcando para forzar reconexión en próximo resume');
    
    _disconnectSocket();
  }

  void _setupLocationIsolateListener() {
    final receivePort = ReceivePort();
    if (IsolateNameServer.lookupPortByName(_isolateName) != null) {
      IsolateNameServer.removePortNameMapping(_isolateName);
    }
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);

    receivePort.listen((message) {
      if (message is Map<String, dynamic> && message['type'] == 'location') {
        final locationData = message['data'];
        if (travelList.isNotEmpty) {
          String idStatusString = travelList[0].id_status.toString();
          
          // Solo enviar datos si estamos en estado 3 y conectados
          if (idStatusString == "3" && _isSocketConnected.value && _isRoomJoined.value) {
            socketDriver.updateLocation(
              travelList[0].id.toString(),
              locationData,
            );
          }
        }
      }
    });
  }

  void _initializeSocket() {
    socketDriver = SocketDriverDataSourceImpl();
    
    // No conectar automáticamente al inicializar
    // La conexión se gestionará basada en el estado de la app y el viaje
  }

  void _manageSocketBasedOnStatus(String status) {
    // Solo conectar si estamos exactamente en estado 3
    if (status == "3") {
      print('TaxiSocket: Estado 3 detectado, iniciando conexión');
      _reconnectSocketIfNeeded();
    } else {
      // Desconectar en otros estados
      print('TaxiSocket: Estado $status detectado, desconectando socket');
      _disconnectSocket();
    }
  }

  void _reconnectSocketIfNeeded() {
    if (_isSocketOperationInProgress.value) {
      print('TaxiSocket: Operación en progreso, ignorando reconexión');
      return;
    }
    
    if (travelList.isEmpty) return;
    
    // Verificar que estemos exactamente en estado 3
    String status = travelList[0].id_status.toString();
    if (status != "3") {
      print('TaxiSocket: No estamos en estado 3, cancelando reconexión');
      _disconnectSocket();
      return;
    }
    
    if (!_isSocketConnected.value) {
      _connectSocket();
    } else if (!_isRoomJoined.value) {
      _joinRoom(travelList[0].id.toString());
    } else {
      print('TaxiSocket: Ya conectado y unido a la sala');
      
      if (_lastUpdateTime != null) {
        final elapsed = DateTime.now().difference(_lastUpdateTime!);
        if (elapsed.inSeconds > 15) {
          print('TaxiSocket: No se han recibido actualizaciones en ${elapsed.inSeconds} segundos, forzando reconexión');
          _disconnectSocket();
          Future.delayed(Duration(milliseconds: 500), () {
            _connectSocket();
          });
        }
      }
    }
  }

  void _connectSocket() {
    if (_isSocketOperationInProgress.value) return;
    
    if (travelList.isNotEmpty) {
      String status = travelList[0].id_status.toString();
      if (status != "3") {
        print('TaxiSocket: No estamos en estado 3, cancelando conexión');
        return;
      }
    } else {
      return;
    }
    
    _isSocketOperationInProgress.value = true;
    _connectionAttempts++;
    
    print('TaxiSocket: Iniciando conexión al socket (intento: $_connectionAttempts)');
    
    try {
      if (socketDriver.socket.connected) {
        socketDriver.socket.disconnect();
      }
      
      socketDriver.socket.onConnect((_) {
        print('TaxiSocket: Conectado con ID: ${socketDriver.socketId}');
        _isSocketConnected.value = true;
        _isSocketOperationInProgress.value = false;
        
        if (travelList.isNotEmpty) {
          String status = travelList[0].id_status.toString();
          if (status == "3" && !_isRoomJoined.value) {
            _joinRoom(travelList[0].id.toString());
          } else if (status != "3") {
            print('TaxiSocket: Estado cambió a $status, desconectando');
            _disconnectSocket();
          }
        }
      });
      
      socketDriver.socket.onDisconnect((_) {
        print('TaxiSocket: Desconectado');
        _isSocketConnected.value = false;
        _isRoomJoined.value = false;
        
        if (travelList.isNotEmpty && travelList[0].id_status.toString() == "3") {
          _socketReconnectTimer?.cancel();
          _socketReconnectTimer = Timer(Duration(seconds: 5), () {
            _reconnectSocketIfNeeded();
          });
        }
      });
      
      socketDriver.socket.onError((error) {
        print('TaxiSocket: Error de conexión - $error');
        _isSocketOperationInProgress.value = false;
      });
      
      socketDriver.connect();
      
      Future.delayed(const Duration(seconds: 5), () {
        _isSocketOperationInProgress.value = false;
      });
    } catch (e) {
      print('TaxiSocket: Error al conectar socket - $e');
      _isSocketOperationInProgress.value = false;
    }
  }

  void _joinRoom(String roomId) {
    if (_isSocketOperationInProgress.value || _isRoomJoined.value) return;
    
    if (travelList.isNotEmpty) {
      String status = travelList[0].id_status.toString();
      if (status != "3") {
        print('TaxiSocket: No estamos en estado 3, cancelando unión a sala');
        return;
      }
    } else {
      return;
    }
    
    if (!_isSocketConnected.value) {
      print('TaxiSocket: No conectado, intentando reconectar primero');
      _connectSocket();
      return;
    }
    
    _isSocketOperationInProgress.value = true;
    print('TaxiSocket: Uniéndose a la sala $roomId');
    
    try {
      socketDriver.joinTravel(roomId);
      _isRoomJoined.value = true;
      print('TaxiSocket: Unido a la sala $roomId');
      
      _setupUpdateMonitor();
    } catch (e) {
      print('TaxiSocket: Error al unirse a la sala - $e');
    } finally {
      _isSocketOperationInProgress.value = false;
    }
  }

  void _setupUpdateMonitor() {
    if (travelList.isEmpty || travelList[0].id_status.toString() != "3") return;
    
    Future.delayed(Duration(seconds: 15), () {
      if (travelList.isEmpty || travelList[0].id_status.toString() != "3") return;
      
      if (_isSocketConnected.value && _isRoomJoined.value) {
        if (_lastUpdateTime != null) {
          final elapsed = DateTime.now().difference(_lastUpdateTime!);
          if (elapsed.inSeconds > 12) {
            print('TaxiSocket: Sin actualizaciones por ${elapsed.inSeconds} segundos, reconectando');
            
            _disconnectSocket();
            Future.delayed(Duration(seconds: 1), () {
              if (travelList.isNotEmpty && travelList[0].id_status.toString() == "3") {
                _connectSocket();
              }
            });
          } else {
            // Seguir monitoreando
            _setupUpdateMonitor();
          }
        } else {
          // No hay actualización previa, seguir monitoreando
          _setupUpdateMonitor();
        }
      }
    });
  }

  void _disconnectSocket() {
    // Cancelar timers primero
    _socketReconnectTimer?.cancel();
    _socketReconnectTimer = null;
    
    if (!_isSocketConnected.value) return;
    
    print('TaxiSocket: Desconectando socket');
    try {
      socketDriver.disconnect();
      _isSocketConnected.value = false;
      _isRoomJoined.value = false;
    } catch (e) {
      print('TaxiSocket: Error al desconectar socket - $e');
    }
  }

Future<void> _loadCustomMarkerIcons() async {
  try {
    final String taxiImagePath = Platform.isAndroid 
      ? 'assets/images/taxi/taxi_norte.png' 
      : 'assets/images/taxi/taxi_norte_ios.png';


    final String origenImagePath = Platform.isAndroid 
      ? 'assets/images/mapa/origen-android.png' 
      : 'assets/images/mapa/origen-ios.png';
      
    final String destinoImagePath = Platform.isAndroid 
      ? 'assets/images/mapa/destino-android.png' 
      : 'assets/images/mapa/destino-ios.png';

    await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      taxiImagePath,
    ).then((icon) {
      driverIcon.value = icon;
      driverIconLoaded.value = true;
      _updateExistingMarkers();
    }).catchError((error) {
      print('Error cargando ícono del taxi: $error');
      driverIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      driverIconLoaded.value = true;
    });

    await Future.wait([
      BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        origenImagePath,
      ).then((icon) {
        startIcon.value = icon;
        startIconLoaded.value = true;
      }).catchError((error) {
        print('Error cargando ícono de origen: $error');
        startIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        startIconLoaded.value = true;
      }),

      BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.5),
        destinoImagePath,
      ).then((icon) {
        destinationIcon.value = icon;
        destinationIconLoaded.value = true;
      }).catchError((error) {
        print('Error cargando ícono de destino: $error');
        destinationIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        destinationIconLoaded.value = true;
      }),
    ]);

    markersLoaded.value = startIconLoaded.value && 
                         destinationIconLoaded.value && 
                         driverIconLoaded.value;

    if (markersLoaded.value) {
      _updateExistingMarkers();
    }
  } catch (e) {
    print('Error general cargando íconos personalizados: $e');
    startIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    destinationIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    driverIcon.value = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    
    markersLoaded.value = true;
    _updateExistingMarkers();
  }
}

  void _updateExistingMarkers() {
    if (markers.isNotEmpty) {
      final updatedMarkers = Set<Marker>.from(markers);
      markers.value = updatedMarkers;
      _initializeData();
    }
  }

  @override
  void onClose() {
    try {
      // Liberar recursos de observador de ciclo de vida
      WidgetsBinding.instance.removeObserver(this);
      
      // Cancelar timer de reconexión si existe
      _socketReconnectTimer?.cancel();
      _socketReconnectTimer = null;
      
      if (mapController != null) {
        mapController?.dispose();
        mapController = null;
      }

      // Desconectar socket
      _disconnectSocket();

      if (positionStreamSubscription != null) {
        positionStreamSubscription?.cancel();
        positionStreamSubscription = null;
      }
    } catch (e) {
      print('Error en onClose: $e');
    } finally {
      super.onClose();
    }
  }

  int travelStageToInt(TravelStage stage) {
    switch (stage) {
      case TravelStage.heLlegado:
        return 0;
      case TravelStage.iniciarViaje:
        return 1;
      case TravelStage.terminarViaje:
        return 2;
    }
  }

  TravelStage intToTravelStage(int value) {
    switch (value) {
      case 0:
        return TravelStage.heLlegado;
      case 1:
        return TravelStage.iniciarViaje;
      case 2:
        return TravelStage.terminarViaje;
      default:
        return TravelStage.heLlegado;
    }
  }

  void _initializeData() {
    if (travelList.isNotEmpty) {
      var travelAlert = travelList[0];

      double? startLatitude = double.tryParse(travelAlert.start_latitude);
      double? startLongitude = double.tryParse(travelAlert.start_longitude);
      double? endLatitude = double.tryParse(travelAlert.end_latitude);
      double? endLongitude = double.tryParse(travelAlert.end_longitude);

      if (startLatitude != null &&
          startLongitude != null &&
          endLatitude != null &&
          endLongitude != null) {
        startLocation.value = LatLng(startLatitude, startLongitude);
        endLocation.value = LatLng(endLatitude, endLongitude);

        // Obtener id_status
        int idStatus = int.tryParse(travelAlert.id_status.toString()) ?? 0;
        
        // Añadir marcador de inicio siempre
        _addMarkerWithoutBounds(startLocation.value!, isStartPlace: true);
        
        // Añadir marcador de destino solo si id_status NO es 3
        if (idStatus != 3) {
          _addMarkerWithoutBounds(endLocation.value!, isStartPlace: false);
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar('Error', 'Error al convertir coordenadas a números');
        });
      }

      int idStatus = int.tryParse(travelAlert.id_status.toString()) ?? 0;
      waitingFor.value = travelAlert.waiting_for;

      // Activar seguimiento automático para estados 3 y 4
      shouldTrackDriver.value = (idStatus == 3 || idStatus == 4);
      isFollowingDriver.value = (idStatus == 3 || idStatus == 4);

      if (idStatus == 3) {
        // Asegurar que el marcador de destino no esté presente
        markers.removeWhere((m) => m.markerId.value == 'destination');
        
        if (mapController != null && driverLocation.value != null) {
          _focusOnDriver();
        }
      } else if (idStatus == 4) {
        // Limpiar las polylines
        polylines.clear();
        
        // Desconectar socket si estábamos en estado 4
        _disconnectSocket();
        
        if (mapController != null && driverLocation.value != null) {
          _focusOnDriver();
        }
      }
      
      isIdStatusSix.value = (idStatus == 6);
      if (idStatus == 6) {
        polylines.clear();
        
        // Desconectar socket si estábamos en estado 6
        _disconnectSocket();
      }
    }
  }

  void _focusOnDriver() {
    if (driverLocation.value != null &&
        mapController != null &&
        isFollowingDriver.value) {
      try {
        double bearing = 0.0;
    
        mapController
            ?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: driverLocation.value!,
              zoom: navigationZoom,
              tilt: navigationTilt,
              bearing: bearing,
            ),
          ),
        )
            .catchError((error) {
          print('Error al animar la cámara: $error');
        });
      } catch (e) {
        print('Error en _focusOnDriver: $e');
      }
    }
  }

  void _addMarkerWithoutBounds(LatLng latLng,
      {required bool isStartPlace, bool isDriver = false}) {
    if (!markersLoaded.value) {
      // Si los íconos no están cargados, esperamos un momento y reintentamos
      Future.delayed(const Duration(milliseconds: 500), () {
        _addMarkerWithoutBounds(latLng, isStartPlace: isStartPlace, isDriver: isDriver);
      });
      return;
    }

    final updatedMarkers = Set<Marker>.from(markers.value);
    String title;
    BitmapDescriptor markerIcon;
    String markerId;
    double rotation = 0.0;

    if (isDriver) {
      title = 'Conductor';
      markerIcon = driverIconLoaded.value ? driverIcon.value : 
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      markerId = 'driver';
      driverLocation.value = latLng;
      
      if (_lastKnownDriverPosition != null) {
        rotation = _calculateBearing(_lastKnownDriverPosition!, latLng);
      }
      _lastKnownDriverPosition = latLng;
    } else if (isStartPlace) {
      title = 'Inicio';
      markerIcon = startIconLoaded.value ? startIcon.value : 
          BitmapDescriptor.defaultMarker;
      markerId = 'start';
      startLocation.value = latLng;
    } else {
      title = 'Destino';
      markerIcon = destinationIconLoaded.value ? destinationIcon.value : 
          BitmapDescriptor.defaultMarker;
      markerId = 'destination';
      endLocation.value = latLng;
    }

    updatedMarkers.removeWhere((m) => m.markerId.value == markerId);
    updatedMarkers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: latLng,
        infoWindow: InfoWindow(title: title),
        icon: markerIcon,
        rotation: isDriver ? rotation : 0.0,
        anchor: const Offset(0.5, 0.5),
        flat: isDriver,
        onTap: () {
          if (!isDriver) {
            driverTravelLocalDataSource.showLocationPreview(latLng, title);
          }
        },
      ),
    ); 

    markers.value = updatedMarkers;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double long1 = start.longitude * pi / 180;
    double long2 = end.longitude * pi / 180;
    double dLon = (long2 - long1);
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  LatLngBounds createLatLngBoundsFromMarkers() {
    if (markers.isEmpty) {
      return LatLngBounds(
        northeast: center,
        southwest: center,
      );
    }

    List<LatLng> positions = markers.map((m) => m.position).toList();
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void addMarker(LatLng latLng,
      {required bool isStartPlace, bool isDriver = false}) {
    _addMarkerWithoutBounds(latLng,
        isStartPlace: isStartPlace, isDriver: isDriver);

    if (mapController != null) {
      updateMapBounds();
    }
  }

  void getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Por favor, habilita los servicios de ubicación');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Los permisos de ubicación están denegados');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Los permisos de ubicación están denegados permanentemente');
      return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      driverLocation.value = LatLng(position.latitude, position.longitude);
      
      // Usar el rumbo del dispositivo cuando esté disponible, de lo contrario calcular desde posiciones
      double bearing = position.heading;
      if (bearing == 0 && _lastKnownDriverPosition != null) {
        bearing = _calculateBearing(_lastKnownDriverPosition!, driverLocation.value!);
      }
      
      // Solo actualizar el marcador del conductor
      _addMarkerWithoutBounds(
        driverLocation.value!,
        isStartPlace: false,
        isDriver: true,
      );

      // Actualización de ubicación por socket
      if (travelList.isNotEmpty) {
        String idStatusString = travelList[0].id_status.toString();
        if ((idStatusString == "3" || idStatusString == "4") && 
            _isSocketConnected.value && 
            _isRoomJoined.value) {
          socketDriver.updateLocation(
            travelList[0].id.toString(),
            {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'speed': position.speed,
              'bearing': bearing
            },
          );
        }
      }

      // Actualizar enfoque de cámara si es necesario
      if (travelList.isNotEmpty) {
        String idStatusString = travelList[0].id_status.toString();
        int idStatus = int.tryParse(idStatusString) ?? 0;

        if (idStatus == 3 || idStatus == 4) {
          shouldTrackDriver.value = true;
          isFollowingDriver.value = true;
          _focusOnDriver();
        }
      }
    });
  }

  void updateCurrentStep() {
    if (routeSteps.isEmpty || driverLocation.value == null) return;

    // Encontrar el paso más cercano basado en la distancia
    var minDistance = double.infinity;
    var closestStepIndex = 0;

    for (int i = 0; i < routeSteps.length; i++) {
      // Aquí deberías implementar la lógica para calcular
      // la distancia entre la ubicación actual y cada paso
      // Por ahora, usaremos un ejemplo simple
      if (i < routeSteps.length - 1) {
        currentStep.value = routeSteps[i];
        break;
      }
    }
  }
double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
void cancelJourney() {
  journeyStarted.value = false;
  journeyCompleted.value = false;
  hellegado.value = false;
  polylines.clear();

  if (startLocation.value != null) {
    addMarker(startLocation.value!, isStartPlace: true);
  }
}
Future<void> launchGoogleMapsNavigationToDestination() async {
 

  final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
      '&origin=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
      '&destination=${endLocation.value!.latitude},${endLocation.value!.longitude}'
      '&travelmode=driving';

  if (await canLaunch(googleMapsUrl)) {
    // Iniciar el rastreo antes de abrir Google Maps
    if (travelList.isNotEmpty) {
     // await LocationHandler.startTracking(travelList[0].id.toString());
    }
    await launch(googleMapsUrl);
  } else {
    CustomSnackBar.showError('Error', 'No se pudo abrir Google Maps');
  }
}

Future<void> launchGoogleMapsNavigationStart() async {
 

  final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1'
      '&origin=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
      '&destination=${startLocation.value!.latitude},${startLocation.value!.longitude}'
      '&travelmode=driving';

  if (await canLaunch(googleMapsUrl)) {
    // Iniciar el rastreo antes de abrir Google Maps
    if (travelList.isNotEmpty) {
     // await LocationHandler.startTracking(travelList[0].id.toString());
    }
    await launch(googleMapsUrl);
  } else {
    CustomSnackBar.showError('Error', 'No se pudo abrir Google Maps');
  }
}

  void updateNavigationPreference(bool useMapboxNav) async {
    useMapbox.value = useMapboxNav;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_mapbox', useMapboxNav);
  }
// Actualiza estos métodos en TravelRouteController

Future<void> launchNavigationToDestination() async {
  if (endLocation.value == null || driverLocation.value == null) {
    CustomSnackBar.showError('Error', 'Esperando coordenadas de destino...');
    return;
  }

  try {
    if (Platform.isAndroid) {
      // Navegación con Google Maps para Android
      await launchGoogleMapsNavigationToDestination();
    } else if (Platform.isIOS) {
      // Navegación con Apple Maps para iOS
      await launchAppleMapsNavigationToDestination();
    }
  } catch (e) {
    CustomSnackBar.showError('Error', 'No se pudo iniciar la navegación: $e');
  }
}

Future<void> launchNavigationToStart() async {
  if (startLocation.value == null || driverLocation.value == null) {
    CustomSnackBar.showError('Error', 'Esperando coordenadas de origen...');
    return;
  }

  try {
    if (Platform.isAndroid) {
      // Navegación con Google Maps para Android
      await launchGoogleMapsNavigationStart();
    } else if (Platform.isIOS) {
      // Navegación con Apple Maps para inicio
      await launchAppleMapsNavigationStart();
    }
  } catch (e) {
    CustomSnackBar.showError('Error', 'No se pudo iniciar la navegación: $e');
  }
}

Future<void> launchAppleMapsNavigationToDestination() async {
  // Usar el esquema maps:// para abrir directamente la aplicación Apple Maps
  final String appleMapsUrl = 'maps://?'
      'saddr=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
      '&daddr=${endLocation.value!.latitude},${endLocation.value!.longitude}'
      '&dirflg=d';

  if (await canLaunch(appleMapsUrl)) {
    await launch(appleMapsUrl, forceSafariVC: false);
  } else {
    // Intentar URL alternativa como respaldo
    final String fallbackUrl = 'https://maps.apple.com/?'
        'saddr=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
        '&daddr=${endLocation.value!.latitude},${endLocation.value!.longitude}'
        '&dirflg=d';
        
    if (await canLaunch(fallbackUrl)) {
      await launch(fallbackUrl);
    } else {
      CustomSnackBar.showError('Error', 'No se pudo abrir Apple Maps');
    }
  }
}

Future<void> launchAppleMapsNavigationStart() async {
  // Usar el esquema maps:// para abrir directamente la aplicación Apple Maps
  final String appleMapsUrl = 'maps://?'
      'saddr=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
      '&daddr=${startLocation.value!.latitude},${startLocation.value!.longitude}'
      '&dirflg=d';

  if (await canLaunch(appleMapsUrl)) {
    await launch(appleMapsUrl, forceSafariVC: false);
  } else {
    // Intentar URL alternativa como respaldo
    final String fallbackUrl = 'https://maps.apple.com/?'
        'saddr=${driverLocation.value!.latitude},${driverLocation.value!.longitude}'
        '&daddr=${startLocation.value!.latitude},${startLocation.value!.longitude}'
        '&dirflg=d';
        
    if (await canLaunch(fallbackUrl)) {
      await launch(fallbackUrl);
    } else {
      CustomSnackBar.showError('Error', 'No se pudo abrir Apple Maps');
    }
  }
}

// El resto de los métodos existentes se mantienen igual

// El resto de los métodos existentes se mantienen igual
  void startTravel(BuildContext context) {
    String travelId = travelList.isNotEmpty ? travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      CustomSnackBar.showError('Error', 'No se encontró el ID del viaje');
      return;
    }

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Inicio de Viaje',
      text: '¿Estás seguro de que deseas iniciar el viaje?',
      confirmBtnText: 'Sí',
      cancelBtnText: 'No',
      onConfirmBtnTap: () async {
        Navigator.of(Get.context!).pop();
        isLoadingStartJourney.value = true; // Iniciar loading

        try {
                 //   await LocationHandler.stopTracking();

          startTravelController
              .starttravel(StartravelEvent(id_travel: travelList[0].id));
          travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

          await startTravelController.starttravelState.listen((state) {
            if (state is StarttravelLoading) {
              // Ya estamos mostrando el loading
            } else if (state is AcceptedtravelSuccessfully) {
              travelStage.value = TravelStage.terminarViaje;

              journeyStarted.value = true;
              markers.removeWhere((m) => m.markerId.value == 'start');
              polylines.removeWhere(
                  (polyline) => polyline.polylineId.value == 'start_to_end');
              polylines.removeWhere(
                  (polyline) => polyline.polylineId.value == 'driver_to_start');
              lastDriverPositionForRouteUpdate = null;
              final currentTravelGetx = Get.find<CurrentTravelGetx>();

              currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
              CustomSnackBar.showSuccess(
                'Éxito',
                'Viaje iniciado correctamente',
              );
            } else if (state is StarttravelError) {
              CustomSnackBar.showError(
                  'Error', 'Viaje ya fue iniciado ${state.message}');
            }
          });
        } catch (e) {
          CustomSnackBar.showError('Error', 'Error al iniciar el viaje: $e');
        } finally {
          isLoadingStartJourney.value = false; // Finalizar loading
        }
      },
    );
  }

  void endTravel(BuildContext context) {
    String travelId = travelList.isNotEmpty ? travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      CustomSnackBar.showError('Error', 'No se encontró el ID del viaje');
      return;
    }

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Fin de Viaje',
      widget: RichText(
        text: TextSpan(
          text: 'Importe ',
          style: TextStyle(color: Colors.black, fontSize: 20),
          children: [
            TextSpan(
              text: '\$${travelList[0].tarifa} MXN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      confirmBtnText: 'Sí',
      cancelBtnText: 'No',
      onConfirmBtnTap: () async {
        Navigator.of(Get.context!).pop();
              //  await LocationHandler.stopTracking();

        endTravelController
            .endtravel(EndTravelEvent(id_travel: travelList[0].id));
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        endTravelController.endtravelState.listen((state) async {
          if (state is EndtravelSuccessfully) {
            journeyCompleted.value = true;
            travelStage.value = TravelStage.heLlegado;
  await Get.find<NavigationService>()
                .navigateToHome(selectedIndex: 0);
            CustomSnackBar.showSuccess(
                'Éxito', 'Viaje terminado correctamente');
            currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
          } else if (state is EndtravelError) {
            CustomSnackBar.showError('Error', 'Viaje ya fue terminado');
          }
        });
      },
    );
  }

  void completeTrip(BuildContext context) {
    String travelId = travelList.isNotEmpty ? travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      CustomSnackBar.showError('Error', 'No se encontró el ID del viaje');
      return;
    }

    final event = DriverArrivalEvent(id_travel: travelList[0].id);
    driverArrivalGetx.driverarrival(event);

    driverArrivalGetx.driverarrivalState.listen((state) {
      if (state is DriverarrivalSuccessfully) {
        
        CustomSnackBar.showSuccess('Éxito', 'notificación enviada');
        travelStage.value = TravelStage.iniciarViaje;
      } else if (state is DriverarrivalError) {
        CustomSnackBar.showSuccess('Error', driverArrivalGetx.message.value);
      }
    });
  }

  void cancelTravel(BuildContext context)  {
    int travelId = travelList.isNotEmpty ? travelList[0].id : 0;
    int driverId =
        travelList.isNotEmpty ? int.parse(travelList[0].id_travel_driver) : 0;

    final travel =
        Travelwithtariff(travelId: travelId, tarifa: 0, driverId: driverId);
    showCustomAlert(
      context: Get.context!,
      type: CustomAlertType.confirm,
      title: 'Cancelar viaje',
      message: '¿Estás seguro de Cancelar el viaje?',
      confirmText: 'Sí',
      cancelText: 'No',
      onConfirm: () async {
            //    await LocationHandler.stopTracking();

        final event = CancelTravelEvent(travelwithtariff: travel);
        _cancelTravel.canceltravel(event);

        _cancelTravel.acceptedtravelState.listen((state) async {
          if (state is CanceltravelSuccessfully) {
              await Get.find<NavigationService>()
                .navigateToHome(selectedIndex: 0);
            CustomSnackBar.showSuccess(
                'Éxito', 'Viaje cancelado correctamente');
            currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
            travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
          } else if (state is CanceltravelError) {
            CustomSnackBar.showError('Error', _cancelTravel.message.value);
          }
        });

        Navigator.of(Get.context!).pop();
      },
      onCancel: () => Navigator.of(Get.context!).pop(),
    );
  }

  void CancelTravel(BuildContext context) async {
    int travelId = travelList.isNotEmpty ? travelList[0].id : 0;
    int driverId =
        travelList.isNotEmpty ? int.parse(travelList[0].id_travel_driver) : 0;

    final travel =
        Travelwithtariff(travelId: travelId, tarifa: 0, driverId: driverId);

    final event = RejecttravelOfferEvent(travel: travel);
    rejectTravelOfferGetx.rejectTravelOfferGetx(event);
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

    rejectTravelOfferGetx.acceptedtravelState.listen((state) {
      if (state is RejectTravelOfferSuccessfully) {
        CustomSnackBar.showSuccess('Éxito', 'Viaje cancelado correctamente');
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
        AuthService().clearCurrenttravel();

        final availability = ChangeAvailabilityEntitie(status: true);
        _driverGetx.execute(
            ChangeaVailabilityEvent(changeAvailabilityEntitie: availability));

        Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
      } else if (state is RejectTravelOfferError) {
        AuthService().clearCurrenttravel();

        CustomSnackBar.showSuccess(
            'Error', rejectTravelOfferGetx.message.value);
        Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
      }
    });
  }

  void onMapCreated(GoogleMapController controller) {
    try {
      mapController = controller;
      if (travelList.isNotEmpty) {
        int idStatus = int.tryParse(travelList[0].id_status.toString()) ?? 0;
        if ((idStatus == 3 || idStatus == 4) && driverLocation.value != null) {
          shouldTrackDriver.value = true;
          isFollowingDriver.value = true;
          _focusOnDriver();
        } else {
          updateMapBounds();
        }
      }
    } catch (e) {
      print('Error en onMapCreated: $e');
    }
  }

  void updateTravelStatus(String newStatus) {
    int idStatus = int.tryParse(newStatus) ?? 0;
    shouldTrackDriver.value = (idStatus == 3 || idStatus == 4);
    isFollowingDriver.value = (idStatus == 3 || idStatus == 4);

    if (shouldTrackDriver.value && driverLocation.value != null) {
      _focusOnDriver();
    }
  }

  void toggleDriverFollow() {
    if (travelList.isNotEmpty) {
      int idStatus = int.tryParse(travelList[0].id_status.toString()) ?? 0;
      if (idStatus == 3 || idStatus == 4) {
        isFollowingDriver.value = !isFollowingDriver.value;
        shouldTrackDriver.value = isFollowingDriver.value;

        if (isFollowingDriver.value && driverLocation.value != null) {
          _focusOnDriver();
        }
      }
    }
  }

  void updateMapBounds() {
    if (markers.isEmpty || mapController == null) return;

    /*
    if (!shouldTrackDriver.value) {
      LatLngBounds bounds = createLatLngBoundsFromMarkers();
      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }*/
  }
}
