import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:newapp/services/supabase_analytics_service.dart';
import 'package:newapp/ui/notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    HapticFeedback.lightImpact();
    
    // Asynchronously register anonymous user in Supabase (Non-blocking)
    SupabaseAnalyticsService.instance.registerUser();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NotesUi(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // -------------------------------------------------------------
              // 1. Minimal Logo & App Badge
              // -------------------------------------------------------------
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.r),
                  child: Image.asset(
                    'assets/1b1ebb0d0b3b5d8b-capybara-7.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.sticky_note_2_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // -------------------------------------------------------------
              // 2. Bold Editorial Typography
              // -------------------------------------------------------------
              Text(
                "Your thoughts,\nuncluttered & offline.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.sp,
                  fontFamily: 'NunitoBold',
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Capture ideas instantly with zero distractions.\n100% private, no account needed.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14.sp,
                  fontFamily: 'Nunito',
                  height: 1.35,
                ),
              ),

              const Spacer(flex: 2),

              // -------------------------------------------------------------
              // 3. Premium Minimal Feature Rows
              // -------------------------------------------------------------
              _MinimalFeatureRow(
                icon: Icons.shield_outlined,
                iconColor: Colors.black,
                iconBg: const Color(0xffcdeff1),
                title: "100% Offline & Private",
                description: "No cloud servers. Your notes never leave this device.",
              ),
              SizedBox(height: 14.h),
              _MinimalFeatureRow(
                icon: Icons.bolt_rounded,
                iconColor: Colors.black,
                iconBg: const Color(0xffffffa0),
                title: "Seamless Auto-Save",
                description: "Write freely. Every stroke is saved instantly in real time.",
              ),
              SizedBox(height: 14.h),
              _MinimalFeatureRow(
                icon: Icons.alarm_rounded,
                iconColor: Colors.black,
                iconBg: const Color.fromARGB(255, 214, 252, 144),
                title: "Exact Offline Alarms",
                description: "Scheduled local notifications that ring right on time.",
              ),
              SizedBox(height: 14.h),
              _MinimalFeatureRow(
                icon: Icons.palette_outlined,
                iconColor: Colors.black,
                iconBg: const Color(0xfffca590),
                title: "Vibrant Color System",
                description: "Categorize and organize notes with intuitive color palettes.",
              ),

              const Spacer(flex: 2),

              // -------------------------------------------------------------
              // 4. CTA Button (Smooth scale & haptic)
              // -------------------------------------------------------------
              AnimatedBuilder(
                animation: _btnScale,
                builder: (context, child) => Transform.scale(
                  scale: _btnScale.value,
                  child: child,
                ),
                child: GestureDetector(
                  onTapDown: (_) => _btnController.forward(),
                  onTapUp: (_) {
                    _btnController.reverse();
                    _handleGetStarted();
                  },
                  onTapCancel: () => _btnController.reverse(),
                  child: Container(
                    height: 54.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Get Started",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17.sp,
                            fontFamily: 'NunitoBold',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              Center(
                child: Text(
                  "Free forever • No ads • No data collection",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12.sp,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Minimalist Feature Row Widget
// -----------------------------------------------------------------------------
class _MinimalFeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _MinimalFeatureRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: iconColor,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'NunitoBold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.sp,
                    fontFamily: 'Nunito',
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
