import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getxtravel/currentTravel/current_travel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travel_id/travel_id_page.dart';
import '../../getxtravel/TravelsAlert/travels_alert_getx.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:quickalert/quickalert.dart';
import 'package:geocoding/geocoding.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelsPagePage();
}

class _TravelsPagePage extends State<TravelPage> {
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;
  final CurrentTravelGetx _travelAlertGetx = Get.find<CurrentTravelGetx>();

  Future<void> _refreshTravels() async {
    await Future.wait([
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent()),
      _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent()),
    ] as Iterable<Future>);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
      _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
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
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
        _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 4:
        return Theme.of(context).colorScheme.StatusCompletado.withOpacity(0.2);
      case 1:
        return Theme.of(context).colorScheme.StatusLookingfor.withOpacity(0.2);
      case 2:
        return Theme.of(context).colorScheme.Statuscancelled.withOpacity(0.2);
      case 3:
        return Theme.of(context).colorScheme.Statusaccepted.withOpacity(0.2);
      case 5:
        return Theme.of(context).colorScheme.StatusCompletado.withOpacity(0.2);
      default:
        return Theme.of(context).colorScheme.Statusrecognized.withOpacity(0.2);
    }
  }

  Color getStatusTextColor(int status) {
    switch (status) {
      case 4:
        return Theme.of(context).colorScheme.StatusCompletado;
      case 1:
        return Theme.of(context).colorScheme.StatusLookingfor;
      case 2:
        return Theme.of(context).colorScheme.Statuscancelled;
      case 3:
        return Theme.of(context).colorScheme.Statusaccepted;
      case 5:
        return Theme.of(context).colorScheme.StatusCompletado;
      default:
        return Theme.of(context).colorScheme.Statusrecognized;
    }
  }

  Widget _buildRegularTravelCard(TravelAlertModel travel) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: _buildTravelInfo(travel),
    );
  }

  Widget _buildTravelInfo(TravelAlertModel travel) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      title:Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible( 
      child: Text(
        travel.client == "N/A" ? 'Sin cliente' : travel.client.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF333333),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
    ),
    Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(travel.id_status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        travel.status,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: getStatusTextColor(travel.id_status),
        ),
        overflow: TextOverflow.ellipsis, // Opcional si es un texto corto
      ),
    ),
  ],
)
,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5),
          if (travel.id_status != 2)
            Text(
              'Placas: ${travel.plates}',
              style: TextStyle(color: Colors.black87),
            ),
          SizedBox(height: 8),
          if (travel.id_status != 2)
            Text(
              'Kilómetros: ${travel.kilometers}',
              style: TextStyle(color: Colors.black87),
            ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               if (travel.id_status != 2) ...[
                    Text(
                      'Importe: ${travel.id_status == 1 ? travel.cost : travel.tarifa}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
              Text(
                ' ${travel.date.split(',')[0]}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: _buildTrailingIcon(travel),
      onTap: () => _showTravelDetails(travel),
    );
  }

  Widget _buildFirstTravelCard(TravelAlertModel travel) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: TravelIdPage(
                travel: travel,
                showInfoButton: false,
                isPreview: true,
              ),
            ),
          ),
          _buildTravelInfoWithAddress(travel, context),
        ],
      ),
    );
  }

  Widget _buildTravelInfoWithAddress(
    TravelAlertModel travel,
    BuildContext context,
  ) {
    return FutureBuilder<Map<String, String>>(
      future: _getAddresses(travel),
      builder: (context, snapshot) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  travel.client == "N/A"
                      ? 'Sin chofer'
                      : travel.client.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(travel.id_status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  travel.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: getStatusTextColor(travel.id_status),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              if (snapshot.hasData) ...[
                Row(
                  children: [
                    Image.asset(
                      'assets/images/mapa/origen.png',
                      width: 18,
                      height: 18,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Origen: ${snapshot.data!['start'] ?? 'Cargando...'}',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/mapa/destino.png',
                      width: 18,
                      height: 18,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Destino: ${snapshot.data!['end'] ?? 'Cargando...'}',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else if (snapshot.hasError) ...[
                Text(
                  'Error al cargar direcciones',
                  style: TextStyle(color: Colors.red),
                ),
              ] else ...[
                Text('Cargando direcciones...'),
              ],
              SizedBox(height: 8),
              if (travel.id_status != 2 && travel.plates.isNotEmpty)
                Text(
                  'Placas: ${travel.plates}',
                  style: TextStyle(color: Colors.black87),
                ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (travel.id_status != 2) ...[
                    Text(
                      'Importe: ${travel.id_status == 1 ? travel.cost : travel.tarifa}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  Text(
                    ' ${travel.date.split(',')[0]}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: _buildTrailingIcon(travel),
          onTap: () => _showTravelDetails(travel),
        );
      },
    );
  }

  Widget _buildTrailingIcon(TravelAlertModel travel) {
    if (travel.status == 'Buscando Taxi') {
      return IconButton(
        icon: Icon(
          Icons.cancel,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => _showCancelConfirmation(travel),
      );
    }
    return Icon(
      Icons.arrow_forward_ios,
      color: Colors.grey,
      size: 18,
    );
  }

  void _showCancelConfirmation(TravelAlertModel travel) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Cancelar viaje',
      text: '¿Estás seguro de que deseas cancelar este viaje?',
      confirmBtnText: 'Sí',
      cancelBtnText: 'No',
      showCancelBtn: true,
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viaje cancelado')),
        );
        await _refreshTravels();
      },
    );
  }

  void _showTravelDetails(TravelAlertModel travel) {
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
                  ),
                ),
              ),
              Expanded(
                child: TravelIdPage(
                  travel: travel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Actividad',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.buttonColormap,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (travelAlertGetx.state.value is TravelsAlertLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertFailure) {
                    return _buildListOption(
                      icon: Icons.error,
                      title: 'no hay viajes aun',
                      subtitle: '',
                    );
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertLoaded) {
                    var travels =
                        (travelAlertGetx.state.value as TravelsAlertLoaded)
                            .travels;

                    return RefreshIndicator(
                      onRefresh: _refreshTravels,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom +
                              75.0 +
                              16.0,
                        ),
                        itemCount: travels.length,
                        itemBuilder: (context, index) {
                          return index == 0
                              ? _buildFirstTravelCard(travels[index])
                              : _buildRegularTravelCard(travels[index]);
                        },
                      ),
                    );
                  } else {
                    return _buildListOption(
                      icon: Icons.error,
                      title: 'no hay viajes aun',
                      subtitle: '',
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String> getAddressFromCoordinates(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String address = '';
      if (place.street?.isNotEmpty ?? false) {
        address += place.street!;
      }
      if (place.subLocality?.isNotEmpty ?? false) {
        address +=
            address.isNotEmpty ? ', ${place.subLocality}' : place.subLocality!;
      }
      if (place.locality?.isNotEmpty ?? false) {
        address += address.isNotEmpty ? ', ${place.locality}' : place.locality!;
      }
      return address.isNotEmpty ? address : 'Dirección no disponible';
    }
    return 'Dirección no disponible';
  } catch (e) {
    print('Error getting address: $e');
    return 'Dirección no disponible';
  }
}

Future<Map<String, String>> _getAddresses(TravelAlertModel travel) async {
  try {
    double startLat = double.parse(travel.start_latitude);
    double startLng = double.parse(travel.start_longitude);
    double endLat = double.parse(travel.end_latitude);
    double endLng = double.parse(travel.end_longitude);

    final startAddress = await getAddressFromCoordinates(startLat, startLng);
    final endAddress = await getAddressFromCoordinates(endLat, endLng);

    return {
      'start': startAddress,
      'end': endAddress,
    };
  } catch (e) {
    print('Error parsing coordinates: $e');
    return {
      'start': 'Error al cargar dirección',
      'end': 'Error al cargar dirección',
    };
  }
}

Widget _buildListOption(
    {required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
      leading: Icon(icon, color: Colors.black, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailing,
    ),
  );
}
