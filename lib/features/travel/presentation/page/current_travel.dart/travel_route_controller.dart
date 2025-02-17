import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
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
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/NavigationOverlay.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;

import 'package:url_launcher/url_launcher.dart';

enum TravelStage { heLlegado, iniciarViaje, terminarViaje }

class TravelRouteController extends GetxController {
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
  final double navigationZoom = 14.0;
  final double navigationTilt = 60.0;
  RxBool isFollowingDriver = true.obs;
  RxBool isLoadingStartJourney = false.obs;

  GoogleMapController? mapController;
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  final MapaLocalDataSource travelLocalDataSource = MapaLocalDataSourceImp();
  final MapaLocalDataSource driverTravelLocalDataSource =
      MapaLocalDataSourceImp();
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
  late MapBoxNavigation _directions;
  late SocketDriverDataSourceImpl socketDriver;
static const String _isolateName = 'locationIsolate';
  RxBool isBackgroundServiceRunning = false.obs;

  @override
  void onInit() async {
    super.onInit();
    _directions = MapBoxNavigation();
    final prefs = await SharedPreferences.getInstance();
    useMapbox.value = prefs.getBool('use_mapbox') ?? true;
        _setupLocationIsolateListener();

    _loadCustomMarkerIcons();
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

      // Conectar o desconectar socket según el status
      _handleSocketConnectionBasedOnStatus(status);
    }
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
        // Update socket with location data
        if (travelList.isNotEmpty) {
          String idStatusString = travelList[0].id_status.toString();
          if (idStatusString == "3" || idStatusString == "4") {
            socketDriver.updateLocation(
              travelList[0].id.toString(),
              locationData,
            );
          }
        }
      }
    });
  }

  void _handleSocketConnectionBasedOnStatus(String status) {
    if (status == "3" || status == "4") {
      // Conectar y unirse al viaje
      socketDriver.connect();
      if (travelList.isNotEmpty) {
        socketDriver.joinTravel(travelList[0].id.toString());
      }
    } else {
      // Desconectar en otros estados
      socketDriver.disconnect();
    }
  }

  void _initializeSocket() {
    socketDriver = SocketDriverDataSourceImpl();
  }

  Future<void> _loadCustomMarkerIcons() async {
    try {
      final List<Future<void>> futures = [
        BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: 2.5),
          'assets/images/mapa/origen.png',
        ).then((icon) => startIcon.value = icon),
        BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: 2.5),
          'assets/images/mapa/destino.png',
        ).then((icon) => destinationIcon.value = icon),
        BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: 2.5),
          'assets/images/taxi/taxi_norte.png',
        ).then((icon) => driverIcon.value = icon),
      ];

      await Future.wait(futures);
      markersLoaded.value = true;
      _updateExistingMarkers();
    } catch (e) {
      print('Error cargando iconos personalizados: $e');
      startIcon.value = BitmapDescriptor.defaultMarker;
      destinationIcon.value = BitmapDescriptor.defaultMarker;
      driverIcon.value =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
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
      if (mapController != null) {
        mapController?.dispose();
        mapController = null;
      }

      _directions.finishNavigation();

      socketDriver.disconnect();

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

        // Add markers without checking bounds initially
        _addMarkerWithoutBounds(startLocation.value!, isStartPlace: true);
        _addMarkerWithoutBounds(endLocation.value!, isStartPlace: false);

        traceRouteStartToEnd();
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
        traceRouteStartToEnd();
        traceRouteDriverToStart();
        if (mapController != null && driverLocation.value != null) {
          _focusOnDriver();
        }
      } else if (idStatus == 4) {
        polylines.clear();
        traceRouteDriverToEnd();
        if (mapController != null && driverLocation.value != null) {
          _focusOnDriver();
        }
         _addMarkerWithoutBounds(startLocation.value!, isStartPlace: false);

      }
      if (idStatus == 6) {
        isIdStatusSix.value = true;

        polylines.clear();
      } else if (idStatus == 5) {
        isIdStatusSix.value = false;
      } else if (idStatus == 4) {
        isIdStatusSix.value = false;
      } else if (idStatus == 3) {
        isIdStatusSix.value = false;
      } else {
        isIdStatusSix.value = false;
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
  final updatedMarkers = Set<Marker>.from(markers.value);
  String title;
  BitmapDescriptor markerIcon;
  String markerId;
  double rotation = 0.0;

  if (isDriver) {
    title = 'Conductor';
    markerIcon = driverIcon.value;
    markerId = 'driver';
    driverLocation.value = latLng;
    
    // Calculate bearing only if we have a previous position
    if (_lastKnownDriverPosition != null) {
      rotation = _calculateBearing(_lastKnownDriverPosition!, latLng);
    }
    // Update last known position for next calculation
    _lastKnownDriverPosition = latLng;
  } else if (isStartPlace) {
    title = 'Inicio';
    markerIcon = startIcon.value;
    markerId = 'start';
    startLocation.value = latLng;
  } else {
    title = 'Destino';
    markerIcon = destinationIcon.value;
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
      rotation: isDriver ? rotation : 0.0, // Apply rotation only to driver marker
      anchor: const Offset(0.5, 0.5),
      flat: isDriver, // Make driver marker flat to enable rotation
      onTap: () {
        if (!isDriver) {
          _showLocationPreview(latLng, title);
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


void _showLocationPreview(LatLng location, String title) {
  final colorScheme = Theme.of(Get.context!).colorScheme;
  final String streetViewUrl = 'https://maps.googleapis.com/maps/api/streetview?'
    'size=600x400'
    '&location=${location.latitude},${location.longitude}'
    '&fov=90'
    '&heading=70'
    '&pitch=0'
    '&key=AIzaSyBAVJDSpCXiLRhVTq-MA3RgZqbmxm1wD1I';

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                color: colorScheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.textButton,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.CurvedNavigationIcono2),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Contenedor de imagen
            Container(
              height: Get.height * 0.3,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.loaderbaseColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      streetViewUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.loader),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: colorScheme.Statusaccepted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vista no disponible',
                                style: TextStyle(
                                  color: colorScheme.snackBartext2,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Overlay con coordenadas
                  
                  ],
                ),
              ),
            ),
            // Botones de acción
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                 
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.buttonColormap,
                      foregroundColor: colorScheme.textButton,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierColor: Colors.black54,
  );
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
    await Geolocator.openLocationSettings();
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
    if (driverLocation.value != null) {
      lastDriverPositionForRouteUpdate = driverLocation.value;
    }

    driverLocation.value = LatLng(position.latitude, position.longitude);
    
    // Use the device's heading when available, otherwise calculate from positions
    double bearing = position.heading;
    if (bearing == 0 && _lastKnownDriverPosition != null) {
      bearing = _calculateBearing(_lastKnownDriverPosition!, driverLocation.value!);
    }
    
    _addMarkerWithoutBounds(
      driverLocation.value!,
      isStartPlace: false,
      isDriver: true,
    );

    // Socket location update logic
    if (travelList.isNotEmpty) {
      String idStatusString = travelList[0].id_status.toString();
      if (idStatusString == "3" || idStatusString == "4") {
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

    // Update camera focus if needed
    if (travelList.isNotEmpty) {
      String idStatusString = travelList[0].id_status.toString();
      int idStatus = int.tryParse(idStatusString) ?? 0;

      if (idStatus == 3 || idStatus == 4) {
        shouldTrackDriver.value = true;
        isFollowingDriver.value = true;
        _focusOnDriver();
      }
    }

    updateDriverRouteIfNeeded();
  });
}

  void updateDriverRouteIfNeeded() {
    if (isIdStatusSix.value) return;
    if (driverLocation.value == null) return;

    int idStatus = travelList.isNotEmpty
        ? (int.tryParse(travelList[0].id_status.toString()) ?? 0)
        : 0;

    if (idStatus == 4) {
      traceRouteDriverToEnd();
    } else if (idStatus == 3) {
      traceRouteDriverToStart();
    }
  }

  Future<void> traceRouteStartToEnd() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);

        final updatedPolylines = Set<Polyline>.from(polylines.value);
        updatedPolylines.removeWhere(
            (polyline) => polyline.polylineId.value == 'start_to_end');
        updatedPolylines.add(Polyline(
          polylineId: PolylineId('start_to_end'),
          points: polylineCoordinates,
          color: Colors.black,
          width: 5,
        ));

        polylines.value = updatedPolylines;
      } catch (e) {
        print('Error al trazar la ruta de inicio a destino: $e');
      }
    }
  }

  Future<void> traceRouteDriverToStart() async {
    if (driverLocation.value != null && startLocation.value != null) {
      try {
        await driverTravelLocalDataSource.getRoute(
            driverLocation.value!, startLocation.value!);
        String encodedPoints =
            await driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            driverTravelLocalDataSource.decodePolyline(encodedPoints);

        final updatedPolylines = Set<Polyline>.from(polylines.value);
        updatedPolylines.removeWhere(
            (polyline) => polyline.polylineId.value == 'driver_to_start');
        updatedPolylines.add(Polyline(
          polylineId: PolylineId('driver_to_start'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));

        polylines.value = updatedPolylines;
      } catch (e) {
        print('Error al trazar la ruta del conductor al inicio: $e');
      }
    }
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

  Future<void> traceRouteDriverToEnd() async {
    if (driverLocation.value != null && endLocation.value != null) {
      try {
        await driverTravelLocalDataSource.getRoute(
            driverLocation.value!, endLocation.value!);
        String encodedPoints =
            await driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            driverTravelLocalDataSource.decodePolyline(encodedPoints);

        // Obtener los pasos de la ruta
        routeSteps.value = driverTravelLocalDataSource.steps ?? [];
        if (routeSteps.isNotEmpty) {
          currentStep.value = routeSteps[0];
        }
        final updatedPolylines = Set<Polyline>.from(polylines.value);
        // Remove any existing routes
        updatedPolylines.clear();
        updatedPolylines.add(Polyline(
          polylineId: PolylineId('driver_to_end'),
          points: polylineCoordinates,
          color: Colors.black,
          width: 5,
        ));

        polylines.value = updatedPolylines;
      } catch (e) {
        print('Error al trazar la ruta del conductor al destino: $e');
      }
    }
  }

  void cancelJourney() {
    journeyStarted.value = false;
    journeyCompleted.value = false;
    hellegado.value = false;
    polylines.clear();

    if (startLocation.value != null) {
      addMarker(startLocation.value!, isStartPlace: true);
      traceRouteStartToEnd();
      traceRouteDriverToStart();
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

  Future<void> launchMapboxNavigationToDestination() async {
   /* if (endLocation.value == null || driverLocation.value == null) {
      CustomSnackBar.showError('', 'Espere un momente obteniendo ubicasion');
      return;
    }*/

    isLoadingNavigation.value = true; // Start loading

    try {
      final wayPoints = [
        WayPoint(
            name: "Mi ubicación",
            latitude: driverLocation.value!.latitude,
            longitude: driverLocation.value!.longitude,
            isSilent: true),
        WayPoint(
            name: "Destino Final",
            latitude: endLocation.value!.latitude,
            longitude: endLocation.value!.longitude,
            isSilent: true),
      ];

      final options = MapBoxOptions(
          mode: MapBoxNavigationMode.drivingWithTraffic,
          simulateRoute: false,
          language: "es",
          units: VoiceUnits.metric,
          zoom: 18.0,
          tilt: 30.0,
          bearing: 0.0,
          enableRefresh: true,
          alternatives: true,
          voiceInstructionsEnabled: true,
          bannerInstructionsEnabled: true,
          allowsUTurnAtWayPoints: true,
          isOptimized: true);

      final success = await _directions.startNavigation(
        wayPoints: wayPoints,
        options: options,
      );

      if (success == null || !success) {
        throw Exception('La navegación no se pudo iniciar');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(seconds: 5), () {
          if (!Get.isDialogOpen! && !Get.isSnackbarOpen) {
            Get.back();
          }
        });
      });
    } catch (e) {
      print('Error detallado al iniciar la navegación: $e');
      CustomSnackBar.showError(
          'Error', 'No se pudo iniciar la navegación: ${e.toString()}');
    } finally {
      isLoadingNavigation.value = false; // Stop loading regardless of outcome
    }
  }

  Future<void> launchMapboxNavigationStart() async {
   /* if (startLocation.value == null || driverLocation.value == null) {
      CustomSnackBar.showError('', 'espere un momente ');
      return;
    }*/

    isLoadingNavigation.value = true; // Start loading

    try {
      final wayPoints = [
        WayPoint(
            name: "Mi ubicación",
            latitude: driverLocation.value!.latitude,
            longitude: driverLocation.value!.longitude,
            isSilent: true),
        WayPoint(
            name: "Destino",
            latitude: startLocation.value!.latitude,
            longitude: startLocation.value!.longitude,
            isSilent: true),
      ];

      final options = MapBoxOptions(
        mode: MapBoxNavigationMode.drivingWithTraffic,
        simulateRoute: false,
        language: "es",
        units: VoiceUnits.metric,
        zoom: 18.0,
        tilt: 30.0,
        bearing: 0.0,
        enableRefresh: true,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        isOptimized: true,
      );

      final success = await _directions.startNavigation(
        wayPoints: wayPoints,
        options: options,
      );

      if (success == null || !success) {
        throw Exception('La navegación no se pudo iniciar');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(seconds: 5), () {
          if (!Get.isDialogOpen! && !Get.isSnackbarOpen) {
            Get.back();
          }
        });
      });
    } catch (e) {
      print('Error detallado al iniciar la navegación: $e');
      CustomSnackBar.showError(
          'Error', 'No se pudo iniciar la navegación: ${e.toString()}');
    } finally {
      isLoadingNavigation.value = false; // Stop loading regardless of outcome
    }
  }

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
              _handleSocketConnectionBasedOnStatus("4");

              journeyStarted.value = true;
              markers.removeWhere((m) => m.markerId.value == 'start');
              polylines.removeWhere(
                  (polyline) => polyline.polylineId.value == 'start_to_end');
              polylines.removeWhere(
                  (polyline) => polyline.polylineId.value == 'driver_to_start');
              lastDriverPositionForRouteUpdate = null;
              updateDriverRouteIfNeeded();
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

  void cancelTravel(BuildContext context) {
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

        _cancelTravel.acceptedtravelState.listen((state) {
          if (state is CanceltravelSuccessfully) {
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
