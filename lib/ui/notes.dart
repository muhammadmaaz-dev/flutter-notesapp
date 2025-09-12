import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:newapp/ui/add.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:newapp/ui/readNotes.dart';

class NotesUi extends StatefulWidget {
  const NotesUi({super.key});

  @override
  State<NotesUi> createState() => _NotesUiState();
}

class _NotesUiState extends State<NotesUi> {
  void toast() {
    if (mounted) {
      Navigator.pop(context, true);
      loadnotes();
      Fluttertoast.showToast(
        msg: "Deleted Sucessfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 20.sp,
        textColor: Colors.black,
        backgroundColor: Colors.red,
      );
    }
  }

  String selectedButton = 'All';

  List<Map<String, dynamic>> notes = [];

  void initState() {
    super.initState();
    DbHelper.dbHelper.getallnotes();
    loadnotes();
  }

  void loadnotes() async {
    var data = await DbHelper.dbHelper.getallnotes();
    setState(() {
      notes = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredNotes = selectedButton == 'All'
        ? notes
        : notes
              .where((note) => note[DbHelper.COL_NOTE_IMPORTANT] == 1)
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "",
            style: TextStyle(color: Colors.white, fontSize: 25.sp),
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 10.h,
              left: 15.w,
              right: 15.w,
              bottom: 5.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Notes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40.sp,
                    fontFamily: 'NunitoBold',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xff1a1a1a),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      bool? isadded = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder:
                              (context, animation, secondaryAnimation) => Add(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(
                                  0.0,
                                  1.0,
                                ); // bottom se start
                                const end = Offset.zero; // apni jagah
                                const curve = Curves.ease;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                        ),
                      );

                      // bool? isadded = await Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => Add()),
                      // );

                      if (isadded == true) {
                        loadnotes();
                      }
                    },
                    icon: Icon(Icons.add, color: Colors.white, size: 30.sp),
                  ),
                ),
              ],
            ),
          ),

          //SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: EdgeInsets.all(15.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        selectedButton == 'All' ? Colors.white : Colors.black,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedButton = 'All';
                      });
                    },
                    child: Text(
                      "All(${notes.length})",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: 'NunitoBold',
                        color: selectedButton == 'All'
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        selectedButton == 'All' ? Colors.black : Colors.white,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedButton = 'Important';
                      });
                    },
                    child: Text(
                      "Important(${notes.where((n) => n[DbHelper.COL_NOTE_IMPORTANT] == 1).length})",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: 'NunitoBold',
                        color: selectedButton == 'All'
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
              ),
            ),
          ),

          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Text(
                      "No Notes yet",
                      style: TextStyle(color: Colors.white, fontSize: 25.sp),
                    ),
                  )
                : MasonryGridView.count(
                    itemCount: filteredNotes.length,

                    crossAxisCount: 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,

                    itemBuilder: (context, index) {
                      var note = filteredNotes[index];

                      Color noteColor = Color(note[DbHelper.COL_NOTE_COLOR]);

                      return Padding(
                        padding: EdgeInsets.all(5.r),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 500,
                                ), // thoda slow for smoothness
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        readnotes(
                                          title: note[DbHelper.COL_NOTE_TITLE],
                                          desc: note[DbHelper.COL_NOTE_DESC],
                                          color: Color(
                                            note[DbHelper.COL_NOTE_COLOR],
                                          ),
                                        ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;

                                      // 👇 advanced smooth curve
                                      var curve = Curves.easeInOutCubic;

                                      var tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                              ),
                            );
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => readnotes(
                            //       title: note[DbHelper.COL_NOTE_TITLE],
                            //       desc: note[DbHelper.COL_NOTE_DESC],
                            //       color: Color(note[DbHelper.COL_NOTE_COLOR]),
                            //     ),
                            //   ),
                            // );
                          },

                          onLongPress: () {
                            bottomSheet(
                              context,
                              note[DbHelper.COL_NOTE_SNO],
                              loadnotes,
                              toast,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(25.r),
                              ),
                              color: noteColor,
                            ),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 10.w,
                                    right: 10.w,
                                    top: 5.h,
                                  ),
                                  child: Text(
                                    note[DbHelper.COL_NOTE_TITLE],

                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 21.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'NunitoBold',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 10.w,
                                    right: 10.w,
                                    bottom: 5.h,
                                  ),
                                  child: Text(
                                    note[DbHelper.COL_NOTE_DESC],
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

void bottomSheet(
  BuildContext context,
  int noteID,
  Function loadnotes,
  Function toast,
) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white)),
        ),
        height: 200.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              child: ListTile(
                leading: Icon(Icons.edit, size: 25.sp, color: Colors.white),
                title: Text(
                  "Edit Note",
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontFamily: 'NunitoBold',
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await DbHelper.dbHelper.impotantNote(noteID);
                Navigator.pop(context, true);
                loadnotes();

                Fluttertoast.showToast(
                  msg: "Marked as Important",
                  textColor: Colors.black,
                  toastLength: Toast.LENGTH_SHORT,
                  backgroundColor: Colors.lime,
                  gravity: ToastGravity.BOTTOM,
                  fontSize: 20.sp,
                );
              },
              child: ListTile(
                leading: Icon(
                  Icons.label_important_outline,
                  size: 25.sp,
                  color: Colors.white,
                ),
                title: Text(
                  "Mark as important",
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontFamily: 'NunitoBold',
                  ),
                ),
              ),
            ),

            GestureDetector(
              child: ListTile(
                leading: Icon(Icons.delete, size: 25.sp, color: Colors.white),
                title: Text(
                  "Delete Note",
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontFamily: 'NunitoBold',
                  ),
                ),
              ),

              onTap: () async {
                await DbHelper.dbHelper.deleteNote(noteID);
                toast();
              },
            ),
          ],
        ),
      );
    },
  );
}
