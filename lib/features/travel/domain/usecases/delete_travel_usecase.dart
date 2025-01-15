import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class DeleteTravelUsecase{
  final MapaRepository mapaRepository;
  DeleteTravelUsecase({required this.mapaRepository});
  Future<void> execute(String id, bool connection) async {
    return await mapaRepository.deleteTravel(id,connection);
  }
}