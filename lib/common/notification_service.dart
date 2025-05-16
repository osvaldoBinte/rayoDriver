import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/app/splash_screen.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/notificationcontroller/notification_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/accept_travel/accept_travel_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
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
  final travelByIdController = Get.find<TravelByIdAlertGetx>();

  RemoteMessage? initialMessage;

  NotificationService(this.navigatorKey);
  String? _pendingErrorMessage;

  bool _initialMessageProcessed = false;
  Future<void> initialize() async {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  await _setupNotificationChannels();
  
  FirebaseMessaging.onBackgroundMessage(
      NotificationController.firebaseMessagingBackgroundHandler);
NotificationSettings settings = await _messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones Importantes',
    description: 'Este canal se usa para notificaciones importantes.',
    importance: Importance.high,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
      );

  // Mejora el manejo de clics en las notificaciones
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      print('Received notification response: ${notificationResponse.id}');
      final String? payload = notificationResponse.payload;
      if (payload != null && payload.isNotEmpty) {
        print('Notification payload: $payload');
        try {
          Map<String, dynamic> data = json.decode(payload);
          String? title = data['notification']?['title'] ?? data['title'];
          print('Decoded payload - Title: $title, Travel: ${data['travel']}');
          _handleNotificationClick(data, title);
        } catch (e) {
          print('Error processing notification payload: $e');
          CustomSnackBar.showError('Error', 'Error al procesar la notificación');
        }
      } else {
        print('Empty payload received');
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

    ever(currentTravelGetx.state, (state) {
      if (state is TravelAlertLoaded) {
        final travel = state.travels.firstOrNull;
        if (travel != null) {
          _handleTravelStateChange(travel);
        }
      }
    });
  }

  Future<void> _handleTravelStateChange(TravelAlertModel travel) async {
    if (travel.waiting_for == "2" && travel.id_status == 6) {
      //  await Get.find<NavigationService>().navigateToHome(selectedIndex: 1);

      if (Get.context != null) {
        showNewPriceDialog(Get.context!);
      }
    }
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
  
  if (notification != null && context != null) {
    // Mostrar QuickAlert para "Nuevo viaje!!"
    if (title == 'Nuevo viaje!!' && travelId != null) {
      _showNuevoViajeAlert(context, title, body, travelId);
    } else {
      // Para otros tipos de notificaciones, mostrar la notificación local normal
      _showLocalNotification(message);
    }
  }
}void _showNuevoViajeAlert(BuildContext context, String title, String body, int travelId) {
  QuickAlert.show(
    context: context,
    type: QuickAlertType.info,
    title: title,
    text: body,
    confirmBtnText: 'Ver detalles',
    cancelBtnText: 'Cerrar',
    showCancelBtn: true,
    onConfirmBtnTap: () {
      Get.back(); // Cerrar el alerta
      // Navegar a la página de aceptar viaje
      Get.offAll(() => AcceptTravelPage(idTravel: travelId));
    },
    onCancelBtnTap: () {
      Get.back(); // Solo cerrar el alerta
    },
    confirmBtnColor: Theme.of(context).colorScheme.secondary2,
  );
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
    travelByIdController
        .fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: travelId));
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
      context: Get.context!,
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
      CustomSnackBar.showError('', message);
      Navigator.of(context).pop();
      //navigateToHome();
    } else {
      _pendingErrorMessage = message;
      navigateToHome();
    }
  }

    Future<void> _handleTravelFetch(int? travelId, BuildContext? context) async {
      if (travelId == null) {
        CustomSnackBar.showError('', 'Viaje no encontrado');
        return;
      }

      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        barrierDismissible: false,
      );

      try {
        await travelByIdController
            .fetchCoDetails(TravelByIdEventDetailsEvent(idTravel: travelId));

        final state = travelByIdController.state.value;

        Get.back();

        if (state is TravelByIdAlertLoaded) {
          Get.off(() => AcceptTravelPage(idTravel: travelId));
        } else if (state is TravelByIdAlertFailure) {
          await Get.offAll(() => SplashScreen());
          CustomSnackBar.showError('', 'Viaje ya fue aceptado');
        }
      } catch (e) {
        Get.back(); // Cerrar dialogo en caso de error
        print('Error fetching travel details: $e');
        CustomSnackBar.showError('', 'Viaje ya fue aceptado');
      }
    }

