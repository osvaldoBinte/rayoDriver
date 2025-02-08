
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/travel_route_controller.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/waiting_status_widget.dart';
import 'package:speech_bubble/speech_bubble.dart';
class TravelRoute extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  TravelRoute({required this.travelList});

  @override
  _TravelRouteState createState() => _TravelRouteState();
}
class _TravelRouteState extends State<TravelRoute> with AutomaticKeepAliveClientMixin {
  late TravelRouteController controller;
  final NotificationController notificationController = Get.find<NotificationController>();
  final notificationService = Get.find<NotificationService>();
  GoogleMapController? _mapController;
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TravelRouteController(travelList: widget.travelList));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    Get.delete<TravelRouteController>();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController mapController) {
    _mapController = mapController;
    controller.mapController = mapController;
    
    LatLngBounds bounds = controller.createLatLngBoundsFromMarkers();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RepaintBoundary(
              child: Obx(() {
                final position = controller.startLocation.value ?? controller.center;
                return GoogleMap(
  onMapCreated: _onMapCreated,
  initialCameraPosition: CameraPosition(
    target: position,
    zoom: 12.0,
  ),
  markers: controller.markers.value,
  polylines: controller.polylines.value,
  myLocationEnabled: false,
  myLocationButtonEnabled: false, // Cambiar a false
  compassEnabled: true,
  tiltGesturesEnabled: true,
  rotateGesturesEnabled: true,
  zoomControlsEnabled: false,
  trafficEnabled: false,
);
              }),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GetBuilder<CurrentTravelGetx>(
                builder: (_) => Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ' ${widget.travelList[0].status}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

           Obx(() => WaitingStatusWidget(
  isIdStatusSix: controller.isIdStatusSix.value,
  waitingFor: widget.travelList[0].waiting_for,
  notificationService: notificationService,
  controller: controller,
)),
        /*    InfoButtonWidget(travel: widget.travelList[0]),
            FloatingActionButton(
  onPressed: controller.toggleDriverFollow,
  child: Icon(
    controller.isFollowingDriver.value 
      ? Icons.location_on 
      : Icons.location_off
  ),
),*/
            Positioned(
              bottom: 80,
              left: 10,
              right: 10,
              child: GetBuilder<CurrentTravelGetx>(
                builder: (_) => Obx(() {
                  if (controller.isIdStatusSix.value) {
                    return SizedBox.shrink();
                  }
                  bool isIdStatusFour = widget.travelList[0].id_status == 4;
                  bool canCancel = !isIdStatusFour && 
                                 controller.travelStage.value != TravelStage.terminarViaje;
                  
                  return // En la sección del Row dentro del Positioned bottom: 80
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: canCancel ? () => controller.cancelTravel(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.buttonColormap,
          ),
          child: Text('Cancelar Viaje'),
        ),
        if (widget.travelList[0].id_status == 3 || widget.travelList[0].id_status == 4)
  Padding(
    padding: EdgeInsets.only(top: 8),
    child: Obx(() => ElevatedButton.icon(
      onPressed: controller.isLoadingNavigation.value 
        ? null 
        : () async {
            if (widget.travelList[0].id_status == 3) {
              if (controller.useMapbox.value) {
                await controller.launchMapboxNavigationStart();
              } else {
                await controller.launchGoogleMapsNavigationStart();
              }
            } else {
              if (controller.useMapbox.value) {
                await controller.launchMapboxNavigationToDestination();
              } else {
                await controller.launchGoogleMapsNavigationToDestination();
              }
            }
          },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.buttonColormap,
      ),
      icon: controller.isLoadingNavigation.value
        ? SpinKitFadingCircle(
            color: Colors.white,
            size: 18.0,
          )
        : Icon(controller.useMapbox.value ? Icons.navigation : Icons.map),
      label: Text(
        controller.isLoadingNavigation.value 
          ? 'Cargando...' 
          : controller.useMapbox.value 
            ? 'Cómo llegar' 
            : 'Cómo llegar'
      )
    )),
  ),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isIdStatusFour)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => controller.completeTrip(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.buttongoNotification,
              ),
              icon: Icon(Icons.notification_important),
              label: Text('He llegado'),
            ),
          ),
        ElevatedButton(
  onPressed: controller.isLoadingStartJourney.value 
    ? null 
    : () => isIdStatusFour
        ? controller.endTravel(context)
        : controller.startTravel(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.buttonColormap,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (controller.isLoadingStartJourney.value)
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: SpinKitFadingCircle(
            color: Colors.white,
            size: 18.0,
          ),
        ),
      Text(isIdStatusFour 
        ? 'Terminar Viaje' 
        : controller.isLoadingStartJourney.value 
          ? 'Iniciando...' 
          : 'Iniciar Viaje'),
    ],
  ),
)
      ],
    ),
  ],
);
                }),
              ),
            ),
          ],
        ),
      ),
    );
 
  }
}