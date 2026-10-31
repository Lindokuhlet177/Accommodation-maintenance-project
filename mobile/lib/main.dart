import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/requests_viewmodel.dart';
import 'core/constants/app_routes.dart';
import 'views/splash/splash_screen.dart';
import 'views/widgets/coming_soon_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/home/main_shell.dart';
import 'viewmodels/report_request_viewmodel.dart';
import 'views/report/report_request_screen.dart';
import 'viewmodels/request_details_viewmodel.dart';
import 'views/requests/request_details_screen.dart';
import 'viewmodels/confirm_resolution_viewmodel.dart';
import 'views/resolution/confirm_resolution_screen.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'views/notifications/notifications_screen.dart';
import 'views/profile/edit_profile_screen.dart';
import 'views/profile/help_support_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.publishableKey,
  );

  runApp(
    // App-wide ViewModels: available on every screen
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => RequestsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        
      ],
      child: const StudentStayFixApp(),
    ),
  );
}

class StudentStayFixApp extends StatelessWidget {
  const StudentStayFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudentStayFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signUp: (_) => const SignUpScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.report: (_) => ChangeNotifierProvider(
          create: (_) => ReportRequestViewModel(),
          child: const ReportRequestScreen()),

                  AppRoutes.requestDetails: (context) => ChangeNotifierProvider(
              create: (_) => RequestDetailsViewModel(),
              child: RequestDetailsScreen(
                // The request id sent with pushNamed(..., arguments: id)
                requestId: ModalRoute.of(context)!.settings.arguments as int,
              ),
            ),

                    AppRoutes.confirmResolution: (context) => ChangeNotifierProvider(
              create: (_) => ConfirmResolutionViewModel(),
              child: ConfirmResolutionScreen(
                requestId: ModalRoute.of(context)!.settings.arguments as int,
              ),
            ),
                    AppRoutes.notifications: (_) => const NotificationsScreen(),
                   AppRoutes.editProfile: (_) => const EditProfileScreen(),
                   AppRoutes.helpSupport: (_) => const HelpSupportScreen(),
        // More screens are added here as we build them
      },
      // Any screen not built yet shows "Coming soon"
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => ComingSoonScreen(title: settings.name ?? ''),
      ),
    );
  }
}

/// Temporary screen: also proves Provider is connected.
class ThemeCheckScreen extends StatelessWidget {
  const ThemeCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reads the AuthViewModel from Provider
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_repair_service, size: 90, color: Colors.white),
              const SizedBox(height: 32),
              Text(
                auth.isLoggedIn ? 'Provider OK: logged in' : 'Provider OK: logged out',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}