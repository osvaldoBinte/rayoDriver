import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
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
import 'dart:math' show sin, cos, sqrt, atan2, pi;

import 'package:url_launcher/url_launcher.dart';

enum TravelStage { heLlegado, iniciarViaje, terminarViaje }

class TravelRouteController extends GetxController {
  final List<TravelAlertModel> travelList;

  TravelRouteController({required this.travelList});
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();

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
  final double navigationZoom = 20.0;
  final double navigationTilt = 60.0;
  RxBool isFollowingDriver = true.obs;

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

  RxBool shouldTrackDriver = false.obs;
  Rx<BitmapDescriptor> startIcon = BitmapDescriptor.defaultMarker.obs;
  Rx<BitmapDescriptor> destinationIcon = BitmapDescriptor.defaultMarker.obs;
  Rx<BitmapDescriptor> driverIcon = BitmapDescriptor.defaultMarker.obs;
  RxBool markersLoaded = false.obs;
  late SocketDriverDataSourceImpl socketDriver;
Rx<DirectionStep?> currentStep = Rx<DirectionStep?>(null);
  RxList<DirectionStep> routeSteps = <DirectionStep>[].obs;
late MapBoxNavigation _directions; 
@override
  void onInit() {
    super.onInit();
      _directions = MapBoxNavigation(); // Usa MapBoxNavigation

    _loadCustomMarkerIcons();
    _initializeData();
    getCurrentLocation();
    _initializeSocket();
   if (travelList.isNotEmpty) {
      String status = travelList[0].id_status.toString();
      isFollowingDriver.value = (status == "3" || status == "4");
      
      // Conectar o desconectar socket según el status
      _handleSocketConnectionBasedOnStatus(status);
    }
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
          'assets/images/mapa/drivermakert.png',
        ).then((icon) => driverIcon.value = icon),
      ];

      await Future.wait(futures);
      markersLoaded.value = true;
      // Actualizar los marcadores existentes con los nuevos iconos
      _updateExistingMarkers();
    } catch (e) {
      print('Error cargando iconos personalizados: $e');
      // En caso de error, usar marcadores por defecto
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
      _initializeData(); // Reinicializar los marcadores con los nuevos iconos
    }
  }

  @override
