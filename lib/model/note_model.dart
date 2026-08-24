import 'package:flutter/material.dart';
import 'package:newapp/local/db_helper.dart';

class Note {
  final int? id;
  final String title;
  final String desc;
  final int color;
  final bool isImportant;
  final DateTime? reminderAt;
  final DateTime? createdAt;

  const Note({
    this.id,
    required this.title,
    required this.desc,
    required this.color,
    this.isImportant = false,
    this.reminderAt,
    this.createdAt,
  });

  Note copyWith({
    int? id,
    String? title,
    String? desc,
    int? color,
    bool? isImportant,
    DateTime? reminderAt,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      color: color ?? this.color,
      isImportant: isImportant ?? this.isImportant,
      reminderAt: reminderAt ?? this.reminderAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) DbHelper.COL_NOTE_SNO: id,
      DbHelper.COL_NOTE_TITLE: title,
      DbHelper.COL_NOTE_DESC: desc,
      DbHelper.COL_NOTE_COLOR: color,
      DbHelper.COL_NOTE_IMPORTANT: isImportant ? 1 : 0,
      DbHelper.COL_NOTE_REMINDER_AT: reminderAt?.millisecondsSinceEpoch,
      DbHelper.COL_NOTE_CREATED_AT: createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map[DbHelper.COL_NOTE_SNO] as int?,
      title: (map[DbHelper.COL_NOTE_TITLE] as String?) ?? '',
      desc: (map[DbHelper.COL_NOTE_DESC] as String?) ?? '',
      color: (map[DbHelper.COL_NOTE_COLOR] as int?) ?? Colors.white.toARGB32(),
      isImportant: (map[DbHelper.COL_NOTE_IMPORTANT] as int? ?? 0) == 1,
      reminderAt: map[DbHelper.COL_NOTE_REMINDER_AT] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbHelper.COL_NOTE_REMINDER_AT] as int,
            )
          : null,
      createdAt: map[DbHelper.COL_NOTE_CREATED_AT] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DbHelper.COL_NOTE_CREATED_AT] as int,
            )
          : null,
    );
  }
}
