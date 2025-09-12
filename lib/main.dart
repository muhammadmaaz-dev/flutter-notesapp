import 'package:flutter/material.dart';
import 'package:newapp/ui/add.dart';
import 'package:newapp/ui/notes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:newapp/ui/splashscreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NotesApp',
          home: Splashscreen(),
        );
      },
    );
  }
}
