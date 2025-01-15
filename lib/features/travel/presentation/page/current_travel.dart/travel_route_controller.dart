import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
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
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/main.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
enum TravelStage { heLlegado, iniciarViaje, terminarViaje }

class TravelRouteController extends GetxController {
  final List<TravelAlertModel> travelList;

  TravelRouteController({required this.travelList});
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final  travelAlertGetx = Get.find<TravelsAlertGetx>();

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
  final double driverZoomLevel = 20; // Ajusta este valor según necesites
final double navigationZoom = 20.0;  // Zoom para modo navegación
  final double navigationTilt = 60.0;  // Inclinación para modo navegación
  RxBool isFollowingDriver = true.obs; // Estado para seguimiento del conductor

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
  final RejectTravelOfferGetx rejectTravelOfferGetx = Get.find<RejectTravelOfferGetx>();
  
  RxBool shouldTrackDriver = false.obs;


  @override
  void onInit() {
    super.onInit();
    _initializeData();
    getCurrentLocation();
    
    // Configurar el estado inicial de seguimiento basado en el status
    if (travelList.isNotEmpty) {
      String status = travelList[0].id_status.toString();
      isFollowingDriver.value = (status == "3" || status == "4");
    }
  }


  @override
  void onClose() {
    positionStreamSubscription?.cancel();
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
    if (driverLocation.value != null && mapController != null) {
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
            zoom: 18.0,
            tilt: 60.0,
            bearing: bearing,
          ),
        ),
      );
    }
  }

double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
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
 void _addMarkerWithoutBounds(LatLng latLng, {required bool isStartPlace, bool isDriver = false}) {
    final updatedMarkers = Set<Marker>.from(markers.value);

    if (isDriver) {
      updatedMarkers.removeWhere((m) => m.markerId.value == 'driver');
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('driver'),
          position: latLng,
          infoWindow: InfoWindow(title: 'Conductor'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

 void addMarker(LatLng latLng, {required bool isStartPlace, bool isDriver = false}) {
    _addMarkerWithoutBounds(latLng, isStartPlace: isStartPlace, isDriver: isDriver);
    
    // Only update bounds if mapController is initialized
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
      Get.snackbar(
          'Error', 'Los permisos de ubicación están denegados permanentemente');
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
      _addMarkerWithoutBounds(driverLocation.value!, isStartPlace: false, isDriver: true);
      
    if (travelList.isNotEmpty) {
  String idStatusString = travelList[0].id_status.toString(); 
  int idStatus = int.tryParse(idStatusString) ?? 0;

  // Mantener seguimiento automático en estados 3 y 4
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

  int idStatus = travelList.isNotEmpty ? 
      (int.tryParse(travelList[0].id_status.toString()) ?? 0) : 0;

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
        color: Colors.blue,
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
          color: Colors.red,
          width: 5,
        ));

        polylines.value = updatedPolylines;
      } catch (e) {
        print('Error al trazar la ruta del conductor al inicio: $e');
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

      final updatedPolylines = Set<Polyline>.from(polylines.value);
      // Remove any existing routes
      updatedPolylines.clear();
      updatedPolylines.add(Polyline(
        polylineId: PolylineId('driver_to_end'),
        points: polylineCoordinates,
        color: Colors.blue,
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

  void startTravel(BuildContext context) {
    String travelId = travelList.isNotEmpty ? travelList[0].id.toString() : '';

    if (travelId.isEmpty) {
      CustomSnackBar.showError('Error', 'No se encontró el ID del viaje');
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Confirmar Inicio de Viaje',
      text: '¿Estás seguro de que deseas iniciar el viaje?',
      confirmBtnText: 'Sí',
      cancelBtnText: 'No',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        startTravelController
            .starttravel(StartravelEvent(id_travel: travelList[0].id));
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        startTravelController.starttravelState.listen((state) {
          if (state is StarttravelLoading) {
          } else if (state is AcceptedtravelSuccessfully) {
            travelStage.value = TravelStage.terminarViaje;

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
      context: context,
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
  ),      confirmBtnText: 'Sí',
      cancelBtnText: 'No',
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();
        endTravelController
            .endtravel(EndTravelEvent(id_travel: travelList[0].id));
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

        endTravelController.endtravelState.listen((state) async {
          if (state is EndtravelSuccessfully) {
            journeyCompleted.value = true;
            travelStage.value = TravelStage.heLlegado;

         
        CustomSnackBar.showSuccess('Éxito', 'Viaje terminado correctamente');
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

void CancelTravel(BuildContext context) {
  int travelId = travelList.isNotEmpty ? travelList[0].id : 0;
int driverId = travelList.isNotEmpty ? int.parse(travelList[0].id_travel_driver) : 0;
  
   final travel = Travelwithtariff(
                        travelId: travelId,
                        tarifa: 0,
                        driverId: driverId);

  final event = RejecttravelOfferEvent(travel: travel);
  rejectTravelOfferGetx.rejectTravelOfferGetx(event);
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

  rejectTravelOfferGetx.acceptedtravelState.listen((state) {
    if (state is RejectTravelOfferSuccessfully) {
      CustomSnackBar.showSuccess('Éxito', 'Viaje cancelado correctamente');
      
     
      
      currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
    } else if (state is RejectTravelOfferError) {
      CustomSnackBar.showSuccess('Error', rejectTravelOfferGetx.message.value);
    }
  });
}void onMapCreated(GoogleMapController controller) {
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
    
    // Solo ejecutar para estados que no son 3 o 4
    if (!shouldTrackDriver.value) {
      LatLngBounds bounds = createLatLngBoundsFromMarkers();
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50)
      );
    }
  }
}
