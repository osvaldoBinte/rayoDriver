import '../../../data/models/travel_alert/travel_alert_model.dart';
import '../../repository/travel_repository.dart';

class TravelsAlertUsecase {
  final TravelRepository travelRepository;
  TravelsAlertUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await travelRepository.getalltravel(connection);
  }
}
