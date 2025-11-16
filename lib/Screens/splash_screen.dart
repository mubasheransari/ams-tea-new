import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart' show AuthBloc;
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _logoPath = 'assets/ams_logo_underline.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final token = (GetStorage().read<String>('auth_token') ?? '').trim();
      final hasToken = token.isNotEmpty;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const AuthScreen(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WatermarkTiledSmall(tileScale: 25.0),

          Positioned(
            top: 350,
            left: 58,
            child: Image.asset(
              _logoPath,
              width: 320,
              height: 160,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
