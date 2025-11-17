import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Data/local_sessions.dart';
import 'package:new_amst_flutter/Model/loginModel.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:bloc/bloc.dart';

var storage = GetStorage();

final now = DateTime.now();
final currentDate = DateFormat("dd-MMM-yyyy").format(now);
final currentTime = DateFormat("HH:mm:ss").format(now);

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repository repo;
  AuthBloc(this.repo) : super(const AuthState()) {
    on<LoginEvent>(_onLogin);

    final cached = LocalSession.readLogin();
    if (cached != null) {
      emit(state.copyWith(loginModel: cached));
    }
  }

  Future<void> _onLogin(LoginEvent e, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: LoginStatus.loading, error: null));

    final now = DateTime.now();
    final attTime = DateFormat('HH:mm:ss').format(now);
    final attDate = DateFormat('dd-MMM-yyyy').format(now);
    var deviceID = storage.read('device_id');

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
        deviceId:deviceID//"0d6bb3238ca24544",
      );

      debugPrint("BODY ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final status = body['status']?.toString();
        final message = body['message']?.toString() ?? 'Unknown error';

        if (status == '1') {
          final model = LoginModel.fromJson(body);
          await LocalSession.saveLogin(model);

          emit(
            state.copyWith(
              loginModel: model,
              loginStatus: LoginStatus.success,
              error: null,
            ),
          );
        } else {
          await LocalSession.clearLogin();
          emit(
            state.copyWith(
              loginStatus: LoginStatus.failure,
              error: message.isEmpty ? 'Invalid login' : message,
            ),
          );
        }
      } else {
        await LocalSession.clearLogin();
        emit(
          state.copyWith(
            loginStatus: LoginStatus.failure,
            error: 'Login failed (${res.statusCode})',
          ),
        );
      }
    } catch (err) {
      await LocalSession.clearLogin();
      emit(state.copyWith(loginStatus: LoginStatus.failure, error: '$err'));
    }
  }
}
