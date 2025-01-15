import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';
import 'package:speech_bubble/speech_bubble.dart';

class InfoButtonWidget extends StatelessWidget {
  final TravelByIdAlertGetx? travelByIdController;
  final List<TravelAlertModel>? travelList;
  final TravelAlertModel? travel;
  final String defaultImagePath;

  const InfoButtonWidget({
    Key? key,
    this.travelByIdController,
    this.travelList,
    this.travel,
    this.defaultImagePath = 'assets/images/taxi.png',
  }) : super(key: key);

  Widget _buildProfileImage(String? pathPhoto, String clientName) {
    if (pathPhoto != null && pathPhoto.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          pathPhoto,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar(clientName);
          },
        ),
      );
    } else {
      return _buildFallbackAvatar(clientName);
    }
  }

  Widget _buildFallbackAvatar(String clientName) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue,
      child: Text(
        clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    String clientName = '';
    String date = '';
    String tarifa = '';
    String plates = '';
    String? pathPhoto;

    if (travel != null) {
      clientName = travel!.client.toString();
      date = travel!.date;
      tarifa = travel!.tarifa.toString();
      plates = travel!.plates ?? '';
      pathPhoto = travel!.path_photo;
    } else if (travelByIdController != null && 
        travelByIdController!.state.value is TravelByIdAlertLoaded) {
      var travelData = (travelByIdController!.state.value as TravelByIdAlertLoaded).travels[0];
      clientName = travelData.client.toString();
      date = travelData.date;
      tarifa = (travelData.id_status == 1 || travelData.id_status == 2) 
          ? travelData.cost.toString() 
          : travelData.tarifa.toString();
      plates = travelData.plates ?? '';
      pathPhoto = travelData.path_photo;
    } else if (travelList != null && travelList!.isNotEmpty) {
      clientName = travelList![0].client.toString();
      date = travelList![0].date;
      tarifa = travelList![0].tarifa.toString();
      plates = travelList![0].plates ?? '';
      pathPhoto = travelList![0].path_photo;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: 'Información del Viaje',
      confirmBtnText: 'Cerrar',
      widget: Column(
        children: [
          _buildProfileImage(pathPhoto, clientName),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(text: 'Cliente: $clientName\n'),
                TextSpan(
                  text: 'Fecha: $date\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'Importe: \$ $tarifa MXN\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: 'Placas: ${plates.isNotEmpty ? plates : "N/A"}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeechBubble(
            nipLocation: NipLocation.BOTTOM,
            color: Theme.of(context).colorScheme.buttonColormap,
            borderRadius: 20,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Información',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          IconButton(
            icon: Image.asset(
              defaultImagePath,
              width: 40,
              height: 40,
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }
}