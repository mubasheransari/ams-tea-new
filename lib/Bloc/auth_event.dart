// abstract class AuthEvent {}

// class GetLeavesTypeEvent extends AuthEvent {
//   final String userId;
//   GetLeavesTypeEvent(this.userId);
// }

// class LoginEvent extends AuthEvent {
//   final String email,password;
//   LoginEvent(this.email,this.password);
// }

abstract class AuthEvent {}

class GetLeavesTypeEvent extends AuthEvent {
  final String userId;
  GetLeavesTypeEvent(this.userId);
}

class LoginEvent extends AuthEvent {
  final String email, password;
  LoginEvent(this.email, this.password);
}
