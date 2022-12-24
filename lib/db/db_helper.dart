// ignore_for_file: prefer_const_declarations, avoid_print

import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class DBHelper {
  static Database? _db;
  static final int _version = 1;
  static final String _tableName = "tasks";

  static Future<void> initDb() async {
    if (_db != null) {
      return;
    }
    try {
      String _path = await getDatabasesPath() + 'tasks.db';
      _db =
          await openDatabase(_path, version: _version, onCreate: (db, version) {
        print("yeni databe oluşuyor");
        return db.execute(
          "CREATE TABLE $_tableName("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "title STRING, note TEXT,category STRING ,date STRING, "
          "startTime STRING, endTime STRING, "
          "remind INTEGER, repeat STRING, "
          "color INTEGER, "
          "isCompleted INTEGER)",
        );
      });
    } catch (e) {
      print(e);
    }
  }

  static Future<int> insert(Task? task) async {
    print("insert cagrildi");
    return await _db?.insert(_tableName, task!.toJson()) ?? 1;
  }

  static Future<List<Map<String, dynamic>>> query() async {
    print("query cagrildi");
    return await _db!.query(_tableName);
  }

  static delete(Task task) async {
    return await _db!.delete(_tableName, where: 'id=?', whereArgs: [task.id]);
  }

  static update(int id) async {
    return await _db!.rawUpdate('''
      UPDATE tasks
      SET isCompleted = ?
      WHERE id=?
    ''', [1, id]);
  }

  static updateBack(int id) async {
    return await _db!.rawUpdate('''
      UPDATE tasks
      SET isCompleted = ?
      WHERE id=?
    ''', [0, id]);
  }

  static getCategoryFromDB() async {
    List<Map> kategoriler = await _db!.rawQuery("SELECT category FROM tasks");
    List<String> allCategory = [];
    for (var element in kategoriler) {
        String kat = element.toString();
        var ka = kat.split(': ');
        String katego = ka[1].toString();
        String lastKAT = katego.substring(0, katego.length - 1);
        allCategory.add(lastKAT);
      }
    return allCategory;
  }
}
