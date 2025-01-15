import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/midireccion/midireccion_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/select_map/select_map.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../travel/presentation/page/travel/travel_page.dart';
import '../get_driver_page.dart';
import '../login_driver_page.dart';
class HomePage extends StatefulWidget {
  final int selectedIndex;
  HomePage({required this.selectedIndex});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final HomeController controller = Get.put(HomeController());
  final List<Widget> _pages = [
    TravelPage(),
    SelectMap(),
    GetDriverPage(),
  ];

  @override
  void initState() {
    super.initState();
    controller.setIndex(widget.selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
     return WillPopScope(
      onWillPop: () => controller.handleBackButton(widget.selectedIndex),
      child: Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => IndexedStack(
              index: controller.selectedIndex.value,
              children: _pages,
            )),
            Align(
              alignment: Alignment.bottomCenter,
              child: Obx(() => Offstage(
                offstage: MediaQuery.of(context).viewInsets.bottom != 0,
                child: CurvedNavigationBar(
                  index: controller.selectedIndex.value,
                  backgroundColor: Colors.transparent,
                  color: Theme.of(context).primaryColor,
                  buttonBackgroundColor: Theme.of(context).colorScheme.CurvedIconback,
                  height: 75,
                  items: <Widget>[
                    _buildIcon(Icons.receipt, 0),
                    _buildIcon(Icons.car_rental, 1),
                    _buildIcon(Icons.person, 2),
                  ],
                  animationDuration: const Duration(milliseconds: 700),
                  animationCurve: Curves.easeInOut,
                  onTap: controller.setIndex,
                ),
              )),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildIcon(IconData icon, int index) {
    return Obx(() {
      bool isSelected = controller.selectedIndex.value == index;
      return Container(
        margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
        height: isSelected ? 40 : 60,
        child: Icon(
          icon,
          size: isSelected ? 30 : 40,
          color: isSelected
              ? Theme.of(context).colorScheme.CurvedNavigationIcono
              : Theme.of(context).colorScheme.CurvedNavigationIcono2,
        ),
      );
    });
  }
}