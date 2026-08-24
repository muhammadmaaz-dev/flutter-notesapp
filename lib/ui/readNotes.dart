import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:newapp/services/notification_service.dart';
import 'package:newapp/ui/add.dart';
import 'package:newapp/ui/notes.dart';

class readnotes extends StatefulWidget {
  final int? noteId;
  final String title;
  final String desc;
  final Color color;
  final bool isImportant;
  final DateTime? reminderAt;
  final DateTime? createdAt;

  const readnotes({
    super.key,
    this.noteId,
    required this.title,
    required this.desc,
    required this.color,
    this.isImportant = false,
    this.reminderAt,
    this.createdAt,
  });

  @override
  State<readnotes> createState() => _readnotesState();
}

class _readnotesState extends State<readnotes> {
  late String _currentTitle;
  late String _currentDesc;
  late Color _currentColor;
  late bool _isImportant;
  DateTime? _currentReminderAt;
  DateTime? _currentCreatedAt;
  bool _hasChanges = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _currentDesc = widget.desc;
    _currentColor = widget.color;
    _isImportant = widget.isImportant;
    _currentReminderAt = widget.reminderAt;
    _currentCreatedAt = widget.createdAt;
  }

  void _handleBack() {
    if (_isPopping) return;
    _isPopping = true;
    if (mounted) {
      Navigator.of(context).pop(_hasChanges);
    }
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
              border: const Border(top: BorderSide(color: Colors.white24, width: 0.5)),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

                // 1. Edit Note Tile
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Edit Note",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontFamily: 'NunitoBold',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 280),
                        pageBuilder: (context, animation, secondaryAnimation) => Add(
                          noteId: widget.noteId,
                          existingTitle: _currentTitle,
                          existingDesc: _currentDesc,
                          existingColor: _currentColor,
                          existingReminderAt: _currentReminderAt,
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

                    _hasChanges = true;
                    if (widget.noteId != null) {
                      var all = await DbHelper.dbHelper.getallnotes();
                      var match = all.firstWhere(
                        (n) => n[DbHelper.COL_NOTE_SNO] == widget.noteId,
                        orElse: () => {},
                      );
                      if (match.isNotEmpty && mounted) {
                        setState(() {
                          _currentTitle = match[DbHelper.COL_NOTE_TITLE] ?? _currentTitle;
                          _currentDesc = match[DbHelper.COL_NOTE_DESC] ?? _currentDesc;
                          _currentColor = Color(match[DbHelper.COL_NOTE_COLOR] ?? _currentColor.toARGB32());
                          _isImportant = (match[DbHelper.COL_NOTE_IMPORTANT] ?? 0) == 1;
                          int? remMs = match[DbHelper.COL_NOTE_REMINDER_AT] as int?;
                          _currentReminderAt = remMs != null
                              ? DateTime.fromMillisecondsSinceEpoch(remMs)
                              : null;
                          int? crtMs = match[DbHelper.COL_NOTE_CREATED_AT] as int?;
                          _currentCreatedAt = crtMs != null
                              ? DateTime.fromMillisecondsSinceEpoch(crtMs)
                              : _currentCreatedAt;
                        });
                      }
                    }
                  },
                ),

                // 2. Mark / Remove Important Tile
                ListTile(
                  leading: Icon(
                    _isImportant
                        ? Icons.label_important
                        : Icons.label_important_outline,
                    size: 24.sp,
                    color: _isImportant ? const Color(0xFFFFD54F) : Colors.white,
                  ),
                  title: Text(
                    _isImportant ? "Remove from Important" : "Mark as Important",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontFamily: 'NunitoBold',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (widget.noteId == null) return;

                    await DbHelper.dbHelper.toggleImportant(widget.noteId!, _isImportant);
                    _hasChanges = true;
                    if (mounted) {
                      setState(() {
                        _isImportant = !_isImportant;
                      });
                    }

                    Fluttertoast.showToast(
                      msg: _isImportant
                          ? "Marked as Important"
                          : "Removed from Important",
                      textColor: Colors.black,
                      toastLength: Toast.LENGTH_SHORT,
                      backgroundColor: Colors.lime,
                      gravity: ToastGravity.BOTTOM,
                      fontSize: 20.sp,
                    );
                  },
                ),

                // 3. Remind Me / Remove Reminder Tile
                ListTile(
                  leading: Icon(
                    _currentReminderAt != null
                        ? Icons.alarm_on_rounded
                        : Icons.alarm_rounded,
                    size: 24.sp,
                    color: _currentReminderAt != null
                        ? const Color(0xFFFFD54F)
                        : Colors.white,
                  ),
                  title: Text(
                    _currentReminderAt != null ? "Remove Reminder" : "Remind Me",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontFamily: 'NunitoBold',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (widget.noteId == null) return;

                    if (_currentReminderAt != null) {
                      // Remove reminder
                      await DbHelper.dbHelper.updateReminder(widget.noteId!, null);
                      _hasChanges = true;
                      if (mounted) {
                        setState(() {
                          _currentReminderAt = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Reminder removed"),
                            backgroundColor: Color(0xff1a1a1a),
                          ),
                        );
                      }
                    } else {
                      // Pick and schedule reminder
                      final pickedDate = await pickReminderDateTime(context);
                      if (pickedDate != null) {
                        await DbHelper.dbHelper.updateReminder(widget.noteId!, pickedDate);
                        try {
                          await NotificationService.instance.scheduleNoteReminder(
                            id: widget.noteId!,
                            title: _currentTitle,
                            content: _currentDesc,
                            scheduledDate: pickedDate,
                          );
                        } catch (_) {}
                        _hasChanges = true;
                        if (mounted) {
                          setState(() {
                            _currentReminderAt = pickedDate;
                          });
                          final formatted =
                              DateFormat('MMM d, h:mm a').format(pickedDate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Reminder set for $formatted"),
                              backgroundColor: const Color(0xff1a1a1a),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),

                // 4. Delete Note Tile
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    size: 24.sp,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    "Delete Note",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.redAccent,
                      fontFamily: 'NunitoBold',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (widget.noteId == null) return;

                    bool? confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
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
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && widget.noteId != null) {
                      await DbHelper.dbHelper.deleteNote(widget.noteId!);
                      Fluttertoast.showToast(
                        msg: "Deleted Successfully",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        fontSize: 20.sp,
                        textColor: Colors.black,
                        backgroundColor: Colors.red,
                      );
                      _isPopping = true;
                      if (mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                ),

                // 5. Creation Date & Time Indicator
                Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.white38),
                      SizedBox(width: 6.w),
                      Text(
                        formatCreatedAt(_currentCreatedAt?.millisecondsSinceEpoch),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white38,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isPopping,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: _currentColor,
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
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 35.sp,
                      color: Colors.black,
                    ),
                    IconButton(
                      onPressed: _showMenuBottomSheet,
                      icon: const Icon(Icons.more_vert_rounded),
                      iconSize: 35.sp,
                      color: Colors.black,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  _currentTitle,
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'NunitoBold',
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  _currentDesc,
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
      ),
    );
  }
}
