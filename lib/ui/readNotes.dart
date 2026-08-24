import 'package:flutter/material.dart';
import 'package:newapp/ui/add.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class readnotes extends StatelessWidget {
  final int? noteId;
  final String title;
  final String desc;
  final Color color;

  const readnotes({
    super.key,
    this.noteId,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 35.sp,
                  ),
                  IconButton(
                    onPressed: () async {
                      bool? isUpdated = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (context, animation, secondaryAnimation) => Add(
                            noteId: noteId,
                            existingTitle: title,
                            existingDesc: desc,
                            existingColor: color,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                      );
                      if (isUpdated == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    iconSize: 35.sp,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'NunitoBold',
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }
}
