import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:newapp/ui/add.dart';
import 'package:newapp/ui/readNotes.dart';

class NotesUi extends StatefulWidget {
  const NotesUi({super.key});

  @override
  State<NotesUi> createState() => _NotesUiState();
}

class _NotesUiState extends State<NotesUi> {
  String selectedButton = 'All';
  List<Map<String, dynamic>> notes = [];

  void toast() {
    if (mounted) {
      loadnotes();
      Fluttertoast.showToast(
        msg: "Deleted Successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 20.sp,
        textColor: Colors.black,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadnotes();
  }

  void loadnotes() async {
    try {
      var data = await DbHelper.dbHelper.getallnotes();
      if (mounted) {
        setState(() {
          notes = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading notes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredNotes = selectedButton == 'All'
        ? notes
        : notes
            .where((note) => note[DbHelper.COL_NOTE_IMPORTANT] == 1)
            .toList();

    final int importantCount =
        notes.where((n) => n[DbHelper.COL_NOTE_IMPORTANT] == 1).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. Collapsing Top Title & Add Action Row
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 10.h,
                  left: 15.w,
                  right: 15.w,
                  bottom: 5.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Notes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40.sp,
                            fontFamily: 'NunitoBold',
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "${notes.length} notes recorded",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14.sp,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          bool? isadded = await Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 500),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const Add(),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
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

                          if (isadded == true) {
                            loadnotes();
                          }
                        },
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Sticky Filter Pills Bar (pinned: true)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFilterBarDelegate(
                selectedButton: selectedButton,
                allCount: notes.length,
                importantCount: importantCount,
                onFilterChanged: (filter) {
                  setState(() {
                    selectedButton = filter;
                  });
                },
              ),
            ),

            // 3. Notes Grid / Empty States
            if (notes.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350.h,
                  child: Center(
                    child: Text(
                      "No Notes yet",
                      style: TextStyle(color: Colors.white, fontSize: 25.sp),
                    ),
                  ),
                ),
              )
            else if (filteredNotes.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350.h,
                  child: Center(
                    child: Text(
                      selectedButton == 'Important'
                          ? "No Important notes"
                          : "No Notes yet",
                      style: TextStyle(color: Colors.white, fontSize: 25.sp),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  itemBuilder: (context, index) {
                    var note = filteredNotes[index];
                    Color noteColor = Color(note[DbHelper.COL_NOTE_COLOR]);

                    return Padding(
                      padding: EdgeInsets.all(5.r),
                      child: GestureDetector(
                        onTap: () async {
                          bool? isUpdated = await Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 500,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      readnotes(
                                        noteId: note[DbHelper.COL_NOTE_SNO],
                                        title: note[DbHelper.COL_NOTE_TITLE],
                                        desc: note[DbHelper.COL_NOTE_DESC],
                                        color: Color(
                                          note[DbHelper.COL_NOTE_COLOR],
                                        ),
                                      ),
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
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

                          if (isUpdated == true) {
                            loadnotes();
                          }
                        },
                        onLongPress: () {
                          bottomSheet(
                            context,
                            note[DbHelper.COL_NOTE_SNO],
                            note[DbHelper.COL_NOTE_TITLE],
                            note[DbHelper.COL_NOTE_DESC],
                            note[DbHelper.COL_NOTE_COLOR],
                            note[DbHelper.COL_NOTE_IMPORTANT] == 1,
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  childCount: filteredNotes.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Sticky Filter Bar Sliver Delegate with exact Pill Styling & Badges
// -----------------------------------------------------------------------------
class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String selectedButton;
  final int allCount;
  final int importantCount;
  final ValueChanged<String> onFilterChanged;

  const _StickyFilterBarDelegate({
    required this.selectedButton,
    required this.allCount,
    required this.importantCount,
    required this.onFilterChanged,
  });

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 68.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // All Pill
          GestureDetector(
            onTap: () => onFilterChanged('All'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: selectedButton == 'All' ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: selectedButton == 'All'
                      ? Colors.white
                      : Colors.white24,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "All",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'NunitoBold',
                      fontWeight: FontWeight.bold,
                      color: selectedButton == 'All'
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: selectedButton == 'All'
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "$allCount",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: 'NunitoBold',
                        fontWeight: FontWeight.w800,
                        color: selectedButton == 'All'
                            ? Colors.black87
                            : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Important Pill
          GestureDetector(
            onTap: () => onFilterChanged('Important'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: selectedButton == 'Important' ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: selectedButton == 'Important'
                      ? Colors.white
                      : Colors.white24,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 18.sp,
                    color: selectedButton == 'Important'
                        ? Colors.black
                        : const Color(0xFFFFD54F),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "Important",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'NunitoBold',
                      fontWeight: FontWeight.bold,
                      color: selectedButton == 'Important'
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: selectedButton == 'Important'
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "$importantCount",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: 'NunitoBold',
                        fontWeight: FontWeight.w800,
                        color: selectedButton == 'Important'
                            ? Colors.black87
                            : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFilterBarDelegate oldDelegate) {
    return oldDelegate.selectedButton != selectedButton ||
        oldDelegate.allCount != allCount ||
        oldDelegate.importantCount != importantCount;
  }
}

// -----------------------------------------------------------------------------
// Original Bottom Sheet & Confirmation Dialog
// -----------------------------------------------------------------------------
void bottomSheet(
  BuildContext context,
  int noteID,
  String title,
  String desc,
  int colorValue,
  bool isImportant,
  Function loadnotes,
  Function toast,
) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
          color: Colors.black,
          border: const Border(top: BorderSide(color: Colors.white)),
        ),
        height: 200.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                Navigator.pop(sheetContext);
                bool? isUpdated = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder:
                        (context, animation, secondaryAnimation) => Add(
                          noteId: noteID,
                          existingTitle: title,
                          existingDesc: desc,
                          existingColor: Color(colorValue),
                        ),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
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
                if (isUpdated == true) {
                  loadnotes();
                }
              },
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
                await DbHelper.dbHelper.toggleImportant(noteID, isImportant);
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, true);
                }
                loadnotes();

                Fluttertoast.showToast(
                  msg: isImportant
                      ? "Removed from Important"
                      : "Marked as Important",
                  textColor: Colors.black,
                  toastLength: Toast.LENGTH_SHORT,
                  backgroundColor: Colors.lime,
                  gravity: ToastGravity.BOTTOM,
                  fontSize: 20.sp,
                );
              },
              child: ListTile(
                leading: Icon(
                  isImportant
                      ? Icons.label_important
                      : Icons.label_important_outline,
                  size: 25.sp,
                  color: Colors.white,
                ),
                title: Text(
                  isImportant
                      ? "Remove from Important"
                      : "Mark as Important",
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
                Navigator.pop(sheetContext);
                bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (dialogContext) => AlertDialog(
                        backgroundColor: const Color(0xff1a1a1a),
                        title: const Text(
                          "Delete Note",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "Are you sure you want to delete this note?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
                if (confirmed == true) {
                  await DbHelper.dbHelper.deleteNote(noteID);
                  toast();
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
