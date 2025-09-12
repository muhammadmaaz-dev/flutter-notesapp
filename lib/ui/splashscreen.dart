import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:newapp/ui/add.dart';
import 'package:newapp/ui/notes.dart'; // <-- Add wali screen import karo

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      backgroundColor: Colors.black,
      splash: SizedBox(
        height: 500.h,
        width: 500.w,
        child: Center(
          child: Lottie.asset('assets/animation.json', fit: BoxFit.contain),
        ),
      ),
      splashIconSize: 800.sp,
      duration: 1500,
      nextScreen: const NotesUi(), // <-- yahan sirf widget dena hai
      splashTransition: SplashTransition.fadeTransition, // optional animation
    );
  }
}
