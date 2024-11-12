import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../alarm/helpers/map_converters.dart'; // Import your MapConverters class
import 'package:alarm/alarm.dart'; // Adjust import based on your file structure

class AlarmDatabase {
  static final AlarmDatabase _instance = AlarmDatabase._internal();
  static Database? _database;

  factory AlarmDatabase() {
    return _instance;
  }

  AlarmDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'alarms.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        datetime INTEGER,
        assetAudioPath TEXT,
        loopAudio INTEGER,
        vibrate INTEGER,
        volume REAL,
        volumeEnforced INTEGER,
        fadeDuration INTEGER,
        warningNotificationOnKill INTEGER,
        androidFullScreenIntent INTEGER,
        title TEXT,
        body TEXT,
        stopButton TEXT,
        icon TEXT
      )
    ''');
  }

  Future<void> insertAlarm(AlarmSettings alarmSettings) async {
    final db = await database;
    await db.insert(
      'alarms',
      MapConverters.alarmSettingsToMap(alarmSettings),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AlarmSettings?> getAlarm(String id) async {
    final db = await database;
    final maps = await db.query(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MapConverters.alarmSettingsFromMap(maps.first);
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

  Future<void> deleteAlarm(String id) async {
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

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
