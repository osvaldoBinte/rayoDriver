import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/firebase_options.dart';
import 'package:rayo_taxi/features/travel/domain/entities/TravelwithtariffEntitie/travelwithtariff.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/acceptWithCounteroffe/accept_with_counteroffe_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/offerNegotiation/offer_negotiation_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/rejectTravelOffer/reject_travel_offer_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? channel;
  final GlobalKey<NavigatorState> navigatorKey;
  final currentTravelGetx = Get.find<CurrentTravelGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();

  RemoteMessage? initialMessage;

  NotificationService(this.navigatorKey);
  String? _pendingErrorMessage;

  bool _initialMessageProcessed = false;
  Future<void> initialize() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await _setupNotificationChannels();

    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.high,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null && payload.isNotEmpty) {
          
          Map<String, dynamic> data = json.decode(payload);
          String? title = data['notification']?['title'] ?? data['title'];
          _handleNotificationClick(data, title);
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && !_initialMessageProcessed) {
      print('Cold start with notification: ${initialMessage?.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialMessage(initialMessage!);
      });
    }

    FirebaseMessaging.onMessage.listen(_onMessageHandler);

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background notification clicked: ${message.data}');
      _handleNotificationNavigation(message);
    });
  
  }

  

  void _handleNotificationNavigation(RemoteMessage message) {
    final NotificationController notificationController =
        Get.find<NotificationController>();
            notificationController.updateNotification(message); 
    final message2 = notificationController.lastNotification.value;






    final int? travelId = int.tryParse(message.data['travel'] ?? '');
    print('TravelId: $travelId');
    if (message2 != null && message2.notification?.title != null) {
      final title = message2.notification!.title!;
      if (title == 'Nuevo viaje!!') {
        print('Navigating to AcceptTravelPage with travel ID: $travelId');
       
        if (travelId != null) {
                    _handleNotificationClick(message.data, title);

         // Get.offAll(() => AcceptTravelPage(idTravel: travelId));
        } else {
          print('Error: travelId is null');
        }
      } else {
        print('Navigating to HomePage');
        navigateToHome();
        }
    }
  }

  Future<void> _onMessageHandler(RemoteMessage message) async {
    print('Mensaje recibido en primer plano: ${message.messageId}');
    final context = navigatorKey.currentState?.overlay?.context;
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    final travelId = int.tryParse(message.data['travel'] ?? '');

    final title = notification?.title ?? 'Notificación';
    final body = notification?.body ?? 'Tienes una nueva notificación';
    Get.find<NotificationController>().updateNotification(message);
    final TravelByIdAlertGetx travelByIdController =
        Get.find<TravelByIdAlertGetx>();
    if (notification != null && android != null) {
      if (context != null) {
        if (title == 'Nuevo precio del viaje' ||
            title == 'Propuesta de viaje rechazada' ||
            title == 'Nuevo viaje!!') {
                    _showQuickAlert(context, title, body);

        } else if (title == 'Nuevo precio para tu viaje') {
     await _waitForOperationsToComplete(
      currentTravelGetx: Get.find<CurrentTravelGetx>(),
      travelByIdController: Get.find<TravelByIdAlertGetx>(),
       travelAlertGetx:  Get.find<TravelsAlertGetx>(),
      travelId: travelId,
    );

    if (context.mounted) { 
      showNewPriceDialog(context);
    }
          
        }else if (body == 'El cliente ha aceptado la propuesta para el viaje.' ||
            title == "Contraoferta aceptada por el cliente") {
          _waitForOperationsToComplete(
      currentTravelGetx: Get.find<CurrentTravelGetx>(),
      travelByIdController: Get.find<TravelByIdAlertGetx>(),
       travelAlertGetx:  Get.find<TravelsAlertGetx>(),
      travelId: travelId,
    );

    if (context.mounted) { 
          showacept(context, title, body);
    }
        }  else {
          print('El contexto es nulo o el título no coincide');
        }
      }

      _showLocalNotification(message);
    }
  }
