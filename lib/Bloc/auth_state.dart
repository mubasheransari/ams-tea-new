import 'package:equatable/equatable.dart';
import 'package:new_amst_flutter/Model/getLeaveType.dart';
import 'package:new_amst_flutter/Model/loginModel.dart';



enum GetLeavesTypeStatus { initial, loading, success, failure }
enum LoginStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final GetLeavesTypeStatus getLeavesTypeStatus;
  final LoginStatus loginStatus;
  final GetLeaveTypeModel? getLeaveTypeModel;
  final LoginModel? loginModel;
  final String? error;

  const AuthState({
    this.getLeavesTypeStatus = GetLeavesTypeStatus.initial,
    this.loginStatus = LoginStatus.initial,
    this.getLeaveTypeModel,
    this.loginModel,
    this.error,
  });

  AuthState copyWith({
    GetLeavesTypeStatus? getLeavesTypeStatus,
    LoginStatus? loginStatus,
    GetLeaveTypeModel? getLeaveTypeModel,
    LoginModel? loginModel,
    String? error,
  }) {
    return AuthState(
      getLeavesTypeStatus: getLeavesTypeStatus ?? this.getLeavesTypeStatus,
      loginStatus: loginStatus ?? this.loginStatus,
      getLeaveTypeModel: getLeaveTypeModel ?? this.getLeaveTypeModel,
      loginModel: loginModel ?? this.loginModel,
      error: error,
    );
  }

  @override
  List<Object?> get props => [getLeavesTypeStatus, loginStatus, getLeaveTypeModel, loginModel, error];
}
