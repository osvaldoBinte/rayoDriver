import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';

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
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();
  final NotificationController notificationController = Get.find<NotificationController>();
  final TravelByIdAlertGetx travelByIdController = Get.find<TravelByIdAlertGetx>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print('App resumed - Fetching current travel details');
      final message = notificationController.lastNotification.value;
    final travelId = int.tryParse(notificationController.lastTravelId.value);

      if (message != null && message.notification?.title != null ) {
        print('DEBUG: Fetching travel details for ID: $travelId');
        
        travelByIdController.fetchCoDetails(
          TravelByIdEventDetailsEvent(idTravel: travelId)
        );
      }
      
      currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}