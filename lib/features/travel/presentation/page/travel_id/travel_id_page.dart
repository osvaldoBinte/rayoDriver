import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel_id/travel_id_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:speech_bubble/speech_bubble.dart';

class TravelIdPage extends StatelessWidget {
  final TravelAlertModel travel;
  final String tag;

  TravelIdPage({
    required this.travel,
    String? tag,
  }) : this.tag = tag ?? travel.hashCode.toString();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TravelController(travel: travel),
      tag: tag,
      permanent: false,
    );

    return Scaffold(
     
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: controller.onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: controller.startLocation.value ?? controller.center,
                      zoom: 12.0,
                    ),
                    markers: controller.markers.value,
                    polylines: controller.polylines.value,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                  )),
                  InfoButtonWidget(
              travel: travel,
            ),
          ],
        ),
      ),
    );
  }
}