void onClose() {
  if (!travelList.isNotEmpty || 
      (travelList[0].id_status.toString() != "3" && 
       travelList[0].id_status.toString() != "4")) {
    socketDriver.disconnect();
  }
  super.onClose();
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
  if (driverLocation.value != null && mapController != null && isFollowingDriver.value) {
    double bearing = 0.0;
    if (lastDriverPositionForRouteUpdate != null) {
      bearing = _calculateBearing(
        lastDriverPositionForRouteUpdate!.latitude,
        lastDriverPositionForRouteUpdate!.longitude,
        driverLocation.value!.latitude,
        driverLocation.value!.longitude,
      );
    }

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: driverLocation.value!,
          zoom: navigationZoom,
          tilt: navigationTilt,
          bearing: bearing,
        ),
      ),
    );
  }
}

  double _calculateBearing(
      double startLat, double startLng, double endLat, double endLng) {
    var startLatRad = startLat * (pi / 180.0);
    var startLngRad = startLng * (pi / 180.0);
    var endLatRad = endLat * (pi / 180.0);
    var endLngRad = endLng * (pi / 180.0);

    var dLng = endLngRad - startLngRad;

    var y = sin(dLng) * cos(endLatRad);
    var x = cos(startLatRad) * sin(endLatRad) -
        sin(startLatRad) * cos(endLatRad) * cos(dLng);

    var bearing = atan2(y, x);
    bearing = bearing * (180.0 / pi);
    bearing = (bearing + 360.0) % 360.0;

    return bearing;
  }

  void _addMarkerWithoutBounds(LatLng latLng,
      {required bool isStartPlace, bool isDriver = false}) {
    final updatedMarkers = Set<Marker>.from(markers.value);

    if (isDriver) {
      updatedMarkers.removeWhere((m) => m.markerId.value == 'driver');
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('driver'),
          position: latLng,
          infoWindow: InfoWindow(title: 'Conductor'),
          icon: driverIcon.value,
          anchor: Offset(0.5, 0.5), // Centrar el icono en la posición
        ),
      );
      driverLocation.value = latLng;
    } else if (isStartPlace) {
      updatedMarkers.removeWhere((m) => m.markerId.value == 'start');
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('start'),
          position: latLng,
          infoWindow: InfoWindow(title: 'Inicio'),
          icon: startIcon.value,
          anchor: Offset(0.5, 0.5), // Centrar el icono en la posición
        ),
      );
      startLocation.value = latLng;
    } else {
      updatedMarkers.removeWhere((m) => m.markerId.value == 'destination');
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: latLng,
          infoWindow: InfoWindow(title: 'Destino'),
          icon: destinationIcon.value,
          anchor: Offset(0.5, 0.5), // Centrar el icono en la posición
        ),
      );
      endLocation.value = latLng;
    }

    markers.value = updatedMarkers;
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

    LocationSettings locationSettings = LocationSettings(
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
      _addMarkerWithoutBounds(driverLocation.value!,
          isStartPlace: false, isDriver: true);

      // Enviar ubicación por socket si estamos en estado 3 o 4
      if (travelList.isNotEmpty) {
        String idStatusString = travelList[0].id_status.toString();
        if (idStatusString == "3" || idStatusString == "4") {
          socketDriver.updateLocation(
            travelList[0].id.toString(),
            {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'speed': position.speed,
              'bearing': position.heading
            },
          );
        }
      }

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
        String encodedPoints = await driverTravelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates = driverTravelLocalDataSource.decodePolyline(encodedPoints);

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

void launchMapboxNavigationToDestination() async {
  if (endLocation.value == null || driverLocation.value == null) {
    CustomSnackBar.showError('Error', 'No se pudo obtener la ubicación');
    return;
  }

  try {
    // Crear los waypoints con coordenadas exactas
    final wayPoints = [
      WayPoint(
        name: "Mi ubicación",
        latitude: driverLocation.value!.latitude,
        longitude: driverLocation.value!.longitude,
        isSilent: true
      ),
      WayPoint(
        name: "Destino Final",
        latitude: endLocation.value!.latitude,
        longitude: endLocation.value!.longitude,
        isSilent: true
      ),
    ];

    // Configurar las opciones de navegación
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
      isOptimized: true
    );

    print('Iniciando navegación con waypoints: ${wayPoints.map((wp) => '${wp.name}: ${wp.latitude},${wp.longitude}').join(' -> ')}');

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
    CustomSnackBar.showError('Error', 'No se pudo iniciar la navegación: ${e.toString()}');
  }
}
void launchMapboxNavigationStart() async {
  if (startLocation.value == null || driverLocation.value == null) {
    CustomSnackBar.showError('Error', 'No se pudo obtener la ubicación');
    return;
  }

  try {
    // Crear los waypoints con coordenadas exactas
    final wayPoints = [
      WayPoint(
        name: "Mi ubicación",
        latitude: driverLocation.value!.latitude,
        longitude: driverLocation.value!.longitude,
        isSilent: true
      ),
      WayPoint(
        name: "Destino",
        latitude: startLocation.value!.latitude,
        longitude: startLocation.value!.longitude,
        isSilent: true
      ),
    ];

    // Configurar las opciones de navegación
    final options = MapBoxOptions(
      mode: MapBoxNavigationMode.drivingWithTraffic,
      simulateRoute: false,
      language: "es",
      units: VoiceUnits.metric,
      zoom: 18.0, // Zoom más cercano para mejor visibilidad
      tilt: 30.0, // Ángulo de inclinación para mejor perspectiva
      bearing: 0.0,
      enableRefresh: true, // Permite actualizar la ruta
      alternatives: true, // Muestra rutas alternativas si están disponibles
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      allowsUTurnAtWayPoints: true,
      isOptimized: true
    );

    print('Iniciando navegación con waypoints: ${wayPoints.map((wp) => '${wp.name}: ${wp.latitude},${wp.longitude}').join(' -> ')}');

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
    CustomSnackBar.showError('Error', 'No se pudo iniciar la navegación: ${e.toString()}');
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
      onConfirmBtnTap: () {
        Navigator.of(Get.context!).pop();
        startTravelController
            .starttravel(StartravelEvent(id_travel: travelList[0].id));
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        startTravelController.starttravelState.listen((state) {
          if (state is StarttravelLoading) {
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
            launchMapboxNavigationToDestination();
            CustomSnackBar.showSuccess(
              'Éxito',
              'Viaje iniciado correctamente',
            );
          } else if (state is StarttravelError) {
            CustomSnackBar.showError(
                'Error', 'Viaje ya fue iniciado ${state.message}');
          }
        });
      },
    );
  }

  void launchNavigationWebView() {
    if (endLocation.value != null) {
      Get.to(() => NavigationWebView(
            destLat: endLocation.value!.latitude,
            destLng: endLocation.value!.longitude,
          ));
    }
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
        endTravelController
            .endtravel(EndTravelEvent(id_travel: travelList[0].id));
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        endTravelController.endtravelState.listen((state) async {
          if (state is EndtravelSuccessfully) {
            journeyCompleted.value = true;
            travelStage.value = TravelStage.heLlegado;

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
      onConfirm: () {
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