void _handleNotificationClick(Map<String, dynamic> data, String? title) {
  final int? travelId = int.tryParse(data['travel'] ?? '');
  final context = navigatorKey.currentState?.overlay?.context;

  print('Handling notification click: Title=$title, TravelId=$travelId, Context=${context != null}');

  if (title == 'Nuevo viaje!!' && travelId != null) {
    // Añadir un log para depuración
    print('Processing new travel notification click - TravelId: $travelId');
    _handleTravelFetch(travelId, context);
  } else {
    print('Notification clicked but conditions not met: Title=$title, TravelId=$travelId');
  }
}

  void _showQuickAlert(BuildContext context, String title, String body) {
    final NotificationController notificationController =
        Get.find<NotificationController>();
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.info,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () async {
        if (title == 'Nuevo precio del viaje') {
          AuthService().clearCurrenttravel();
          await Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
        } else if (title == 'Propuesta de viaje rechazada') {
          await AuthService().clearCurrenttravel();
          await Get.find<NavigationService>().navigateToHome(selectedIndex: 1);
        } else {
          Navigator.of(Get.context!).pop();
        }
      },
    );
  }

  void _showNuevoviaje(BuildContext context, String title, String body) {
    final NotificationController notificationController =
        Get.find<NotificationController>();
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.info,
      title: title,
      text: body,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () async {
        if (title == 'Nuevo viaje!!') {
          final message = notificationController.lastNotification.value;
          if (message != null && message.notification?.title != null) {
final int? travelId = int.tryParse(message.data['travel'] ?? '');
   if (travelId != null) {
          Get.offAll(() => AcceptTravelPage(idTravel: travelId));
        } else {
          print('Error: travelId is null');
          // Puedes navegar a una página de error o manejarlo de otra forma
        }
          }
        }  else {
          Navigator.of(Get.context!).pop();
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

      showCustomAlert(
        context: Get.context!,
        type: CustomAlertType.warning,
        title: 'Nueva oferta',
        message: '',
        confirmText: '',
        cancelText: null,
        customWidget: Column(
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
            Obx(() {
              if (inputAmount.value.isNotEmpty) {
                String displayAmount = inputAmount.value.length > 6
                    ? '${inputAmount.value.substring(0, 6)}...'
                    : inputAmount.value;
                return Text(
                  'Monto ofertado: \$${displayAmount}',
                  style: TextStyle(fontSize: 16),
                );
              } else {
                return SizedBox();
              }
            }),
            SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                inputAmount.value = value;
                final truncatedValue =
                    value.length > 5 ? '${value.substring(0, 5)}...' : value;
                buttonText.value = value.isNotEmpty
                    ? "Ofertar \$${truncatedValue}"
                    : "Confirmar";
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
            // Usar Wrap para manejar automáticamente el desbordamiento
            Wrap(
              spacing: 10, // Espacio horizontal entre los botones
              runSpacing: 10, // Espacio vertical cuando los botones cambian de línea
              alignment: WrapAlignment.spaceBetween, // Distribuye los botones en el espacio disponible
              children: [
                _buildRejectButton(context, travelId, driverId, inputAmount),
                _buildConfirmButton(context, travel, travelId, driverId, inputAmount, buttonText),
              ],
            ),
          ],
        ),
      );
    });
  }

// Método para construir el botón de rechazo
Widget _buildRejectButton(BuildContext context, int travelId, int driverId, RxString inputAmount) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
    onPressed: () async {
      Get.back();

      final rejectController = Get.find<RejectTravelOfferGetx>();
      final travel = Travelwithtariff(
          travelId: travelId,
          tarifa: double.tryParse(inputAmount.value.replaceAll(',', '.')) ?? 0.0,

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
  );
}

// Método para construir el botón de confirmación
Widget _buildConfirmButton(BuildContext context, dynamic travel, int travelId, int driverId, RxString inputAmount, RxString buttonText) {
  return Obx(() => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary2,
    ),
    onPressed: () async {
      if (inputAmount.value.isNotEmpty) {
            final numericAmount = double.tryParse(inputAmount.value.replaceAll(',', '.')) ?? 0.0;
        final currentTarifa = travel.cost ?? 0;

        if (numericAmount < currentTarifa) {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.error,
            title: 'Importe inválido',
            text: 'El Importe debe ser mayor a \$${travel.cost} MXN',
            confirmBtnText: 'Entendido',
            confirmBtnColor: Theme.of(Get.context!).colorScheme.error,
            borderRadius: 8,
            titleColor: Theme.of(Get.context!).colorScheme.error,
          );
          return;
        }

        final offerController = Get.find<OfferNegotiationGetx>();
        final travelObj = Travelwithtariff(
            travelId: travelId,
            tarifa: numericAmount,
            driverId: driverId);
        final event = OffernegotiationEvent(travel: travelObj);

        await offerController.OfferNegotiationtravel(event);

        if (offerController.message.value.contains('correctamente')) {
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
        // Lógica existente para aceptar sin contraoferta
        final travel = Travelwithtariff(
            travelId: travelId,
           tarifa: double.tryParse(inputAmount.value.replaceAll(',', '.')) ?? 0.0,

            driverId: driverId);

        final acceptController = Get.find<AcceptWithCounteroffeGetx>();
        final event = AcceptwithcounteroffeEvent(travel: travel);

        await acceptController.acceptedtravel(event);

        if (acceptController.message.value.contains('correctamente')) {
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
  ));
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
    // Simplifica y clarifica el payload
    final Map<String, dynamic> payloadData = {
      'travel': message.data['travel'],
      'title': notification.title,
      'body': notification.body,
      'notification': {'title': notification.title, 'body': notification.body},
    };

    print('Sending local notification with payload: ${jsonEncode(payloadData)}');

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel!.name,
          channelDescription: channel!.description,
          icon: '@drawable/ic_launcher_background',
          color: Color(0xFFEFC300),
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          autoCancel: true,
          enableLights: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payloadData),
    );
  }
}
}
