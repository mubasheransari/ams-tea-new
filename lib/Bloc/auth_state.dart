import 'package:equatable/equatable.dart';
import 'package:new_amst_flutter/Model/getLeaveType.dart';



enum GetLeavesTypeStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final GetLeavesTypeStatus getLeavesTypeStatus;
  final GetLeaveTypeModel? getLeaveTypeModel;
  final String? error;

  const AuthState({
    this.getLeavesTypeStatus = GetLeavesTypeStatus.initial,
    this.getLeaveTypeModel,
    this.error,
  });

  AuthState copyWith({
    GetLeavesTypeStatus? getLeavesTypeStatus,
    GetLeaveTypeModel? getLeaveTypeModel,
    String? error,
  }) {
    return AuthState(
      getLeavesTypeStatus: getLeavesTypeStatus ?? this.getLeavesTypeStatus,
      getLeaveTypeModel: getLeaveTypeModel ?? this.getLeaveTypeModel,
      error: error,
    );
  }

  @override
  List<Object?> get props => [getLeavesTypeStatus, getLeaveTypeModel, error];
}
