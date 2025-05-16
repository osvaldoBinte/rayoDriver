// navigation_service.dart
import 'package:get/get.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';

class NavigationService extends GetxService {
  static NavigationService get to => Get.find();
  
  Future<void> navigateToHome({int selectedIndex = 1}) async {
    // Asegurarse de que la navegación se realice en el siguiente frame
    await Get.offAllNamed(
      RoutesNames.homePage, 
      arguments: {'selectedIndex': selectedIndex}
    );
  }
}