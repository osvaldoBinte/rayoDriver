part of 'travelWithTariff_getx.dart';

@immutable
abstract class TravelwithtariffState {}

class TravelwithtariffInitial extends TravelwithtariffState {}

class TravelwithtariffLoading extends TravelwithtariffState {}

class TravelwithtariffSuccessfully extends TravelwithtariffState {}

class TravelwithtariffFailure extends TravelwithtariffState {
  final String error;
  TravelwithtariffFailure(this.error);
}
