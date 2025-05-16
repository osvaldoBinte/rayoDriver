import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/home/home_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/select_map/select_map.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import '../../../../travel/presentation/page/travel/travel_page.dart';
import '../get_driver_page.dart';

class HomePage extends StatefulWidget {
  final int selectedIndex;
  HomePage({required this.selectedIndex});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final HomeController controller = Get.put(HomeController());
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    _pages = [
      TravelPage(),
      SelectMap(),
      GetDriverPage(),
    ];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Configurando índice inicial a: ${widget.selectedIndex}');
      controller.selectedIndex.value = widget.selectedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => controller.handleBackButton(widget.selectedIndex),
      child: Scaffold(
         backgroundColor:Theme.of(context).primaryColor,
       appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
        extendBody: true,
        body: SafeArea(
          child: Stack(
            children: [
              GetX<HomeController>(
                builder: (controller) {
                  print('Reconstruyendo IndexedStack con índice: ${controller.selectedIndex.value}');
                  return IndexedStack(
                    index: controller.selectedIndex.value,
                    children: _pages,
                  );
                }
              ),
              
              Align(
                alignment: Alignment.bottomCenter,
                child: Builder(
                  builder: (context) {
                    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
                    
                    if (isKeyboardVisible) {
                      return SizedBox.shrink();
                    }
                    
                    return GetX<HomeController>(
                      builder: (controller) {
                        return CurvedNavigationBar(
                          index: controller.selectedIndex.value,
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).primaryColor,
                          buttonBackgroundColor:
                              Theme.of(context).colorScheme.CurvedIconback,
                          height: 75,
                          items: <Widget>[
                            _buildIcon('assets/images/taxi/icons-viaje.png', 0, controller.selectedIndex.value),
                            _buildIcon("assets/images/taxi/icon-taxi.png", 1, controller.selectedIndex.value),
                            _buildIcon(Icons.person, 2, controller.selectedIndex.value),
                          ],
                          animationDuration: const Duration(milliseconds: 700),
                          animationCurve: Curves.easeInOut,
                          onTap: (index) {
                            print('Navegando a índice: $index');
                            controller.setIndex(index);
                          },
                        );
                      }
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(dynamic icon, int index, int currentIndex) {
    bool isSelected = currentIndex == index;
    return Container(
      margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
      height: isSelected ? 40 : 60,
      child: icon is IconData
          ? Icon(
              icon,
              size: isSelected ? 30 : 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.CurvedNavigationIcono
                  : Theme.of(context).colorScheme.CurvedNavigationIcono2,
            )
          : Image.asset(
              icon,
              width: isSelected ? 30 : 40,
              height: isSelected ? 30 : 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.CurvedNavigationIcono
                  : Theme.of(context).colorScheme.CurvedNavigationIcono2,
            ),
    );
  }
}