import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../controllers/settings_controller.dart';

class ModelStorage {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'models.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE models (
            id TEXT PRIMARY KEY,
            name TEXT,
            priceInput REAL,
            priceOutput REAL,
            context INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE selected_model (
            id TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  static Future<void> saveModels(List<AiModelInfo> models) async {
    final database = await db;
    final batch = database.batch();
    batch.delete('models');
    for (final m in models) {
      batch.insert('models', {
        'id': m.id,
        'name': m.name,
        'priceInput': m.priceInput,
        'priceOutput': m.priceOutput,
        'context': m.context,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<AiModelInfo>> loadModels() async {
    final database = await db;
    final maps = await database.query('models');
    return maps.map((m) => AiModelInfo(
      id: m['id'] as String,
      name: m['name'] as String,
      priceInput: (m['priceInput'] as num).toDouble(),
      priceOutput: (m['priceOutput'] as num).toDouble(),
      context: m['context'] as int,
    )).toList();
  }

  static Future<void> saveSelectedModel(String id) async {
    final database = await db;
    await database.delete('selected_model');
    await database.insert('selected_model', {'id': id});
  }

  static Future<String?> loadSelectedModel() async {
    final database = await db;
    final maps = await database.query('selected_model');
    if (maps.isNotEmpty) {
      return maps.first['id'] as String;
    }
    return null;
  }
} 