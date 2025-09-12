import 'package:flutter/material.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:newapp/ui/notes.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> {
  @override
  final titleController = TextEditingController();
  final descController = TextEditingController();
  Color selectedcolor = Colors.white;
  Widget build(BuildContext context) {
    final List<Color> bgColor = [
      Color(0xfffca590),
      Color(0xffffffa0),
      Color(0xffcdeff1),
      Color(0xfff8e7b4),
      Color.fromARGB(255, 214, 252, 144),
      Color.fromARGB(255, 231, 137, 114),
      Color.fromARGB(255, 144, 200, 252),
      Color.fromARGB(255, 191, 144, 252),
      Color.fromARGB(255, 239, 109, 109),
      Color.fromARGB(255, 137, 65, 231),
      Color.fromARGB(255, 255, 72, 173),
      Color.fromARGB(255, 112, 199, 105),
    ];

    void _callbottomsheet() {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.all(8.0.r),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: bgColor.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedcolor = color;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 25.r,
                    child: selectedcolor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    }

    final bottomInset = MediaQuery.of(
      context,
    ).viewInsets.bottom; // keyboard height

    return Scaffold(
      backgroundColor: selectedcolor,
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
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        false,
                        //MaterialPageRoute(builder: (context) => NotesUi()),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 35.sp,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Title
              TextField(
                controller: titleController,
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'NunitoBold',
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 31, 30, 30),
                    fontFamily: 'NunitoBold',
                  ),
                  border: InputBorder.none,
                ),
              ),
              SizedBox(height: 15.h),
              // Description
              TextField(
                controller: descController,
                keyboardType: TextInputType.multiline,
                maxLines: null, // taake scroll ho sake, overflow na ho
                style: TextStyle(
                  fontSize: 25.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
                decoration: InputDecoration(
                  hintText: "Description",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 31, 30, 30),
                    fontFamily: 'NunitoBold',
                  ),
                  border: InputBorder.none,
                ),
              ),

              SizedBox(height: 100.h), // content ke end me thodi space
            ],
          ),
        ),
      ),

      // ---- BOTTOM BAR (keyboard ke upar chipak jayega) ----
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(40, 10, 40, bottomInset + 20),
        child: Container(
          height: 85.h,

          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  _callbottomsheet();
                },
                child: _BottomButton(
                  icon: Icons.color_lens_rounded,
                  color: selectedcolor,
                ),
              ),
              GestureDetector(
                child: _BottomButton(icon: Icons.save, color: selectedcolor),
                onTap: () async {
                  await DbHelper.dbHelper.addnote(
                    mTilte: titleController.text,
                    mDesc: descController.text,
                    mColor: selectedcolor,
                  );
                  Navigator.pop(context, true);
                  Fluttertoast.showToast(
                    msg: "Added Sucessfully",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    fontSize: 20.sp,
                    textColor: Colors.black,
                    backgroundColor: Colors.green,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _BottomButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: 35.sp, color: Colors.black),
    );
  }
}
