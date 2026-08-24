import 'dart:io';
import 'package:flutter/material.dart';
import 'package:newapp/services/notification_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper dbHelper = DbHelper._();

  static const String TABLE_NOTE = "note";
  static const String COL_NOTE_SNO = "s_no";
  static const String COL_NOTE_TITLE = "title";
  static const String COL_NOTE_DESC = "desc";
  static const String COL_NOTE_COLOR = "color";
  static const String COL_NOTE_IMPORTANT = "important";
  static const String COL_NOTE_REMINDER_AT = "reminder_at";
  static const String COL_NOTE_CREATED_AT = "created_at";

  Database? myDB;

  Future<Database> getDB() async {
    myDB ??= await openDB();
    return myDB!;
  }

  Future<Database> openDB() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String dbPath = join(dir.path, "myDB.db");

    return await openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE $TABLE_NOTE($COL_NOTE_SNO INTEGER PRIMARY KEY AUTOINCREMENT, $COL_NOTE_TITLE TEXT, $COL_NOTE_DESC TEXT, $COL_NOTE_COLOR INTEGER, $COL_NOTE_IMPORTANT INTEGER DEFAULT 0, $COL_NOTE_REMINDER_AT INTEGER, $COL_NOTE_CREATED_AT INTEGER)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          try {
            db.execute("ALTER TABLE $TABLE_NOTE ADD COLUMN $COL_NOTE_IMPORTANT INTEGER DEFAULT 0;");
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            db.execute("ALTER TABLE $TABLE_NOTE ADD COLUMN $COL_NOTE_REMINDER_AT INTEGER;");
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            db.execute("ALTER TABLE $TABLE_NOTE ADD COLUMN $COL_NOTE_CREATED_AT INTEGER;");
          } catch (_) {}
        }
      },
      onOpen: (db) async {
        try {
          await db.execute("ALTER TABLE $TABLE_NOTE ADD COLUMN $COL_NOTE_REMINDER_AT INTEGER;");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE $TABLE_NOTE ADD COLUMN $COL_NOTE_CREATED_AT INTEGER;");
        } catch (_) {}
      },
    );
  }

  Future<int> deleteNote(int id) async {
    var db = await getDB();
    await NotificationService.instance.cancelReminder(id);
    return await db.delete(
      TABLE_NOTE,
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }

  Future<int> impotantNote(int id) async {
    var db = await getDB();
    return await db.update(
      TABLE_NOTE,
      {COL_NOTE_IMPORTANT: 1},
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }

  Future<int> unmarkImportant(int id) async {
    var db = await getDB();
    return await db.update(
      TABLE_NOTE,
      {COL_NOTE_IMPORTANT: 0},
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }

  Future<int> toggleImportant(int id, bool currentStatus) async {
    var db = await getDB();
    return await db.update(
      TABLE_NOTE,
      {COL_NOTE_IMPORTANT: currentStatus ? 0 : 1},
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }

  Future<int> updateReminder(int noteId, DateTime? reminderAt) async {
    var db = await getDB();
    if (reminderAt == null) {
      await NotificationService.instance.cancelReminder(noteId);
    }
    return await db.update(
      TABLE_NOTE,
      {
        COL_NOTE_REMINDER_AT: reminderAt?.millisecondsSinceEpoch,
      },
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [noteId],
    );
  }

  Future<bool> addnote({
    required String mTilte,
    required String mDesc,
    required Color mColor,
    DateTime? reminderAt,
    DateTime? createdAt,
  }) async {
    var db = await getDB();
    int rowseffected = await db.insert(TABLE_NOTE, {
      COL_NOTE_TITLE: mTilte,
      COL_NOTE_DESC: mDesc,
      COL_NOTE_COLOR: mColor.toARGB32(),
      COL_NOTE_IMPORTANT: 0,
      COL_NOTE_REMINDER_AT: reminderAt?.millisecondsSinceEpoch,
      COL_NOTE_CREATED_AT: (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    });
    return rowseffected > 0;
  }

  Future<int> addNoteReturnId({
    required String mTitle,
    required String mDesc,
    required Color mColor,
    DateTime? reminderAt,
    DateTime? createdAt,
  }) async {
    var db = await getDB();
    return await db.insert(TABLE_NOTE, {
      COL_NOTE_TITLE: mTitle,
      COL_NOTE_DESC: mDesc,
      COL_NOTE_COLOR: mColor.toARGB32(),
      COL_NOTE_IMPORTANT: 0,
      COL_NOTE_REMINDER_AT: reminderAt?.millisecondsSinceEpoch,
      COL_NOTE_CREATED_AT: (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getallnotes() async {
    var db = await getDB();
    return await db.query(
      TABLE_NOTE,
      orderBy: "$COL_NOTE_SNO DESC",
    );
  }

  Future<int> updateNote({
    required int id,
    required String newTitle,
    required String newDesc,
    required Color newColor,
    DateTime? reminderAt,
  }) async {
    var db = await getDB();
    Map<String, dynamic> values = {
      COL_NOTE_TITLE: newTitle,
      COL_NOTE_DESC: newDesc,
      COL_NOTE_COLOR: newColor.toARGB32(),
    };
    if (reminderAt != null) {
      values[COL_NOTE_REMINDER_AT] = reminderAt.millisecondsSinceEpoch;
    }
    return await db.update(
      TABLE_NOTE,
      values,
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }
}
