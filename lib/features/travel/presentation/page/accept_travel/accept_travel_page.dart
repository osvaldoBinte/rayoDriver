import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelWithTariff/travelWithTariff_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/travel_route_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/waiting_status_widget.dart';
import 'package:rayo_taxi/main.dart';

class AcceptTravelPage extends StatelessWidget {
  final int idTravel;
  
  final TravelwithtariffGetx travelWithTariffController =
      Get.find<TravelwithtariffGetx>();
  final NotificationController notificationController =
      Get.find<NotificationController>();
  final notificationService = Get.find<NotificationService>();

  AcceptTravelPage({required this.idTravel});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<AcceptTravelController>()) {
      Get.delete<AcceptTravelController>();
    }

    final AcceptTravelController controller =
        Get.put(AcceptTravelController(idTravel: idTravel));

    return WillPopScope(
      onWillPop: () async {
        // Retornar false evita que el botón de retroceso funcione
        return false;
      },
      child:  Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              if (controller.travelByIdController.state.value
                  is TravelByIdAlertLoading) {
                return Center(
                  child: SpinKitDoubleBounce(
                    color: Theme.of(context).colorScheme.buttonColormap,
                    size: 50.0,
                  ),
                );
              } else if (controller.travelByIdController.state.value
                  is TravelByIdAlertFailure) {
                return Center(
                    child: Text((controller.travelByIdController.state.value
                            as TravelByIdAlertFailure)
                        .error));
              } else if (controller.travelByIdController.state.value
                  is TravelByIdAlertLoaded) {
                if (controller.startLocation.value != null &&
                    controller.endLocation.value != null) {
                  return GoogleMap(
                    onMapCreated: controller.onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target:
                          controller.startLocation.value ?? controller.center,
                      zoom: 12.0,
                    ),
                    markers: controller.markers.value,
                    polylines: controller.polylines.value,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              } else {
                return Center(
                  child: SpinKitDoubleBounce(
                    color: Theme.of(context).colorScheme.buttonColormap,
                    size: 50.0,
                  ),
                );
              }
            }),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.buttonColormap,
                child: Text(
                  'Negociación',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Obx(() {
              if (controller.travelByIdController.state.value
                  is TravelByIdAlertLoaded) {
                final state = controller.travelByIdController.state.value
                    as TravelByIdAlertLoaded;
                final routeController =
                    Get.put(TravelRouteController(travelList: state.travels));

                return WaitingStatusWidget(
                  isIdStatusSix: controller.isIdStatusSix.value,
                  waitingFor: controller.waitingFor.value,
                  notificationService: notificationService,
                  controller: routeController,
                );
              }
              return SizedBox.shrink();
            }),
            InfoButtonWidget(
                travelByIdController: controller.travelByIdController),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Obx(() {
                if (controller.travelByIdController.state.value
                    is TravelByIdAlertLoaded) {
                 if (!controller.isIdStatusOne.value) {
  return SizedBox.shrink();
}
else {
                    return Positioned(
  bottom: 30,
  left: 20,
  right: 20,
  child: Obx(() {
    if (controller.travelByIdController.state.value is TravelByIdAlertLoaded) {
      if (!controller.isIdStatusOne.value) {
        return SizedBox.shrink();
      } else {
        // Obtener el ancho de la pantalla
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Definir tamaños responsivos
        final double fontSize = screenWidth < 360 ? 14.0 : 18.0;
        final double horizontalPadding = screenWidth < 360 ? 10.0 : 20.0;
        final double verticalPadding = screenWidth < 360 ? 15.0 : 20.0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  controller.rejectTravel();
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rechazar Viaje',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth < 360 ? 5 : 10),
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  controller.showInputAmountAlert(context, controller);
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Negociar Viaje',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.buttonColormap,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    } else if (controller.travelByIdController.state.value is TravelByIdAlertLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (controller.travelByIdController.state.value is TravelByIdAlertFailure) {
      final screenWidth = MediaQuery.of(context).size.width;
      final double fontSize = screenWidth < 360 ? 14.0 : 18.0;
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error al cargar los detalles del viaje'),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.buttonColormap,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 30 : 50,
                  vertical: screenWidth < 360 ? 15 : 20,
                ),
                textStyle: TextStyle(fontSize: fontSize),
              ),
              onPressed: () {
                controller.travelByIdController.fetchCoDetails(
                  TravelByIdEventDetailsEvent(idTravel: idTravel),
                );
              },
              child: Text('Reintentar'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 30 : 50,
                  vertical: screenWidth < 360 ? 15 : 20,
                ),
                textStyle: TextStyle(fontSize: fontSize),
              ),
              onPressed: () {
                controller.rejectTravel();
              },
              child: Text('Regresar al inicio'),
            ),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }),
);
                  }
                } else if (controller.travelByIdController.state.value
                    is TravelByIdAlertLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (controller.travelByIdController.state.value
                    is TravelByIdAlertFailure) {
                  return Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error al cargar los detalles del viaje'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.buttonColormap,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          controller.travelByIdController.fetchCoDetails(
                            TravelByIdEventDetailsEvent(idTravel: idTravel),
                          );
                        },
                        child: Text('Reintentar'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          controller.rejectTravel();
                        },
                        child: Text('Regresar al inicio'),
                      ),
                    ],
                  ));
                } else {
                  return SizedBox();
                }
              }),
            ),
          ],
        ),
      ),
    )
    );
  }
}
