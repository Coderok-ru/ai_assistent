import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PromptRole {
  final int? id;
  final String name;
  final String prompt;
  final String? role;
  final bool isActive;
  final bool isSystem;

  PromptRole({this.id, required this.name, required this.prompt, this.role, this.isActive = false, this.isSystem = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'prompt': prompt,
        'role': role,
        'isActive': isActive ? 1 : 0,
        'isSystem': isSystem ? 1 : 0,
      };

  factory PromptRole.fromMap(Map<String, dynamic> map) => PromptRole(
        id: map['id'] as int?,
        name: map['name'] as String,
        prompt: map['prompt'] as String,
        role: map['role'] as String?,
        isActive: (map['isActive'] ?? 0) == 1,
        isSystem: (map['isSystem'] ?? 0) == 1,
      );
}

class PromptStorage {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prompts.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE prompts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            prompt TEXT,
            role TEXT,
            isActive INTEGER,
            isSystem INTEGER
          )
        ''');
        await _insertDefaultPrompts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE prompts ADD COLUMN isSystem INTEGER DEFAULT 0');
        }
      },
    );
  }

  static Future<void> _insertDefaultPrompts(Database db) async {
    final defaults = [
      {
        'name': 'Стандартный ассистент',
        'prompt': 'Ты — дружелюбный и полезный AI ассистент. Отвечай понятно и по делу.',
        'role': 'system',
        'isActive': 1,
        'isSystem': 1,
      },
      {
        'name': 'Креативный писатель',
        'prompt': 'Ты — креативный AI, помогаешь писать тексты, истории, слоганы.',
        'role': 'system',
        'isActive': 0,
        'isSystem': 1,
      },
      {
        'name': 'Программист',
        'prompt': 'Ты — опытный AI-программист. Помогай с кодом, объясняй решения, пиши примеры.',
        'role': 'system',
        'isActive': 0,
        'isSystem': 1,
      },
      {
        'name': 'Переводчик',
        'prompt': 'Ты — AI-переводчик. Переводи тексты максимально точно и естественно.',
        'role': 'system',
        'isActive': 0,
        'isSystem': 1,
      },
    ];
    for (final p in defaults) {
      await db.insert('prompts', p);
    }
  }

  static Future<void> ensureDefaultSystemPrompts() async {
    final database = await db;
    final maps = await database.query('prompts', where: 'isSystem = 1');
    if (maps.isEmpty) {
      await _insertDefaultPrompts(database);
    }
  }

  static Future<List<PromptRole>> loadPrompts() async {
    await ensureDefaultSystemPrompts();
    final database = await db;
    final maps = await database.query('prompts');
    return maps.map((m) => PromptRole.fromMap(m)).toList();
  }

  static Future<void> savePrompt(PromptRole prompt) async {
    final database = await db;
    if (prompt.id == null) {
      await database.insert('prompts', prompt.toMap());
    } else {
      await database.update('prompts', prompt.toMap(), where: 'id = ?', whereArgs: [prompt.id]);
    }
  }

  static Future<void> deletePrompt(int id) async {
    final database = await db;
    await database.delete('prompts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> setActivePrompt(int id) async {
    final database = await db;
    await database.update('prompts', {'isActive': 0});
    await database.update('prompts', {'isActive': 1}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<PromptRole?> getActivePrompt() async {
    final database = await db;
    final maps = await database.query('prompts', where: 'isActive = 1');
    if (maps.isNotEmpty) {
      return PromptRole.fromMap(maps.first);
    }
    return null;
  }
} 