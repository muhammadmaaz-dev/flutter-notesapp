import 'dart:async';
import 'package:flutter/material.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Add extends StatefulWidget {
  final int? noteId;
  final String? existingTitle;
  final String? existingDesc;
  final Color? existingColor;

  const Add({
    super.key,
    this.noteId,
    this.existingTitle,
    this.existingDesc,
    this.existingColor,
  });

  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> with WidgetsBindingObserver {
  late final TextEditingController titleController;
  late final TextEditingController descController;
  Color selectedcolor = Colors.white;

  int? _currentNoteId;
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  bool get isEditing => _currentNoteId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentNoteId = widget.noteId;
    titleController = TextEditingController(text: widget.existingTitle ?? '');
    descController = TextEditingController(text: widget.existingDesc ?? '');
    selectedcolor = widget.existingColor ?? Colors.white;

    titleController.addListener(_onContentChanged);
    descController.addListener(_onContentChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _flushAutoSave();
    }
  }

  void _onContentChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final title = titleController.text.trim();
    final desc = descController.text.trim();

    if (title.isEmpty && desc.isEmpty) return;
    if (_isSaving) return;
    _isSaving = true;

    try {
      if (_currentNoteId != null) {
        await DbHelper.dbHelper.updateNote(
          id: _currentNoteId!,
          newTitle: titleController.text,
          newDesc: descController.text,
          newColor: selectedcolor,
        );
      } else {
        int newId = await DbHelper.dbHelper.addNoteReturnId(
          mTitle: titleController.text,
          mDesc: descController.text,
          mColor: selectedcolor,
        );
        if (newId > 0) {
          _currentNoteId = newId;
        }
      }
    } catch (e) {
      debugPrint("AutoSave error: $e");
    } finally {
      _isSaving = false;
    }
  }

  void _flushAutoSave() {
    _autoSaveTimer?.cancel();
    _performAutoSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushAutoSave();
    _autoSaveTimer?.cancel();
    titleController.removeListener(_onContentChanged);
    descController.removeListener(_onContentChanged);
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
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

    void callBottomSheet() {
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
                    _onContentChanged();
                    Navigator.pop(context);
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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _flushAutoSave();
      },
      child: Scaffold(
        backgroundColor: selectedcolor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _flushAutoSave();
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 35.sp,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
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
                TextField(
                  controller: descController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
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
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
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
                    callBottomSheet();
                  },
                  child: _BottomButton(
                    icon: Icons.color_lens_rounded,
                    color: selectedcolor,
                  ),
                ),
                GestureDetector(
                  child: _BottomButton(icon: Icons.save, color: selectedcolor),
                  onTap: () async {
                    _autoSaveTimer?.cancel();
                    if (isEditing) {
                      await DbHelper.dbHelper.updateNote(
                        id: _currentNoteId!,
                        newTitle: titleController.text,
                        newDesc: descController.text,
                        newColor: selectedcolor,
                      );
                    } else {
                      await DbHelper.dbHelper.addnote(
                        mTilte: titleController.text,
                        mDesc: descController.text,
                        mColor: selectedcolor,
                      );
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                    Fluttertoast.showToast(
                      msg: isEditing ? "Updated Successfully" : "Added Successfully",
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
