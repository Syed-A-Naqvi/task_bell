import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../alarm/helpers/map_converters.dart';
import 'package:alarm/alarm.dart';
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
        parentId TEXT,
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
        icon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        parentId TEXT,
        name TEXT,
        position INTEGER
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

  Future<AlarmFolder?> getFolder(String id) async {
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
  
  Future<List<AlarmFolder>> getAllFolders() async {
    final db = await database;
    final maps = await db.query('folders');
    return List.generate(maps.length, (i) {
      return AlarmFolder.fromMap(maps[i]);
    });
  }

  Future<List<AlarmFolder>> getAllChildFolders(String parentId) async {
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

  Future<void> deleteFolder(String id) async {
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

  Future<List<AlarmInstance>> getAllChildAlarms(String parentId) async {
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

  Future<AlarmInstance?> getAlarm(String id) async {
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


  Future<List<AlarmSettings>> getAllAlarms() async {
    final db = await database;
    final maps = await db.query('alarms');
    return List.generate(maps.length, (i) {
      return MapConverters.alarmSettingsFromMap(maps[i]);
    });
  }

  Future<void> updateAlarm(AlarmSettings alarmSettings) async {
    final db = await database;
    await db.update(
      'alarms',
      MapConverters.alarmSettingsToMap(alarmSettings),
      where: 'id = ?',
      whereArgs: [alarmSettings.id],
    );
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
