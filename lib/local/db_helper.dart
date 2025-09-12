import 'dart:io'; // File system ke liye (path handle karne ke liye)
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // SQLite database use karne ke liye

import 'package:path/path.dart'; // join() function ke liye (path merge karne ke liye)
import 'package:path_provider/path_provider.dart'; // device ke storage directory path lene ke liye

// Database helper class
class DbHelper {
  // Private constructor (singleton banane ke liye)
  DbHelper._();

  // Singleton object (sirf ek instance hoga throughout app)
  static final DbHelper dbHelper = DbHelper._();

  // Table aur column ke names define kar diye
  static final String TABLE_NOTE = "note"; // table ka naam
  static final String COL_NOTE_SNO = "s_no"; // primary key column
  static final String COL_NOTE_TITLE = "title"; // title column
  static final String COL_NOTE_DESC = "desc"; // description column
  static final String COL_NOTE_COLOR = "color";
  static const String COL_NOTE_IMPORTANT = "important";

  // Database object (pehle null hoga, baad me initialize hoga)
  Database? myDB;

  // Database lazily load karne ka function
  Future<Database> getDB() async {
    // Agar database null hai to open karo, warna jo pehle se open hai use karo
    myDB ??= await openDB();
    return myDB!;

    // Alternative tarika (upar wala short hai)
    // if (myDB != null) {
    //   return myDB!;
    // } else {
    //   myDB = await openDB();
    //   return myDB!;
    // }
  }

  // Database create/open karne ka function
  Future<Database> openDB() async {
    // App ka documents directory (storage path) lena
    Directory dir = await getApplicationDocumentsDirectory();

    // Database file ka path create karna (myDB.db file save hogi is jagah par)
    String dbPath = join(dir.path, "myDB.db");

    // Database open karo (agar exist nahi hai to create hoga)
    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) {
        // Jab pehli dafa database create hoga to yeh table banega
        db.execute(
          "CREATE TABLE $TABLE_NOTE($COL_NOTE_SNO INTEGER PRIMARY KEY AUTOINCREMENT, $COL_NOTE_TITLE TEXT, $COL_NOTE_DESC TEXT, $COL_NOTE_COLOR INTEGER, $COL_NOTE_IMPORTANT INTEGER DEFAULT 0)",
        );
      },
    );
  }

  Future<int> deleteNote(int id) async {
    var db = await getDB();
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

  // Naya note insert karne ka function
  Future<bool> addnote({
    required String mTilte,
    required String mDesc,
    required Color mColor,
  }) async {
    // Database open karo
    var db = await getDB();

    // Insert query run karo aur number of rows affected return hoga
    int rowseffected = await db.insert(TABLE_NOTE, {
      COL_NOTE_TITLE: mTilte,
      COL_NOTE_DESC: mDesc,
      COL_NOTE_COLOR: mColor.toARGB32(),
    });

    // Agar kam se kam 1 row insert hui hai to true return hoga
    return rowseffected > 0;
  }

  // Sare notes fetch karne ka function
  Future<List<Map<String, dynamic>>> getallnotes() async {
    // Database open karo
    var db = await getDB();

    // Query run karo (select * from note)
    List<Map<String, dynamic>> mData = await db.query(TABLE_NOTE);

    // Sare notes return kar do list ke form me
    return mData;
  }

  Future<int> updateNote({
    required int id,
    required String newTitle,
    required String newDesc,
    required Color newColor,
  }) async {
    var db = await getDB();
    return await db.update(
      TABLE_NOTE,
      {
        COL_NOTE_TITLE: newTitle,
        COL_NOTE_DESC: newDesc,
        COL_NOTE_COLOR: newColor.value,
      },
      where: "$COL_NOTE_SNO = ?",
      whereArgs: [id],
    );
  }
}
