import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/test_provider.dart';
import 'providers/edu_plan_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/user_provider.dart';
import 'providers/student_exam_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void navigateToLogin() {
  navigatorKey.currentState?.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    ),
    (route) => false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // runApp ishga tushishidan oldin logindan chiqarib yuboramiz. (har doim so'rashi uchun)
  // AuthProvider ichida `StorageService` bor, u yerda `_loadStoredUser` o'chirib qo'yilgan bo'lishi kerak
  runApp(const BilimScanApp());
}

class BilimScanApp extends StatelessWidget {
  const BilimScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => EduPlanProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StudentExamProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        title: 'IIV Akademik Litseyi - Bilim Scan',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark, // Har doim dark mode bo'lishini ta'minlash
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.goldPrimary,
            secondary: AppColors.emeraldAccent,
            surface: AppColors.cardDark,
          ),
        ),
        theme: ThemeData( // Windows kabi OT larda "System theme" oq bo'lsa ham qorani ishlatishi uchun
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.goldPrimary,
            secondary: AppColors.emeraldAccent,
            surface: AppColors.cardDark,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
