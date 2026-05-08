import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/globals.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/employee_provider.dart';
import 'core/providers/intern_provider.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/company_provider.dart';

void main() async {
  // Ensuring the Flutter engine is ready before calling any async methods
  WidgetsFlutterBinding.ensureInitialized();
  
  // Starting the root widget of the application
  runApp(const LearnyorHRMApp());
}

class LearnyorHRMApp extends StatelessWidget {
  const LearnyorHRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Core Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // 2. Data Providers with JWT Injection using ProxyProvider
        ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
          create: (_) => EmployeeProvider(),
          update: (_, auth, employee) => employee!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InternProvider>(
          create: (_) => InternProvider(),
          update: (_, auth, intern) => intern!..updateToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, auth, attendance) => attendance!..updateToken(auth.token),
        ),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
      ],
      // Consumer listens for changes in AuthProvider to rebuild the router if user logs in/out
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Getting the dynamic router configuration based on the user's auth state
          final router = AppRouter.getRouter(auth);
          return MaterialApp.router(
            title: 'Learnyor HRM',
            theme: AppTheme.lightTheme, // Using our custom corporate theme
            routerConfig: router, // Integrating GoRouter for navigation
            scaffoldMessengerKey: Globals.scaffoldMessengerKey,
            debugShowCheckedModeBanner: false, // Hides the debug tag
          );
        },
      ),
    );
  }
}
