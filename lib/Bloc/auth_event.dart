abstract class AuthEvent {}

class GetLeavesTypeEvent extends AuthEvent {
  final String userId;
  GetLeavesTypeEvent(this.userId);
}
