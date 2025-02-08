import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/id_device_get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/renew_token.dart';
import 'package:rayo_taxi/features/travel/data/datasources/background_location_handler.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/DriverArrival/driverArrival_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel_id/map_data_controller.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:rayo_taxi/common/settings/enviroment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rayo_taxi/common/theme/my_app.dart';
import 'package:rayo_taxi/usecase_config.dart';

import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/get/get_driver_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/AcceptedTravel/acceptedTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/StartTravel/startTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/EndTravel/endTravel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelWithTariff/travelWithTariff_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/acceptWithCounteroffe/accept_with_counteroffe_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/cancelTravel/cancelTravel_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/removeDataAccount/removeDataAccount_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/offerNegotiation/offer_negotiation_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/rejectTravelOffer/reject_travel_offer_getx.dart';
import 'connectivity_service.dart';
import 'package:flutter/services.dart';

void setupMemoryMonitoring() {  
  const duration = Duration(minutes: 5);
  Stream.periodic(duration).listen((_) {
    final memory = ProcessInfo.currentRss;
    print('Uso de memoria: ${memory ~/ 1024 ~/ 1024}MB');
  });
}

final connectivityService = ConnectivityService();
UsecaseConfig usecaseConfig = UsecaseConfig();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String enviromentSelect = Enviroment.development.value; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupMemoryMonitoring(); 
  await LocationHandler.initialize();

  print('=========ENVIROMENT SELECTED: $enviromentSelect');
  await dotenv.load(fileName: enviromentSelect);

  Get.put(TravelByIdAlertGetx(
      travelByIdUsecase: usecaseConfig.travelByIdUsecase!,
      connectivityService: connectivityService));
  Get.put(NotificationController());
  Get.put(CurrentTravelGetx(
      currentTravelUsecase: usecaseConfig.currentTravelUsecase!,
      connectivityService: connectivityService));
  Get.put(TravelsAlertGetx(
      travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(NotificationService(navigatorKey));

  await Get.find<NotificationService>().initialize();
  initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  Get.put(RenewTokenGetx(renewTokenUsecase: usecaseConfig.renewTokenUsecase!));
  Get.put(
      LogindriverGetx(loginDriverUsecase: usecaseConfig.loginDriverUsecase!));
  Get.put(GetDriverGetx(
      getDriverUsecase: usecaseConfig.getDriverUsecase!,
      connectivityService: connectivityService));
  Get.put(DeviceGetx(idDeviceUsecase: usecaseConfig.idDeviceUsecase!));

  Get.put(MapDataController(
      getEncodedPointsUsecase: usecaseConfig.getEncodedPointsUsecase,
      decodePolylineUsecase: usecaseConfig.decodePolylineUsecase,
      getRouteUsecase: usecaseConfig.getRouteUsecase));

  Get.put(GetDeviceGetx(getDeviceUsecase: usecaseConfig.getDeviceUsecase!));
  Get.put(AcceptedtravelGetx(
      acceptedTravelUsecase: usecaseConfig.acceptedTravelUsecase!));
  Get.put(
      StarttravelGetx(startTravelUsecase: usecaseConfig.startTravelUsecase!));
  Get.put(EndtravelGetx(endTravelUsecase: usecaseConfig.endTravelUsecase!));
  Get.put(ChangeavailabilityGetx(
      changeAvailabilityUsecase: usecaseConfig.changeAvailabilityUsecase!));
  Get.put(DriverarrivalGetx(
      driverArrivalUsecase: usecaseConfig.driverArrivalUsecase!));
  Get.put(TravelwithtariffGetx(
      confirmTravelWithTariffUsecase:
          usecaseConfig.confirmTravelWithTariffUsecase!));
  Get.put(AcceptWithCounteroffeGetx(
      acceptWithCounteroffeUsecase:
          usecaseConfig.acceptWithCounteroffeUsecase!));
  Get.put(CanceltravelGetx(
      cancelTravelUsecase: usecaseConfig.cancelTravelUsecase!));
  Get.put(RemovedataaccountGetx(
      removeDataAccountUsecase: usecaseConfig.removeDataAccountUsecase!));
  Get.put(OfferNegotiationGetx(
      offerNegotiationUsecase: usecaseConfig.offerNegotiationUsecase!));
  Get.put(RejectTravelOfferGetx(
      rejectTravelOfferUsecase: usecaseConfig.rejectTravelOfferUsecase!));
  Get.put(NavigationService());

  runApp(MyApp());
  
}
