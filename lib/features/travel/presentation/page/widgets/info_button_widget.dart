import 'package:flutter/material.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/TravelById/travel_by_id_alert_getx.dart';import 'package:speech_bubble/speech_bubble.dart';

import 'package:flutter/material.dart';
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
    this.defaultImagePath = 'assets/images/viajes/taxi.png',
  }) : super(key: key);

  void _showInfoDialog(BuildContext context) {
    String clientName = '';
    String date = '';
    String tarifa = '';
    String plates = '';
    String? pathPhoto;
    int idStatus = 0;
    String rating = '0.0';
    String carModel = '';

    if (travel != null) {
      clientName = (travel!.client == 'N/A' ? 'Sin chofer' : travel!.client)!;
      date = travel!.date;
      tarifa = _getImporte(travel!);
      plates = travel!.plates ?? '';
      pathPhoto = travel!.path_photo;
      idStatus = travel!.id_status;
      rating = travel!.qualification?.toString() ?? '0.0';
      //carModel = travel!.model ?? 'Taxi';
    } else if (travelByIdController?.state.value is TravelByIdAlertLoaded) {
      var travelData =
          (travelByIdController!.state.value as TravelByIdAlertLoaded)
              .travels[0];
      clientName =
          (travelData.client == 'N/A' ? 'Sin chofer' : travelData.client)!;
      date = travelData.date;
      tarifa = _getImporte(travelData);
      plates = travelData.plates ?? '';
      pathPhoto = travelData.path_photo;
      idStatus = travelData.id_status;
      rating = travelData.qualification?.toString() ?? '0.0';
     // carModel = travelData.model ?? 'Taxi';
    } else if (travelList?.isNotEmpty ?? false) {
      clientName =
          (travelList![0].client == 'N/A' ? 'Sin chofer' : travelList![0].client)!;
      date = travelList![0].date;
      tarifa = _getImporte(travelList![0]);
      plates = travelList![0].plates ?? '';
      pathPhoto = travelList![0].path_photo;
      idStatus = travelList![0].id_status;
      rating = travelList![0].qualification?.toString() ?? '0.0';
     // carModel = travelList![0].model ?? 'Taxi';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            contentPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[900]!, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: pathPhoto != null && pathPhoto.isNotEmpty
                                ? Image.network(
                                    pathPhoto,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          clientName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      clientName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          'Fecha',
                          date,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/viajes/taxi2.png',
                                width: 80,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (carModel.isNotEmpty) ...[
                                      Text(
                                        'Modelo: $carModel',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (plates.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Placas: $plates',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.attach_money_rounded,
                          'Importe',
                          '\$$tarifa MXN',
                          highlight: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.button,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlight ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: highlight ? Colors.grey[900]! : Colors.grey[600],
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.grey[700] : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  String _getImporte(dynamic travelData) {
    if (travelData.id_status == 1 || travelData.id_status == 2) {
      return travelData.cost.toString();
    }
    return travelData.tarifa.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showInfoDialog(context),
            child: Image.asset(
              defaultImagePath,
              width: 48,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }
}