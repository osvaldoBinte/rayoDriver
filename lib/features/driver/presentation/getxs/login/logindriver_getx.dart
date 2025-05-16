import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/login_driver_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_page.dart';

part 'logindriver_event.dart';
part 'logindriver_state.dart';

class LogindriverGetx extends GetxController {
  final LoginDriverUsecase loginDriverUsecase;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var state = Rx<LogindriverState>(LogindriverInitial());
  var isLoading = false.obs;

  LogindriverGetx({required this.loginDriverUsecase});
  var obscureText = true.obs;

  // Método para alternar la visibilidad de la contraseña
  void togglePasswordVisibility() {
    obscureText.value = !obscureText.value;
  }
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Campos Vacíos',
        text: 'Por favor, completa todos los campos.',
        confirmBtnText: 'OK',
      );
      return;
    }

    isLoading.value = true;
    state.value = LogindriverLoading();
    try {
      final driver = Driver(email: email, password: password);
      await loginDriverUsecase.execute(driver);
      state.value = LogindriverSuccessfully();
 Get.offAll(()=> HomePage(selectedIndex:1));
      
    } catch (e) {
      state.value = LogindriverFailure(e.toString());

      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'ACCESO INCORRECTO',
        text: 'No se pudo iniciar sesión. Inténtalo de nuevo.',
        confirmBtnText: 'OK',
      );
    } finally {
      isLoading.value = false;
    }
  }

 void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    state.value = LogindriverInitial();
    
    // Eliminar el driver
    await prefs.remove('drives');
    
    // Eliminar el token
    await prefs.remove('auth_token');
    
    await Get.offAll(() => LoginDriverPage());
}

  Future<void> logoutAlert() async {
    showCustomAlert(
      context: Get.context!,
      type: CustomAlertType.confirm,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de cerrar tu sesión?',
      confirmText: 'Sí',
      cancelText: 'No',
      onConfirm: () async {
        logout();
      },
      onCancel: () {
        Navigator.of(Get.context!).pop();
      },
    );
  }
  @override
  void onClose() {
    // Liberar recursos
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
