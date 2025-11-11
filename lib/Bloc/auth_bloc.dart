import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:bloc/bloc.dart';




class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Repository repo;

  AuthBloc(this.repo) : super(const AuthState()) {
    on<GetLeavesTypeEvent>(_getLeavesTypes);
    print('[AuthBloc] constructed');
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
