import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/presentation/page/midireccion/mi_direccion.dart';


class MidireccionPage extends StatelessWidget {
  final MidireccionController controller = Get.put(MidireccionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(
              () => GoogleMap(
                onMapCreated: controller.onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: controller.driverLocation.value ?? controller.center,
                  zoom: 16.0,
                ),
                markers: controller.markers.value,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                liteModeEnabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
