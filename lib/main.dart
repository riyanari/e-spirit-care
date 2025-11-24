import 'package:e_spirit_care/cubit/auth_cubit.dart';
import 'package:e_spirit_care/cubit/child_cubit.dart';
import 'package:e_spirit_care/pages/child_dashboard_page.dart';
import 'package:e_spirit_care/pages/home_page.dart';
import 'package:e_spirit_care/pages/list_ortu_page.dart';
import 'package:e_spirit_care/pages/login_page.dart';
import 'package:e_spirit_care/pages/video_recomendation_page.dart';
import 'package:e_spirit_care/services/reminder_service.dart';
import 'package:e_spirit_care/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'models/child_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => ChildCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashPage(),
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomePage(),
          '/child-dashboard': (_) => const ChildDashboardPage(),
          '/list-ortu': (context) {
            // Ambil role dari AuthCubit atau state management
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthSuccess) {
              return ListOrtuPage(currentUserRole: authState.user.role);
            } else {
              // Fallback jika tidak ada state
              return const ListOrtuPage(currentUserRole: 'ortu');
            }
          },
        },
        onGenerateRoute: (settings) {
          // Handle routes dengan parameter jika diperlukan
          switch (settings.name) {
            case '/video-recommendations':
              final child = settings.arguments as ChildModel?;
              if (child != null) {
                return MaterialPageRoute(
                  builder: (_) => VideoRecommendationsPage(child: child),
                );
              }
              break;
          }
          return null;
        },
      ),
    );
  }
}