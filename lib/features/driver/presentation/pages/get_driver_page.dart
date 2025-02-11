import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/driver/domain/entities/change_availability_entitie.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/changeAvailability/changeAvailability_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/removeDataAccount/removeDataAccount_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/CarInfoDisplay/car_info_display.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/Widget/card_button.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/Widget/list_option.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/ayudaPage/ayuda_page.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/login_driver_page.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/privacy_notices/privacy_notices.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel.dart/travel_route_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickalert/quickalert.dart';

import 'dart:async';

import '../getxs/get/get_driver_getx.dart';
import 'loaderScreen /custom_loading_screen.dart';

class GetDriverPage extends StatefulWidget {
  const GetDriverPage({super.key});

  @override
  State<GetDriverPage> createState() => _GetDriverPage();
}

class _GetDriverPage extends State<GetDriverPage> {
  late StreamSubscription<ConnectivityResult> subscription;
  final GetDriverGetx getDriveGetx = Get.find<GetDriverGetx>();
  final LogindriverGetx _driverGetx = Get.find<LogindriverGetx>();

  final RemovedataaccountGetx _removedataaccountGetx =
      Get.find<RemovedataaccountGetx>();
  final RxBool useMapbox = true.obs;

  
 Future<void> _logout() async {
   _driverGetx.logoutAlert();
  }
  @override
  void initState() {
    super.initState();
    _loadNavigationPreference();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getDriveGetx.fetchCoDetails(FetchgetDetailsEvent());
    });

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se perdió la conectividad Wi-Fi'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        getDriveGetx.fetchCoDetails(FetchgetDetailsEvent());
      }
    });
  }
Future<void> _loadNavigationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    useMapbox.value = prefs.getBool('use_mapbox') ?? true;
  }
bool getNavigationPreference() {
  return useMapbox.value;
}
 void _toggleNavigation() {
  showCustomAlert(
    context: Get.context!,
    type: CustomAlertType.confirm,
    title: 'Cambiar Navegación',
    message: useMapbox.value 
        ? '¿Deseas cambiar a Google Maps?' 
        : '¿Deseas quedarte con Rayo Taxi?',
    confirmText: 'Sí',
    cancelText: 'No',
    onConfirm: () async {
      useMapbox.value = !useMapbox.value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_mapbox', useMapbox.value);
      
      if (Get.isRegistered<TravelRouteController>()) {
        Get.find<TravelRouteController>().updateNavigationPreference(useMapbox.value);
      }
      Navigator.of(Get.context!).pop();
    },
    onCancel: () {
      Navigator.of(Get.context!).pop();
    },
  );
}

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final state = getDriveGetx.state.value;
 if (state is GetDriverFailure) {
            return Center(
              child: Text(
                state.error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 18),
              ),
            );
          }
          if (state is GetDriverLoading) {
            return const CustomLoadingScreen();
          } 
            if (state is GetDriverLoaded) {
            final drive = state.drive.isNotEmpty ? state.drive[0] : null;

            if (drive == null) {
              return const Center(
                child: Text(
                  'Conductor no encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          child: ClipOval(
                            child: Image.network(
                              drive.path_photo ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return Text(
                                        (drive.name ?? '?')[0].toUpperCase(),
                                        style:  TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.avatar,
                                        ),
                                      );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drive.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                         
                          Text(drive.email ?? 'Sin email',
                              style: Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${drive.score?.toStringAsFixed(1) ?? 'N/A'}',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            drive.availability == 1
                                ? Icons.notifications
                                : Icons.notifications_off,
                          ),
                          color: Colors.grey.shade700,
                          iconSize: 30,
                          onPressed: () {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.confirm,
                              title: 'Confirmar Acción',
                              text: drive.availability == 1
                                  ? '¿Deseas desactivar las notificaciones?'
                                  : '¿Deseas activar las notificaciones?',
                              confirmBtnText: 'Sí',
                              cancelBtnText: 'No',
                              onConfirmBtnTap: () async {
                                final ChangeavailabilityGetx _driverGetx =
                                    Get.find<ChangeavailabilityGetx>();
                                final availability = ChangeAvailabilityEntitie(
                                  status:
                                      drive.availability == 1 ? false : true,
                                );
                                await _driverGetx.execute(
                                  ChangeaVailabilityEvent(
                                      changeAvailabilityEntitie: availability),
                                );

                                print(
                                    "Estado cambiado a: ${availability.status}");
                                 getDriveGetx
                                    .fetchCoDetails(FetchgetDetailsEvent());

                                Navigator.of(context).pop();
                              },
                              onCancelBtnTap: () {
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Notificaciones',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CardButton(
                      icon: Icons.logout,
                      label: 'Cerrar Sesión',
                      onPressed: _logout,
                    ),
                     Obx(() => CardButton(
                    icon: useMapbox.value ? Icons.map : Icons.navigation,
                    label: useMapbox.value ? 'Usar Rayo' : 'Usar Google Maps',
                    onPressed: _toggleNavigation,
                  )),
                  ],
                ),
                const SizedBox(height: 30),
                ListOption(
                  icon: Icons.directions_car,
                  title: 'Vehículo',
                  subtitle: 'Información adicional',
                                    onPressed: (){
                                       showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return FractionallySizedBox(
                              heightFactor: 0.8,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 10,
                                    width: 70,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    )),
                                  ),
                                  Expanded(
                                    child: CarInfoDisplay(driver: drive),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                                    }

                ),
                ListOption(
                  icon: Icons.help_outline,
                  title: 'Ayuda',
                  subtitle:
                      '¿Te gustaría que te ayude con algo más relacionado con tu aplicación?',
                 onPressed: (){
                                       showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return FractionallySizedBox(
                              heightFactor: 0.8,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 10,
                                    width: 70,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    )),
                                  ),
                                  Expanded(
                                    child: AyudaPage(driver: drive),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                                    }
                ),
                ListOption(
                  icon: Icons.privacy_tip,
                  title: 'Avisos de Privacidad',
                  subtitle: 'Detalles de nuestras políticas y condiciones',
                  onPressed: () => _showPdfModal(Get.context!),
                ),
                ListOption(
                  icon: Icons.delete_forever,
                  title: 'Eliminar cuenta',
                  subtitle: 'Elimina tu cuenta de forma permanente',
                  cardColor: Colors.red.shade100,
                  onPressed: () {
                    _removedataaccountGetx.confirmDeleteAccount();
                  },
                ),
                const SizedBox(height: 80),
              ],
            );
          }
          return Container();
        }),
      ),
    );
  }


  void _showPdfModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 10,
                width: 70,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                )),
              ),
              Expanded(
                child: PrivacyPolicyView(),
              ),
            ],
          ),
        );
      },
    );
  }

}
