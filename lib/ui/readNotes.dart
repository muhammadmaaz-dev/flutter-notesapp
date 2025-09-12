import 'package:flutter/material.dart';
import 'package:newapp/ui/notes.dart';
import 'package:newapp/ui/add.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class readnotes extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;

  readnotes({
    super.key,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      resizeToAvoidBottomInset: true, // body keyboard ke saath resize ho
      // ---- BODY ----
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Back button row
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
                    onPressed: () {},
                    icon: Icon(Icons.edit),
                    iconSize: 35.sp,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Title
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

              // Description
              Text(
                desc,
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Nunito',
                ),
              ),

              SizedBox(height: 100.h), // content ke end me thodi space
            ],
          ),
        ),
      ),
    );
  }
}
