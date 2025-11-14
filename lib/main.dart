import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Data/local_sessions.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:new_amst_flutter/Screens/app_shell.dart';
import 'package:new_amst_flutter/Screens/splash_screen.dart';
void main() async{
    await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  final repo = Repository();
  final authBloc = AuthBloc(repo);
   // ..add(LoginEvent('mubashera38@gmail.com','123')); 

  runApp(MyApp(repo: repo, authBloc: authBloc));
}

class MyApp extends StatelessWidget {
  final Repository repo;
  final AuthBloc authBloc;
  const MyApp({super.key, required this.repo, required this.authBloc});

  @override
  Widget build(BuildContext context) {
      final hasSession = LocalSession.readLogin() != null;
    return MaterialApp(
      title: 'AMS-T',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),


      builder: (context, child) {
        return RepositoryProvider.value(
          value: repo,
          child: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: child!,
          ),
        );
      },

      home: hasSession ? AppShell() : SplashScreen(),
    );
  }
}
