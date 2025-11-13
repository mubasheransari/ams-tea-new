import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart' show AuthBloc;
import 'package:new_amst_flutter/Screens/app_shell.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';
           

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  static const _logoPath   = 'assets/ams_logo_underline.png';

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


      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(
      //     builder: (_) => hasToken
      //         ? const AppShell() //InspectionHomePixelPerfect()
      //         :  AuthScreen(),
      //   ),
      //   (route) => false,
      // );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
    //   fit: StackFit.expand,
        children: [
               WatermarkTiledSmall(tileScale: 25.0),

               Positioned(
                 top: 350,
                left: 58,
                 child: Image.asset(
                    _logoPath,
                    width:320,
                    height: 160,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
               ),
      /*    Align(
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = MediaQuery.of(context).size.width;
                final logoW = w * 0.64; // 64% of screen width (looks like your mock)
                return Image.asset(
                  _logoPath,
                  width: logoW,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                );
              },
            ),
          ),
          */

        ],
      ),
      backgroundColor: Colors.white, 
    );
  }
}


