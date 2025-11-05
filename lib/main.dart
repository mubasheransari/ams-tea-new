import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Data/app_routes.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'package:new_amst_flutter/Screens/splash_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();                   
  final authRepo = AuthRepositoryHttp();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepo)..add(AppStarted()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS-T',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const  SplashScreen()//AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If no token, show Auth immediately
    final box   = GetStorage();
    final token = (box.read<String>('auth_token') ?? '').trim();
    if (token.isEmpty) return const AuthScreen();

    // With token: wait for profile to load; success -> Home, failure -> Auth
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => p.profileStatus != c.profileStatus,
      builder: (context, state) {
        switch (state.profileStatus) {
          case ProfileStatus.success:
            return const SplashScreen(); // this screen has the bottom bar
          case ProfileStatus.failure:
            // Optional: box.remove('auth_token');
            return const SplashScreen();
          case ProfileStatus.initial:
               return const SplashScreen();
          case ProfileStatus.loading:
          default:
            return const SplashScreen();
        }
      },
    );
  }
}

