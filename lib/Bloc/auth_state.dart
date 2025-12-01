import 'package:equatable/equatable.dart';
import 'package:new_amst_flutter/Model/getLeaveType.dart';
import 'package:new_amst_flutter/Model/loginModel.dart';




enum GetLeavesTypeStatus { initial, loading, success, failure }
enum LoginStatus { initial, loading, success, failure }

enum MapLoadStatus { initial, creating, almostReady, ready }

class AuthState extends Equatable {
  final GetLeavesTypeStatus getLeavesTypeStatus;
  final LoginStatus loginStatus;
  final GetLeaveTypeModel? getLeaveTypeModel;
  final LoginModel? loginModel;
  final String? error;

  // 🔥 NEW: map load status
  final MapLoadStatus mapLoadStatus;

  const AuthState({
    this.getLeavesTypeStatus = GetLeavesTypeStatus.initial,
    this.loginStatus = LoginStatus.initial,
    this.getLeaveTypeModel,
    this.loginModel,
    this.error,
    this.mapLoadStatus = MapLoadStatus.initial, // default
  });

  AuthState copyWith({
    GetLeavesTypeStatus? getLeavesTypeStatus,
    LoginStatus? loginStatus,
    GetLeaveTypeModel? getLeaveTypeModel,
    LoginModel? loginModel,
    String? error,
    MapLoadStatus? mapLoadStatus,
  }) {
    return AuthState(
      getLeavesTypeStatus: getLeavesTypeStatus ?? this.getLeavesTypeStatus,
      loginStatus: loginStatus ?? this.loginStatus,
      getLeaveTypeModel: getLeaveTypeModel ?? this.getLeaveTypeModel,
      loginModel: loginModel ?? this.loginModel,
      error: error,
      mapLoadStatus: mapLoadStatus ?? this.mapLoadStatus,
    );
  }

  // 🔥 optional helper getters
  bool get isMapAlmostReady => mapLoadStatus == MapLoadStatus.almostReady;
  bool get isMapReady => mapLoadStatus == MapLoadStatus.ready;

  @override
  List<Object?> get props => [
        getLeavesTypeStatus,
        loginStatus,
        getLeaveTypeModel,
        loginModel,
        error,
        mapLoadStatus,
      ];
}


