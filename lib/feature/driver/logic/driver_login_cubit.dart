import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/driver_auth_service.dart';

part 'driver_login_state.dart';

class DriverLoginCubit extends Cubit<DriverLoginState> {
  final DriverAuthServices _authService; // تم تغيير التسمية لـ Services

  DriverLoginCubit(this._authService) : super(DriverLoginInitial());

  Future<void> login(String email, String password) async {
    emit(DriverLoginLoading());
    try {
      final response = await _authService.login(email, password);
      emit(DriverLoginSuccess(response));
    } catch (e) {
      emit(DriverLoginError(e.toString()));
    }
  }
}
