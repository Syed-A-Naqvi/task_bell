import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../alarm/alarm_folder.dart';
import '../alarm/alarm_instance.dart';

class TaskBellDatabase {

  // ensures a singleton intance of the databse
  static final TaskBellDatabase _instance = TaskBellDatabase._internal();
  static Database? _database;
  factory TaskBellDatabase() {
    return _instance;
  }
  TaskBellDatabase._internal();

  // database getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // initialize a new empty database
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'taskBell.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY,
        name TEXT,
        isactive INTEGER, 
        parentId INTEGER,
        recurtype TEXT,
        activedays INTEGER,
        skipweeks INTEGER,
        repeatweeks INTEGER,
        recurtime INTEGER,
        inittime INTEGER,
        datetime INTEGER,
        assetAudioPath TEXT,
        loopAudio INTEGER,
        vibrate INTEGER,
        volume REAL,
        volumeEnforced INTEGER,
        fadeDuration REAL,
        warningNotificationOnKill INTEGER,
        androidFullScreenIntent INTEGER,
        title TEXT,
        body TEXT,
        stopButton TEXT,
        icon TEXT,
        FOREIGN KEY (parentId) REFERENCES folders(id) ON DELETE CASCADE 
      )
    ''');
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY,
        parentId INTEGER,
        name TEXT,
        position INTEGER,
        FOREIGN KEY (parentId) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
  }

  // ------------------------------------- FOLDER CRUD METHODS-------------------------------------

  Future<void> insertFolder(AlarmFolder folder) async {
    final db = await database;
    await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AlarmFolder?> getFolder(int id) async {
    final db = await database;
    final maps = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AlarmFolder.fromMap(maps.first);
    }
    return null;
  }
  
  Future<void> updateFolder(int id, Map<String, dynamic> field) async {
    final db = await database;
    await db.update(
      'folders',
      field,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<AlarmFolder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query('folders');
    return List.generate(maps.length, (i) {
      return AlarmFolder.fromMap(maps[i]);
    });
  }

  Future<List<AlarmFolder>> getAllChildFolders(int parentId) async {
    final db = await database;
    final maps = await db.query(
      'folders',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) {
      return AlarmFolder.fromMap(maps[i]);
    });
  }

  Future<void> deleteAllFolders() async {
    final db = await database;
    await db.delete('folders');
  }

  Future<void> deleteFolder(int id) async {
    final db = await database;
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ------------------------------------- FOLDER CRUD METHODS-------------------------------------


  // ------------------------------------- ALARM CRUD METHODS-------------------------------------

  Future<void> insertAlarm(AlarmInstance alarmInstnace) async {
    final db = await database;
    await db.insert(
      'alarms',
      alarmInstnace.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAlarm(int id, Map<String, dynamic> field) async {
    final db = await database;

    await db.update(
      'alarms',
      field,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> activateAlarm(int id) async {
    final db = await database;

    await db.update(
      'alarms',
      {"isactive": 1},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<Map<String, dynamic>?> getAlarmProperty(int id, String property) async {
    final db = await database;
    final maps = await db.query(
      'alarms',
      columns: [property],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return {property: maps.first[property]};
    }
    return null;
  }

  Future<List<AlarmInstance>> getAllChildAlarms(int parentId) async {
    final db = await database;
    final maps = await db.query(
      'alarms',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) {
      return AlarmInstance.fromMap(maps[i]);
    });
  }

  Future<AlarmInstance?> getAlarm(int id) async {
    final db = await database;
    final maps = await db.query(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AlarmInstance.fromMap(maps.first);
    }
    return null;
  }


  Future<List<AlarmInstance>> getAllAlarms() async {
    final db = await database;
    final maps = await db.query('alarms');
    return List.generate(maps.length, (i) {
      return AlarmInstance.fromMap(maps[i]);
    });
  }

  Future<void> deleteAlarm(int id) async {
    final db = await database;
    await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllAlarms() async {
    final db = await database;
    await db.delete('alarms');
  }
  
  // ------------------------------------- ALARM CRUD METHODS-------------------------------------

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
