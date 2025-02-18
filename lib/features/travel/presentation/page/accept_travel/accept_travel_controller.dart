import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/AcceptedTravel/acceptedTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelWithTariff/travelWithTariff_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/main.dart';

import '../../../../../common/routes/ navigation_service.dart';

class AcceptTravelController extends GetxController {
  final int? idTravel;

  AcceptTravelController({required this.idTravel});

  final TravelwithtariffGetx travelwithtariffGetx =
      Get.find<TravelwithtariffGetx>();

  final AcceptedtravelGetx acceptedGetx = Get.find<AcceptedtravelGetx>();
  final TravelByIdAlertGetx travelByIdController =
      Get.find<TravelByIdAlertGetx>();
  bool isSnackbarVisible = false;

  final ChangeavailabilityGetx _driverGetx = Get.find<ChangeavailabilityGetx>();
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Rxn<LatLng> startLocation = Rxn<LatLng>();
  Rxn<LatLng> endLocation = Rxn<LatLng>();
  Rxn<LatLng> driverLocation = Rxn<LatLng>();
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  RxBool isIdStatusSix = false.obs;
  RxBool isIdStatusOne = false.obs;
  RxString waitingFor = ''.obs;
  late BitmapDescriptor startIcon;
  final RxBool isValidAmount = false.obs;

  late GoogleMapController mapController;
  final MapaLocalDataSource travelLocalDataSource = MapaLocalDataSourceImp();


  StreamSubscription<Position>? positionStreamSubscription;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  RxString amount = ''.obs;
  TextEditingController amountController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    // Limpiar estado inicial
    markers.clear();
    polylines.clear();
    startLocation.value = null;
    endLocation.value = null;
    driverLocation.value = null;
    isIdStatusSix.value = false;
    isIdStatusOne.value = false;
    waitingFor.value = '';
    _loadCustomMarker();
    print('id desde page desde onInit $idTravel');
    final ChangeavailabilityGetx _driverGetx =
        Get.find<ChangeavailabilityGetx>();
    final vailability = ChangeAvailabilityEntitie(status: false);
    await _driverGetx.execute(
        ChangeaVailabilityEvent(changeAvailabilityEntitie: vailability));
    ever(travelByIdController.state, (state) {
      if (state is TravelByIdAlertLoaded) {
        TravelAlertModel travel = state.travels[0];
        print('id desde page desde  TravelAlertModel travel ${travel.id}');
        isIdStatusSix.value = travel.id_status == 6;
        isIdStatusOne.value = travel.id_status == 1;

        waitingFor.value = travel.waiting_for ?? '';
        print('====== travel.status ${travel.status}');
        print('====== travel.waiting_for ${travel.waiting_for}');
        print('======  waitingFor.value ${waitingFor.value}');
        print('====== isIdStatusSix ${isIdStatusSix.value}');

        double? startLatitude = double.tryParse(travel.start_latitude);
        double? startLongitude = double.tryParse(travel.start_longitude);
        double? endLatitude = double.tryParse(travel.end_latitude);
        double? endLongitude = double.tryParse(travel.end_longitude);

        if (startLatitude != null &&
            startLongitude != null &&
            endLatitude != null &&
            endLongitude != null) {
          startLocation.value = LatLng(startLatitude, startLongitude);
          endLocation.value = LatLng(endLatitude, endLongitude);

          addMarker(startLocation.value!, isStartPlace: true);
          addMarker(endLocation.value!, isStartPlace: false);

          traceRoute();
        }
      } else if (state is TravelByIdAlertFailure) {
        print('Error al cargar los detalles del viaje: ${state.error}');
      }
    });

