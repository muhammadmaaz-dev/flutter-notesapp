import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:newapp/services/notification_service.dart';
import 'package:newapp/services/supabase_analytics_service.dart';
import 'package:newapp/services/supabase_service.dart';
import 'package:newapp/ui/notes.dart';
import 'package:newapp/ui/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Backend
  await SupabaseService.instance.init();

  // 2. Initialize Anonymous Analytics & Offline Sync Engine
  await SupabaseAnalyticsService.instance.init();

  // 3. Initialize Local Notifications
  await NotificationService.instance.init();

  // 4. Load Onboarding State
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboarded = prefs.getBool('is_onboarded') ?? false;

  runApp(MyApp(isOnboarded: isOnboarded));

  // 5. Check if app was launched via a notification click (cold start)
  NotificationService.instance.checkLaunchNotification();
}

class MyApp extends StatefulWidget {
  final bool isOnboarded;
  const MyApp({super.key, this.isOnboarded = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SupabaseAnalyticsService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SupabaseAnalyticsService.instance.syncPendingUserAndActiveStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: NotificationService.instance.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Noto',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          ),
          home: widget.isOnboarded ? const NotesUi() : const OnboardingScreen(),
        );
      },
    );
  }
}
