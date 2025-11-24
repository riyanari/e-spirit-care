import 'dart:async';

import 'package:e_spirit_care/cubit/auth_cubit.dart';
import 'package:e_spirit_care/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'components/half_circle_painter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndNavigate());
  }

  Future<void> _checkAuthAndNavigate() async {
    debugPrint('[SPLASH] Mulai cek auto login');

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      debugPrint('[SPLASH] currentUser: ${user?.uid}');

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) {
        debugPrint('[SPLASH] Widget sudah unmounted, stop');
        return;
      }

      // ✅ CUKUP CEK user SAJA
      if (user == null) {
        debugPrint('[SPLASH] user null → pindah ke /login');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        return;
      }

      // Reload untuk pastikan user masih valid
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      debugPrint('[SPLASH] refreshedUser: ${refreshedUser?.uid}');

      if (refreshedUser == null) {
        debugPrint('[SPLASH] refreshedUser null setelah reload → ke /login');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        return;
      }

      // Panggil cubit
      final authCubit = context.read<AuthCubit>();
      debugPrint('[SPLASH] Panggil authCubit.getCurrentUser(${refreshedUser.uid})');

      await authCubit.getCurrentUser(refreshedUser.uid);
      debugPrint('[SPLASH] getCurrentUser SELESAI');

      if (!mounted) return;

      final state = authCubit.state;

      if (state is AuthSuccess) {
        final role = state.user.role.toLowerCase();
        debugPrint('[SPLASH] Role user: $role');

        if (role == 'admin') {
          debugPrint('[SPLASH] Role admin → ke /list-ortu-page');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/list-ortu',
                (_) => false,
          );
        } else {
          debugPrint('[SPLASH] Role bukan admin → ke /home');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
                (_) => false,
          );
        }
      } else {
        debugPrint('[SPLASH] State bukan AuthSuccess → ke /login');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e, s) {
      debugPrint('[SPLASH] ERROR: $e');
      debugPrint('[SPLASH] STACKTRACE: $s');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 90,
            right: -50,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(color: const Color(0x33B8FFD8)),
            ),
          ),
          Positioned(
            top: -30,
            right: -75,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(color: const Color(0x3396FFC6)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/logo-spirit.png',
                      width: MediaQuery.of(context).size.width * 0.7,
                    ),
                  ),
                ),
                const CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  backgroundColor: kBoxGreenColor,
                  semanticsLabel: 'Loading...',
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