    print('id desde page antest de  travelByIdController $idTravel');
    travelByIdController
        .fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: idTravel));
    print('id desde page despues de  travelByIdController $idTravel');

    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        travelByIdController
            .fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: idTravel));
      }
    });
  }

  Future<void> _loadCustomMarker() async {
    startIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/mapa/origen.png',
    );
  }

  @override
  void onClose() {
    positionStreamSubscription?.cancel();
    connectivitySubscription.cancel();
    amountController.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (markers.isNotEmpty) {
      LatLngBounds bounds = createLatLngBoundsFromMarkers();
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } else {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  LatLngBounds createLatLngBoundsFromMarkers() {
    if (markers.isEmpty) {
      return LatLngBounds(northeast: center, southwest: center);
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
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  void addMarker(LatLng latLng,
      {required bool isStartPlace, bool isDriver = false}) async {
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
          icon: startIcon,
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
          icon: await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(48, 48)),
            'assets/images/mapa/destino.png',
          ),
        ),
      );
      endLocation.value = latLng;
    }

    markers.value = updatedMarkers;
  }

  Future<void> traceRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);

        final updatedPolylines = Set<Polyline>.from(polylines.value);
        updatedPolylines
            .removeWhere((polyline) => polyline.polylineId.value == 'route');
        updatedPolylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.black,
          width: 5,
        ));

        polylines.value = updatedPolylines;
      } catch (e) {
        print('Error al trazar la ruta: $e');
      }
    }
  }

  void processAmount() {
    if (amount.value.isEmpty) {
      CustomSnackBar.showError('Error', 'Por favor ingrese un monto válido');

      return;
    }

    double? parsedAmount = double.tryParse(amount.value);
    if (parsedAmount == null || parsedAmount <= 0) {
      CustomSnackBar.showError('Error', 'Por favor ingrese un monto válido');

      return;
    }
  }

  Future<void> acceptTravel(BuildContext context) async {
    try {
      await acceptedGetx.acceptedtravel(AcceptedTravelEvent(
        id_travel: idTravel,
      ));

      if (acceptedGetx.acceptedtravelState.value
          is AcceptedtravelSuccessfully) {
        await AuthService().clearCurrenttravel();
        CustomSnackBar.showSuccess('Éxito', 'Viaje aceptado correctamente');
        await NavigationService.to.navigateToHome();

//    navigateToHome();
      } else if (acceptedGetx.acceptedtravelState.value
          is AcceptedtravelError) {
        CustomSnackBar.showError(
            'Error', 'El viaje ya fue aceptado o falló la solicitud');
        await rejectTravel();
      }
    } catch (e) {
      CustomSnackBar.showError(
          'Error', 'El viaje ya fue aceptado o falló la solicitud');
      await rejectTravel();
    }
  }

  Future<void> rejectTravel() async {
    try {
      await AuthService().clearCurrenttravel();

      final availability = ChangeAvailabilityEntitie(status: true);
      await _driverGetx.execute(
          ChangeaVailabilityEvent(changeAvailabilityEntitie: availability));

      // Usar el servicio de navegación
      await NavigationService.to.navigateToHome();
    } catch (e) {
      print('Error en rejectTravel: $e');
      // Manejar el error apropiadamente
    }
  }
 Future<void> rejectTravel2() async {
    try {
      await AuthService().clearCurrenttravel();

     
      // Usar el servicio de navegación
      await NavigationService.to.navigateToHome();
    } catch (e) {
      print('Error en rejectTravel: $e');
      // Manejar el error apropiadamente
    }
  }
  Future<void> processAndSubmitAmount(String montoStr) async {
    if (montoStr.isEmpty) {
      CustomSnackBar.showError('Error', 'Por favor ingresa un monto válido');
      return;
    }

    int? monto = int.tryParse(montoStr);
    if (monto == null || monto <= 0) {
      CustomSnackBar.showError(
          'Error', 'Por favor ingresa un monto numérico válido');
      return;
    }

    try {
      final travel = Travelwithtariff(id: idTravel, tarifa: monto);
      final event = TravelWithtariffEvent(travel: travel);

      await travelwithtariffGetx.travelwithtariffGetx(event);

      if (travelwithtariffGetx.state.value is TravelwithtariffSuccessfully) {
        Get.back();

        CustomSnackBar.showSuccess(
            'Éxito', 'Monto de tarifa procesado y enviado correctamente');
        await AuthService().clearCurrenttravel();
        await travelByIdController
            .fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: idTravel));
      } else if (travelwithtariffGetx.state.value is TravelwithtariffFailure) {
        CustomSnackBar.showError(
            'Error', 'El viaje ya fue aceptado o falló la solicitud');
        await rejectTravel();
      }
    } catch (e) {
      CustomSnackBar.showError(
          'Error', 'El viaje ya fue aceptado o falló la solicitud');
      await rejectTravel();
      print('Error en processAndSubmitAmount: $e');
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}';
      }
      return 'Dirección no disponible';
    } catch (e) {
      print('Error getting address: $e');
      return 'Dirección no disponible';
    }
  }
  
  
