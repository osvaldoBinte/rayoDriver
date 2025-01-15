part of 'accept_with_counteroffe_getx.dart';

@immutable
abstract class AcceptWithCounteroffeState {}

class AcceptWithCounteroffeInitial extends AcceptWithCounteroffeState {}

class AcceptWithCounteroffeLoading extends AcceptWithCounteroffeState {}

class AcceptWithCounteroffeLoaded extends AcceptWithCounteroffeState {
  final int id_travel;
  AcceptWithCounteroffeLoaded(this.id_travel);
}

class AcceptWithCounteroffeError extends AcceptWithCounteroffeState {
  final String message;
  AcceptWithCounteroffeError(this.message);
}
class AcceptWithCounteroffeSuccessfully extends AcceptWithCounteroffeState {}
