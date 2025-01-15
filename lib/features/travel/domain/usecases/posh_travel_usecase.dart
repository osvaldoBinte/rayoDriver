import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/domain/repository/mapa_repository.dart';

class PoshTravelUsecase{
  final MapaRepository mapaRepository;
  PoshTravelUsecase({required this.mapaRepository});
  Future<void> execute(Travel travel) async {
    return await mapaRepository.poshTravel(travel);
  }
}