void showInputAmountAlert(
    BuildContext context, AcceptTravelController controller) {
  final TextEditingController localAmountController = TextEditingController();
  
  Future<void> disposeController() async {
    if (localAmountController.text.isNotEmpty) {
      localAmountController.clear();
    }
    localAmountController.dispose();
  }
  
  final RxString inputAmount = "".obs;
  final travel = (controller.travelByIdController.state.value
          is TravelByIdAlertLoaded)
      ? (controller.travelByIdController.state.value as TravelByIdAlertLoaded)
          .travels[0]
      : null;
  final travelCost = travel?.cost ?? '0';
  final RxString buttonText = "Confirmar \$${travelCost}".obs;
  final RxBool isLoading = false.obs;
  final RxString startAddress = "Cargando dirección...".obs;
  final RxString endAddress = "Cargando dirección...".obs;

  if (travel != null) {
    getAddressFromCoordinates(
      double.parse(travel.start_latitude),
      double.parse(travel.start_longitude),
    ).then((address) => startAddress.value = address);

    getAddressFromCoordinates(
      double.parse(travel.end_latitude),
      double.parse(travel.end_longitude),
    ).then((address) => endAddress.value = address);
  }

  showCustomAlert(
    context: Get.context!,
    type: CustomAlertType.warning,
    title: 'Nueva oferta',
    message: '',
    confirmText: '',
    cancelText: null,
    customWidget: Obx(() {
      if (isLoading.value) {
        return Center(
          child: SpinKitThreeInOut(
            color: Theme.of(context).primaryColor,
            size: 50.0,
          ),
        );
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Información de dirección
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildAddressRow(
                              'assets/images/mapa/origen.png',
                              'Origen:',
                              startAddress,
                            ),
                            const SizedBox(height: 8),
                            _buildAddressRow(
                              'assets/images/mapa/destino.png',
                              'Destino:',
                              endAddress,
                            ),
                          ],
                        ),
                      ),

                      // Costo del viaje
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: RichText(
                          text: TextSpan(
                            text: 'Costo del viaje ',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: '\$${travelCost.toString()} MXN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Input y botón (siempre visibles)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de entrada
                  TextField(
                    controller: localAmountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      inputAmount.value = value;
                      buttonText.value = value.isNotEmpty
                          ? "Ofertar \$${value}"
                          : "Confirmar \$${travelCost}";
                    },
                    decoration: InputDecoration(
                      labelText: 'Importe \$ MXN',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón de acción
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isLoading.value) return;
                        
                        final String montoStr = localAmountController.text.trim();
                        
                        if (montoStr.isNotEmpty) {
                          final double inputAmount = double.parse(montoStr);
                          final double cost = double.parse(travelCost.toString());
                          
                          if (inputAmount < cost) {
                            QuickAlert.show(
                              context: Get.context!,
                              type: QuickAlertType.error,
                              title: 'Importe inválido',
                              text: 'El monto ofertado debe ser mayor al costo del viaje',
                            );
                            return;
                          }
                          isLoading.value = true;
                          try {
                            await controller.processAndSubmitAmount(montoStr);
                            await disposeController();
                            Get.back();
                          } finally {
                            isLoading.value = false;
                          }
                        } else {
                          isLoading.value = true;
                          try {
                            await controller.acceptTravel(Get.context!);
                            await disposeController();
                            Get.back();
                          } finally {
                            isLoading.value = false;
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.buttonColormap2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Obx(() => Text(
                        buttonText.value,
                        style: const TextStyle(fontSize: 14),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }),
  );
}

Widget _buildAddressRow(String imagePath, String label, RxString address) {
  return Row(
    children: [
      Image.asset(
        imagePath,
        width: 16,
        height: 16,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Obx(() => Text(
                  address.value,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )),
          ],
        ),
      ),
    ],
  );
}
}
