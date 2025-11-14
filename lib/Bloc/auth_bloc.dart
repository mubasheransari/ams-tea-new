import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Data/local_sessions.dart';
import 'package:new_amst_flutter/Model/loginModel.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:bloc/bloc.dart';

final now = DateTime.now();
    final currentDate = DateFormat("dd-MMM-yyyy").format(now);
    final currentTime = DateFormat("HH:mm:ss").format(now);
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repository repo;
  AuthBloc(this.repo) : super(const AuthState()) {
    on<GetLeavesTypeEvent>(_getLeavesTypes);
    on<LoginEvent>(_onLogin);

    // Load cached session (if any) so Home can read name without crashing.
    final cached = LocalSession.readLogin();
    if (cached != null) {
      // don't set LoginStatus.success here; just hydrate the model
      emit(state.copyWith(loginModel: cached));
    }
  }

  Future<void> _onLogin(LoginEvent e, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: LoginStatus.loading, error: null));

    final now = DateTime.now();
    final attTime = DateFormat('HH:mm:ss').format(now);
    final attDate = DateFormat('dd-MMM-yyyy').format(now);

    try {
      final http.Response res = await repo.login(
        email: e.email,
        pass: e.password,
        latitude: "24.8870845",
        longitude: "66.9788333",
        actType: "LOGIN",
        action: "IN",
        attTime: attTime,
        attDate: attDate,
        appVersion: "2.0.2",
        add: "fyghfshfohfor",
        deviceId: "0d6bb3238ca24544",
      );

      if (res.statusCode == 200) {
        // Parse -> model
        final map = jsonDecode(res.body);
        final model = LoginModel.fromJson(map);

        // Put model in state AND persist to storage
        await LocalSession.saveLogin(model);
        emit(state.copyWith(loginModel: model, loginStatus: LoginStatus.success, error: null));
      } else {
        await LocalSession.clearLogin();
        emit(state.copyWith(loginStatus: LoginStatus.failure, error: 'Login failed (${res.statusCode})'));
      }
    } catch (err) {
      await LocalSession.clearLogin();
      emit(state.copyWith(loginStatus: LoginStatus.failure, error: '$err'));
    }
  }

  Future<void> _getLeavesTypes(GetLeavesTypeEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(getLeavesTypeStatus: GetLeavesTypeStatus.loading, error: null));
    try {
      final model = await repo.getLeaveTypes(userId: event.userId);
      final ok = (model.status ?? '') == '1';
      emit(state.copyWith(
        getLeavesTypeStatus: ok ? GetLeavesTypeStatus.success : GetLeavesTypeStatus.failure,
        getLeaveTypeModel: ok ? model : null,
        error: ok ? null : (model.message ?? 'failed'),
      ));
    } catch (err) {
      emit(state.copyWith(getLeavesTypeStatus: GetLeavesTypeStatus.failure, error: '$err'));
    }
  }
}

// class AuthBloc extends Bloc<AuthEvent, AuthState> {
//   final Repository repo;
//   LoginModel loginModel = LoginModel();
//   AuthBloc(this.repo) : super(const AuthState()) {
//     on<GetLeavesTypeEvent>(_getLeavesTypes);
//     on<LoginEvent>(_onLogin);
//   }

  



// Future<void> _onLogin(LoginEvent e, Emitter<AuthState> emit) async {
//     emit(state.copyWith(loginStatus: LoginStatus.loading));

//     // If you have real values, plug them here (GPS/device/appVersion).
//     // For now we mirror your working hard-coded payload.
//     final now = DateTime.now();
//     final attTime  = DateFormat('HH:mm:ss').format(now);
//     final attDate  = DateFormat('dd-MMM-yyyy').format(now); 

//     try {
//       final res = await repo.login(
//         email: e.email,
//         pass: e.password,
//         latitude: "24.8870845",
//         longitude: "66.9788333",
//         actType: "LOGIN",
//         action: "IN",
//         attTime: attTime,          
//         attDate: attDate,
//         appVersion: "2.0.2",
//         add: "fyghfshfohfor",
//         deviceId: "0d6bb3238ca24544",
//       );

//       final ok = res.statusCode == 200;
//       if (ok) {
//         emit(state.copyWith(loginStatus: LoginStatus.success));
//       } else {
//         emit(state.copyWith(
//           loginStatus: LoginStatus.failure,
//           error: 'Login failed (${res.statusCode})',
//         ));
//       }
//     } catch (err) {
//       emit(state.copyWith(loginStatus: LoginStatus.failure, error: '$err'));
//     }
//   }










//   Future<void> _getLeavesTypes(
//     GetLeavesTypeEvent event,
//     Emitter<AuthState> emit,
//   ) async {

//     emit(state.copyWith(getLeavesTypeStatus: GetLeavesTypeStatus.loading));

//     try {
//       final model = await repo.getLeaveTypes(userId: event.userId);
//       final ok = (model.status ?? '') == '1';
  
//       emit(state.copyWith(
//         getLeavesTypeStatus:
//             ok ? GetLeavesTypeStatus.success : GetLeavesTypeStatus.failure,
//         getLeaveTypeModel: ok ? model : null,
//         error: ok ? null : (model.message ?? 'failed'),
//       ));
//     } catch (err) {
//       emit(state.copyWith(
//         getLeavesTypeStatus: GetLeavesTypeStatus.failure,
//         error: '$err',
//       ));
//     }
//   }

//   @override
//   void onEvent(AuthEvent event) {
//     // ignore: avoid_print
//     print('[AuthBloc] onEvent: ${event.runtimeType}');
//     super.onEvent(event);
//   }

//   @override
//   void onTransition(Transition<AuthEvent, AuthState> t) {
//     // ignore: avoid_print
//     print('[AuthBloc] transition: ${t.event.runtimeType} '
//         '${t.currentState.getLeavesTypeStatus} -> '
//         '${t.nextState.getLeavesTypeStatus}');
//     super.onTransition(t);
//   }
// }
