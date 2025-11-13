import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Model/loginModel.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:bloc/bloc.dart';

final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repository repo;
  LoginModel loginModel = LoginModel();
  AuthBloc(this.repo) : super(const AuthState()) {
    on<GetLeavesTypeEvent>(_getLeavesTypes);
    on<LoginEvent>(_login);
  }

  



  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {

    emit(state.copyWith(loginStatus: LoginStatus.loading));
    try {
      final response = await repo.login(email: event.email, pass: event.password, latitude: '0', longitude: '0', actType: 'LOGIN', action: 'IN', attTime: currentDate, attDate: currentTime, appVersion: '2.0.2', add: '', deviceId: '0d6bb3238ca24544');
      if (response.statusCode == 200) {
        final loginModel = loginModelFromJson(response.body);
        if (loginModel.status == "1") {
          emit(state.copyWith(loginStatus: LoginStatus.success, loginModel: loginModel));
        } else {
          emit(state.copyWith(loginStatus: LoginStatus.failure, loginModel: loginModel));
        }
      } else {
        emit(state.copyWith(loginStatus: LoginStatus.failure));
      }
    } catch (e, st) {
      debugPrint("login error: $e\n$st");
      emit(state.copyWith(loginStatus: LoginStatus.failure));
    }
  }










  Future<void> _getLeavesTypes(
    GetLeavesTypeEvent event,
    Emitter<AuthState> emit,
  ) async {

    emit(state.copyWith(getLeavesTypeStatus: GetLeavesTypeStatus.loading));

    try {
      final model = await repo.getLeaveTypes(userId: event.userId);
      final ok = (model.status ?? '') == '1';
  
      emit(state.copyWith(
        getLeavesTypeStatus:
            ok ? GetLeavesTypeStatus.success : GetLeavesTypeStatus.failure,
        getLeaveTypeModel: ok ? model : null,
        error: ok ? null : (model.message ?? 'failed'),
      ));
    } catch (err) {
      emit(state.copyWith(
        getLeavesTypeStatus: GetLeavesTypeStatus.failure,
        error: '$err',
      ));
    }
  }

  @override
  void onEvent(AuthEvent event) {
    // ignore: avoid_print
    print('[AuthBloc] onEvent: ${event.runtimeType}');
    super.onEvent(event);
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> t) {
    // ignore: avoid_print
    print('[AuthBloc] transition: ${t.event.runtimeType} '
        '${t.currentState.getLeavesTypeStatus} -> '
        '${t.nextState.getLeavesTypeStatus}');
    super.onTransition(t);
  }
}
