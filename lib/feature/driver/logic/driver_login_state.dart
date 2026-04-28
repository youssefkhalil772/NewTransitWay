part of 'driver_login_cubit.dart';

abstract class DriverLoginState {}

class DriverLoginInitial extends DriverLoginState {}

class DriverLoginLoading extends DriverLoginState {}

class DriverLoginSuccess extends DriverLoginState {
  final Map<String, dynamic> driverData;
  DriverLoginSuccess(this.driverData);
}

class DriverLoginError extends DriverLoginState {
  final String message;
  DriverLoginError(this.message);
}
