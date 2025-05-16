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
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false, // Evita reconstrucción al mostrar teclado
        backgroundColor: Theme.of(context).primaryColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // El mapa ahora es un widget separado para mejor rendimiento
              TravelMapWidget(controller: controller),
              
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
              
              // Widget de estado de espera
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
              
              // Botones inferiores
              TravelActionButtons(controller: controller, context: context),
            ],
          ),
        ),
      )
    );
  }
}

// Separamos el mapa en un widget independiente
class TravelMapWidget extends StatelessWidget {
  final AcceptTravelController controller;
  
  const TravelMapWidget({Key? key, required this.controller}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
          // Usamos un widget con mantención de estado para el mapa
          return MapWidget(
            controller: controller,
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
    });
  }
}

// Widget específico para el mapa con StatefulWidget para preservar estado
class MapWidget extends StatefulWidget {
  final AcceptTravelController controller;
  
  const MapWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Mantiene el estado del mapa
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    
    return GoogleMap(
      onMapCreated: widget.controller.onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.controller.startLocation.value ?? widget.controller.center,
        zoom: 12.0,
      ),
      markers: widget.controller.markers.value,
      polylines: widget.controller.polylines.value,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
    );
  }
}

// Widget para los botones de acción
class TravelActionButtons extends StatelessWidget {
  final AcceptTravelController controller;
  final BuildContext context;
  
  const TravelActionButtons({
    Key? key, 
    required this.controller,
    required this.context
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Obx(() {
        if (controller.travelByIdController.state.value
            is TravelByIdAlertLoaded) {
         if (!controller.isIdStatusOne.value) {
         
          return ElevatedButton(
            onPressed: controller.isRejectingTravel.value
              ? null
              : () async {
                  controller.rejectTravel2();
                },
            child: controller.isRejectingTravel.value
              ? SpinKitThreeBounce(
                  color: Colors.white,
                  size: 20.0,
                )
              : Text('Regresar al inicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.buttonColormap,
              disabledBackgroundColor: Colors.grey[400],
              padding:
                  EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              textStyle: TextStyle(fontSize: 18),
            ),
          );
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
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isRejectingTravel.value
                    ? null  // Deshabilita el botón durante la carga
                    : () {
                        controller.rejectTravel();
                      },
                  child: controller.isRejectingTravel.value
                    ? SpinKitThreeBounce(  // Muestra el loader cuando está cargando
                        color: Colors.white,
                        size: 20.0,
                      )
                    : FittedBox(
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
                    disabledBackgroundColor: Colors.grey[400],  // Color cuando está deshabilitado
                  ),
                )),
              ),

              SizedBox(width: screenWidth < 360 ? 5 : 10),
              
              Flexible(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isButtonEnabled.value
                    ? () => controller.openAmountDialog(context)
                    : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Negociar Viaje',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isButtonEnabled.value
                      ? Theme.of(context).colorScheme.buttonColormap
                      : Colors.grey[400],
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    disabledBackgroundColor: Colors.grey[400],
                    disabledForegroundColor: Colors.white70,
                  ),
                )),
              ),
            ],
          );
        }
      } else if (controller.travelByIdController.state.value
          is TravelByIdAlertLoading) {
        return Center(child: CircularProgressIndicator());
      } else if (controller.travelByIdController.state.value
          is TravelByIdAlertFailure) {
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
                    TravelByIdEventDetailsEvent(idTravel: controller.idTravel),
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
}