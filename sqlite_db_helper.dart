import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

import 'movie_details.dart';

class DbHelper {
  static final DbHelper _dbHelper = DbHelper.init();

  factory DbHelper() => _dbHelper;

  DbHelper.init();

  static Database? _database;

  Future<Database?> createDatabase() async {
    if (_database != null) {
      return _database;
    }

    String path = join(await getDatabasesPath(), 'watch_list.db');
    _database =
        await openDatabase(path, version: 1, onCreate: (Database db, int ver) {
      db.execute("CREATE TABLE movies(imdbID varchar(50) PRIMARY KEY,"
          "Title varchar(50), Year varchar(4), Genre varchar(100), Director varchar(100),"
          "Actors varchar(255), Plot varchar(255), Rated varchar(20), Poster varchar(255))");
    });

    return _database;
  }

  Future<bool> insertMovie(Map<String, dynamic> movieImdb) async {
    Database? db = await createDatabase();
    if (db != null) {
      int result = await db.insert("movies", movieImdb);
      return result > 0;
    }
    return false;
  }
  Future<List?> allIMDB() async {
    Database? db = await createDatabase();
    return db!.query('movies');
  }
}
