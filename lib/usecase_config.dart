import 'package:rayo_taxi/features/driver/data/datasources/driver_local_data_source.dart';
import 'package:rayo_taxi/features/driver/data/repositories/driver_repository_imp.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/change_availability_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/get_driver_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/login_driver_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/remove_data_account_usecase.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/renew_token_usecase.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/repositories/travel_repository_imp.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accept_with_counteroffe_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/accepted_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/cancel_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/confirm_travel_with_tariff_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/driver_arrival_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/end_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/get_device_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/id_device_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/offer_negotiation_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/reject_travel_offer_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/start_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/current_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/travel_by_id_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travelusecase/travels_alert_usecase.dart';

class UsecaseConfig {
  DriverLocalDataSourceImp? driverLocalDataSourceImp;
  DriverRepositoryImp? driverRepositoryImp;
  TravelLocalDataSourceImp? travelLocalDataSourceImp;
  TravelRepositoryImp? travelRepositoryImp;

  LoginDriverUsecase? loginDriverUsecase;
  GetDriverUsecase? getDriverUsecase;
  IdDeviceUsecase? idDeviceUsecase;
  GetDeviceUsecase? getDeviceUsecase;
  ChangeAvailabilityUsecase? changeAvailabilityUsecase;

  TravelsAlertUsecase? travelsAlertUsecase;
  CurrentTravelUsecase? currentTravelUsecase;
  TravelByIdUsecase? travelByIdUsecase;

  AcceptedTravelUsecase? acceptedTravelUsecase;
  EndTravelUsecase? endTravelUsecase;
  StartTravelUsecase? startTravelUsecase;
  DriverArrivalUsecase? driverArrivalUsecase;
  ConfirmTravelWithTariffUsecase? confirmTravelWithTariffUsecase;
  CancelTravelUsecase? cancelTravelUsecase;
  AcceptWithCounteroffeUsecase? acceptWithCounteroffeUsecase;
  RemoveDataAccountUsecase? removeDataAccountUsecase;
  OfferNegotiationUsecase? offerNegotiationUsecase;
  RejectTravelOfferUsecase? rejectTravelOfferUsecase;
  RenewTokenUsecase?renewTokenUsecase;
  UsecaseConfig() {
    driverLocalDataSourceImp = DriverLocalDataSourceImp();
    travelLocalDataSourceImp = TravelLocalDataSourceImp();
    driverRepositoryImp =
        DriverRepositoryImp(driverLocalDataSource: driverLocalDataSourceImp!);
    travelRepositoryImp =
        TravelRepositoryImp(travelLocalDataSource: travelLocalDataSourceImp!);
    loginDriverUsecase =
        LoginDriverUsecase(driverRepository: driverRepositoryImp!);
    getDriverUsecase = GetDriverUsecase(driverRepository: driverRepositoryImp!);
    idDeviceUsecase =
        IdDeviceUsecase(notificationRepository: travelRepositoryImp!);
    changeAvailabilityUsecase =
        ChangeAvailabilityUsecase(driverRepository: driverRepositoryImp!);
  renewTokenUsecase = RenewTokenUsecase(driverRepository: driverRepositoryImp!);

    getDeviceUsecase =
        GetDeviceUsecase(notificationRepository: travelRepositoryImp!);
    currentTravelUsecase =
        CurrentTravelUsecase(travelRepository: travelRepositoryImp!);
    travelsAlertUsecase =
        TravelsAlertUsecase(travelRepository: travelRepositoryImp!);
    travelByIdUsecase =
        TravelByIdUsecase(travelRepository: travelRepositoryImp!);
    acceptedTravelUsecase =
        AcceptedTravelUsecase(travelRepository: travelRepositoryImp!);
    endTravelUsecase = EndTravelUsecase(travelRepository: travelRepositoryImp!);
    startTravelUsecase =
        StartTravelUsecase(travelRepository: travelRepositoryImp!);
    driverArrivalUsecase =
        DriverArrivalUsecase(travelRepository: travelRepositoryImp!);
    confirmTravelWithTariffUsecase =
        ConfirmTravelWithTariffUsecase(travelRepository: travelRepositoryImp!);
    cancelTravelUsecase =
        CancelTravelUsecase(travelRepository: travelRepositoryImp!);
    acceptWithCounteroffeUsecase =
        AcceptWithCounteroffeUsecase(travelRepository: travelRepositoryImp!);
    removeDataAccountUsecase =
        RemoveDataAccountUsecase(driverRepository: driverRepositoryImp!);
    offerNegotiationUsecase =
        OfferNegotiationUsecase(travelRepository: travelRepositoryImp!);
    rejectTravelOfferUsecase =
        RejectTravelOfferUsecase(travelRepository: travelRepositoryImp!);
  }
}