Future<void> _waitForOperationsToComplete({
  required CurrentTravelGetx currentTravelGetx,
  required TravelByIdAlertGetx travelByIdController,
  required TravelsAlertGetx travelAlertGetx,
  required int? travelId,
}) async {
  final currentTravelCompleter = Completer();
  final travelByIdCompleter = Completer();
  final travelAlerCompleter = Completer();

  ever(currentTravelGetx.state, (state) {
    if (state is TravelAlertLoaded || state is TravelAlertFailure) {
      if (!currentTravelCompleter.isCompleted) {
        currentTravelCompleter.complete();
      }
    }
  });

  ever(travelByIdController.state, (state) {
    if (state is TravelByIdAlertLoaded || state is TravelByIdAlertFailure) {
      if (!travelByIdCompleter.isCompleted) {
        travelByIdCompleter.complete();
      }
    }
  });
 ever(travelAlertGetx.state, (state) {
    if (state is TravelsAlertLoaded || state is TravelsAlertFailure) {
      if (!travelAlerCompleter.isCompleted) {
        travelAlerCompleter.complete();
      }
    }
  });
  currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
  travelByIdController.fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: travelId));
  travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

  await Future.wait([
    currentTravelCompleter.future,
    travelByIdCompleter.future,
    travelAlerCompleter.future
  ]);
}


  void showacept(BuildContext context, String title, String body) {
    currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () async {
        await AuthService().clearCurrenttravel();
        currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
        navigateToHome();
      },
    );
  }
  Future<void> _setupNotificationChannels() async {
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);
  }

  void _processColdStartNotification(RemoteMessage message) {
    print('Processing cold start notification');
    final String? title = message.notification?.title;
    final int? travelId = int.tryParse(message.data['travel'] ?? '');

    print('Cold start - Title: $title, TravelId: $travelId');

    if (title == 'Nuevo viaje!!' && travelId != null) {
      print('Attempting navigation to AcceptTravelPage');
      navigateToacceptTravel(travelId);
    }
  }

  void _onMessageOpenedAppHandler(RemoteMessage message) {
    print(
        'El usuario hizo clic en una notificación mientras la app estaba en segundo plano');
    _handleNotificationNavigation(message);
    initialMessage = message;
  }

  void _handleInitialMessage(RemoteMessage message) {
    if (_initialMessageProcessed) return;
    _initialMessageProcessed = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      _handleNotificationNavigation(message);
    });
  }
  void _showErrorAndNavigate(BuildContext? context, String message) {
    if (context != null) {

      CustomSnackBar.showError('Error', message);
      Navigator.of(context).pop();
      navigateToHome();
    } else {

      _pendingErrorMessage = message;
      navigateToHome();
    }
  }

    Future<void> _handleTravelFetch(int? travelId, BuildContext? context) async {
    if (travelId == null) {
      _showErrorAndNavigate(context, 'Viaje no encontrado');
      return;
    }

    try {
      final travelByIdController = Get.find<TravelByIdAlertGetx>();
      await travelByIdController.fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: travelId));
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state = travelByIdController.state.value;
      
      if (state is TravelByIdAlertLoaded) {
        Get.offAll(() => AcceptTravelPage(idTravel: travelId));
      } else if (state is TravelByIdAlertFailure) {
        _showErrorAndNavigate(context, 'Viaje ya fue aceptado');
      }
    } catch (e) {
      print('Error fetching travel details: $e');
      _showErrorAndNavigate(context, 'Error al obtener detalles del viaje');
    }
  }
 void _handleNotificationClick(Map<String, dynamic> data, String? title) {
    final int? travelId = int.tryParse(data['travel'] ?? '');
    final context = navigatorKey.currentState?.overlay?.context;

    if (title == 'Nuevo viaje!!') {
      _handleTravelFetch(travelId, context);
    } else {
      navigateToHome();
    }
  }

  void _showQuickAlert(BuildContext context, String title, String body) {
    final NotificationController notificationController =
        Get.find<NotificationController>();
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        if (title == 'Nuevo viaje!!') {
          final message = notificationController.lastNotification.value;
          if (message != null && message.notification?.title != null) {
            _handleNotificationClick(message.data, title);

          }

        } else if (title == 'Nuevo precio del viaje') {
             AuthService().clearCurrenttravel();
                   currentTravelGetx.fetchCoDetails(FetchgetDetailsEvent());
        Navigator.of(context).pop();

        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void showNewPriceDialog(BuildContext context) {
    //final travelId = int.tryParse(message.data['travel'] ?? '');
    final state = currentTravelGetx.state.value;

    if (state is! TravelAlertLoaded) {
      print("Error: No travel data available.");
      return;
    }

    final travel = state.travels.first;

    final travelId = travel.id;
    final driverId = int.parse(travel.id_travel_driver);

    print('-------- $driverId travel $travelId tarifa ');

    Future.delayed(Duration(milliseconds: 500), () {
      final TextEditingController priceController = TextEditingController();
      final RxString inputAmount = "".obs;
      final RxString buttonText = "Confirmar".obs;
      String _getTravelPriceText() {
        final state = currentTravelGetx.state.value;
        if (state is TravelAlertLoaded) {
          final travel = state.travels.first;
          return 'El cliente envió una oferta de \$${travel.tarifa} MXN para tu viaje';
        }
        return 'Cargando...';
      }

      QuickAlert.show(
        context: context,
        type: QuickAlertType.custom,
        title: 'Negociación de Oferta',
        showCancelBtn: false,
        showConfirmBtn: false,
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              text: TextSpan(
                text: 'El cliente envió una oferta de ',
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(
                    text: '\$${travel.tarifa} MXN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: ' para tu viaje.',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
            Obx(() => Text(
                  inputAmount.value.isNotEmpty
                      ? 'Monto ofertado: \$${inputAmount.value}'
                      : '',
                  style: TextStyle(fontSize: 16),
                )),
            SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                inputAmount.value = value;
                buttonText.value =
                    value.isNotEmpty ? "Ofertar \$${value}" : "Aceptar";
              },
              decoration: InputDecoration(
                labelText: 'Importe \$ MXN',
                hintText: '',
                labelStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.buttonColormap,
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    Get.back();

                    final rejectController = Get.find<RejectTravelOfferGetx>();
                    final travel = Travelwithtariff(
                        travelId: travelId,
                        tarifa: int.tryParse(inputAmount.value) ?? 0,
                        driverId: driverId);
                    final event = RejecttravelOfferEvent(travel: travel);

                    await rejectController.rejectTravelOfferGetx(event);

                    if (rejectController.message.value
                        .contains('correctamente')) {
                      CustomSnackBar.showSuccess(
                        'Éxito',
                        rejectController.message.value,
                      );
                      await AuthService().clearCurrenttravel();

                    navigateToHome();
                    } else {
                      CustomSnackBar.showError(
                        'Error',
                        rejectController.message.value,
                      );
                    }
                  },
                  child: Text("Rechazar"),
                ),
                Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: () async {
                        if (inputAmount.value.isNotEmpty) {
                          final offerController =
                              Get.find<OfferNegotiationGetx>();
                          final travel = Travelwithtariff(
                              travelId: travelId,
                              tarifa: int.tryParse(inputAmount.value) ?? 0,
                              driverId: driverId);
                          final event = OffernegotiationEvent(travel: travel);

                          await offerController.OfferNegotiationtravel(event);

                          if (offerController.message.value
                              .contains('correctamente')) {
                            CustomSnackBar.showSuccess(
                              'Éxito',
                              offerController.message.value,
                            );
                            await AuthService().clearCurrenttravel();
                            navigateToHome();
                          } else {
                            CustomSnackBar.showError(
                              'Error',
                              offerController.message.value,
                            );
                          }
                        } else {
                          final travel = Travelwithtariff(
                              travelId: travelId,
                              tarifa: int.tryParse(inputAmount.value) ?? 0,
                              driverId: driverId);

                          final acceptController =
                              Get.find<AcceptWithCounteroffeGetx>();
                          final event =
                              AcceptwithcounteroffeEvent(travel: travel);

                          await acceptController.acceptedtravel(event);

                          if (acceptController.message.value
                              .contains('correctamente')) {
                            CustomSnackBar.showSuccess(
                              'Éxito',
                              acceptController.message.value,
                            );
                          await AuthService().clearCurrenttravel();
                            navigateToHome();
                          } else {
                            CustomSnackBar.showError(
                              'Error',
                              acceptController.message.value,
                            );
                            Get.back();
                          }
                        }
                      },
                      child: Text(buttonText.value),
                    )),
              ],
            ),
          ],
        ),
      );
    });
  }
void navigateToacceptTravel(int travelId) {
 Get.offAllNamed(
      RoutesNames.acceptTravelPage,
      arguments: {'idTravel': travelId},
    );
}

void navigateToHome() {
  Get.offAllNamed(
      RoutesNames.homePage,
      arguments: {'selectedIndex': 1},
    );
}
  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      final Map<String, dynamic> payloadData = {
        'travel': message.data['travel'],
        'title': notification.title,
        'body': notification.body,
        'originalData': message.data,
      };

      print('Enviando notificación local con payload: ${jsonEncode(payloadData)}');

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel!.id,
            channel!.name,
            channelDescription: channel!.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            autoCancel: true,
            enableLights: true,
            enableVibration: true,
          ),
        ),
        payload: jsonEncode(payloadData),
      );
    }
  }
}
