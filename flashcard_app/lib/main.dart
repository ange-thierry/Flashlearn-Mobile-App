import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/fields_screen.dart';
import 'screens/field_home_screen.dart';
import 'screens/study_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/certificate_screen.dart';
import 'screens/award_certificate_screen.dart';
import 'screens/smart_notes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final isLoggedIn = FirebaseAuth.instance.currentUser != null;
  final isAdmin = FirebaseAuth.instance.currentUser?.email == adminEmail;

  String initialRoute;
  if (isLoggedIn) {
    initialRoute = isAdmin ? '/admin' : '/fields';
  } else {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    initialRoute = onboardingDone ? '/' : '/onboarding';
  }

  // Notification setup (FCM permissions, channel creation, scheduled reminders)
  // is deferred so the UI appears immediately instead of waiting ~2–3 s.
  NotificationService().initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: FlashcardApp(initialRoute: initialRoute),
    ),
  );
}

class FlashcardApp extends StatelessWidget {
  final String initialRoute;
  const FlashcardApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Flashcard Learning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prov.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/': (_) => const LoginScreen(),
        '/fields': (_) => const FieldsScreen(),
        '/field-home': (_) => const FieldHomeScreen(),
        '/study': (_) => const StudyScreen(),
        '/quiz': (_) => const QuizScreen(),
        '/result': (_) => const ResultScreen(),
        '/admin': (_) => const AdminScreen(),
        '/weekly-report': (_) => const WeeklyReportScreen(),
        '/achievements': (_) => const AchievementsScreen(),
        '/bookmarks': (_) => const BookmarksScreen(),
        '/stats':         (_) => const StatsScreen(),
        '/certificate':       (_) => const CertificateScreen(),
        '/award-certificate': (_) => const AwardCertificateScreen(),
        '/smart-notes':       (_) => const SmartNotesScreen(),
      },
    );
  }
}
