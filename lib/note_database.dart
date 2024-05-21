import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'note.dart';

class NoteDatabase {
  static final NoteDatabase instance = NoteDatabase._init();

  static Database? _database;

  NoteDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
CREATE TABLE notes ( 
  ${NoteFields.id} $idType, 
  ${NoteFields.title} $textType,
  ${NoteFields.description} $textType,
  ${NoteFields.imagePath} $textType,
  ${NoteFields.isImportant} $boolType
  )
''');
  }

  Future<Note> create(Note note) async {
    final db = await instance.database;

    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  Future<Note> read(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'notes',
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAll() async {
    final db = await instance.database;

    const orderBy = '${NoteFields.isImportant} DESC, ${NoteFields.id} ASC';
    final result = await db.query('notes', orderBy: orderBy);

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;

    return db.update(
      'notes',
      note.toMap(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      'notes',
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}