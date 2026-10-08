import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/secure_key_store.dart';

class MoodEntry {
  const MoodEntry({
    this.id,
    required this.createdAt,
    required this.mood,
    this.energy,
    this.sleepHours,
    this.note,
    this.emotions = const [],
    this.contexts = const [],
  });

  final int? id;
  final DateTime createdAt;

  /// 1 (lowest) to 5.
  final int mood;
  final int? energy;
  final double? sleepHours;
  final String? note;
  final List<String> emotions;
  final List<String> contexts;
}

class ThoughtRecord {
  const ThoughtRecord({
    this.id,
    required this.createdAt,
    this.situation,
    this.automaticThought,
    this.feeling,
    this.intensityBefore,
    this.trap,
    this.evidenceFor,
    this.evidenceAgainst,
    this.balancedThought,
    this.intensityAfter,
  });

  final int? id;
  final DateTime createdAt;
  final String? situation;
  final String? automaticThought;
  final String? feeling;
  final int? intensityBefore;
  final String? trap;
  final String? evidenceFor;
  final String? evidenceAgainst;
  final String? balancedThought;
  final int? intensityAfter;
}

/// SQLCipher-encrypted database. The key lives in the Keychain / Keystore.
class AppDatabase {
  AppDatabase._(this._keys, this._db);

  final SecureKeyStore _keys;
  Database _db;

  static const _fileName = 'mindmap.db';

  static Future<AppDatabase> open(SecureKeyStore keys) async {
    try {
      return AppDatabase._(keys, await _open(keys));
    } on DatabaseException {
      // The key no longer matches the file (e.g. the Keystore was reset), so
      // the old data can't be read by anyone. Start clean rather than crash.
      await deleteDatabase(p.join(await getDatabasesPath(), _fileName));
      return AppDatabase._(keys, await _open(keys));
    }
  }

  static Future<Database> _open(SecureKeyStore keys) async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      password: await keys.databaseKey(),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE mood_entry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            mood INTEGER NOT NULL,
            energy INTEGER,
            sleep_hours REAL,
            note TEXT
          )''');
        await db.execute('''
          CREATE TABLE mood_tag (
            entry_id INTEGER REFERENCES mood_entry(id) ON DELETE CASCADE,
            kind TEXT NOT NULL,
            tag TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE thought_record (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            situation TEXT, automatic_thought TEXT,
            feeling TEXT, intensity_before INTEGER,
            trap TEXT, evidence_for TEXT, evidence_against TEXT,
            balanced_thought TEXT, intensity_after INTEGER
          )''');
        await db.execute('''
          CREATE TABLE safety_plan (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            warning_signs TEXT, coping TEXT, distractions TEXT,
            trusted_people TEXT, safer_environment TEXT
          )''');
        await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }

  // Settings

  Future<Map<String, String>> settings() async {
    final rows = await _db.query('settings');
    return {
      for (final r in rows)
        if (r['value'] != null) r['key'] as String: r['value'] as String,
    };
  }

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await _db.delete('settings', where: 'key = ?', whereArgs: [key]);
    } else {
      await _db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Mood

  Future<void> addMoodEntry(MoodEntry e) async {
    await _db.transaction((txn) async {
      final id = await txn.insert('mood_entry', {
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'mood': e.mood,
        'energy': e.energy,
        'sleep_hours': e.sleepHours,
        'note': e.note,
      });
      for (final t in e.emotions) {
        await txn.insert(
            'mood_tag', {'entry_id': id, 'kind': 'emotion', 'tag': t});
      }
      for (final t in e.contexts) {
        await txn.insert(
            'mood_tag', {'entry_id': id, 'kind': 'context', 'tag': t});
      }
    });
  }

  Future<List<MoodEntry>> moodEntries() async {
    final rows = await _db.query('mood_entry', orderBy: 'created_at DESC');
    final tags = await _db.query('mood_tag');
    List<String> tagsFor(Object? id, String kind) => [
          for (final t in tags)
            if (t['entry_id'] == id && t['kind'] == kind) t['tag'] as String,
        ];
    return [
      for (final r in rows)
        MoodEntry(
          id: r['id'] as int,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          mood: r['mood'] as int,
          energy: r['energy'] as int?,
          sleepHours: (r['sleep_hours'] as num?)?.toDouble(),
          note: r['note'] as String?,
          emotions: tagsFor(r['id'], 'emotion'),
          contexts: tagsFor(r['id'], 'context'),
        ),
    ];
  }

  Future<void> deleteMoodEntry(int id) =>
      _db.delete('mood_entry', where: 'id = ?', whereArgs: [id]);

  // Thought records

  Future<void> addThoughtRecord(ThoughtRecord t) => _db.insert(
        'thought_record',
        {
          'created_at': t.createdAt.millisecondsSinceEpoch,
          'situation': t.situation,
          'automatic_thought': t.automaticThought,
          'feeling': t.feeling,
          'intensity_before': t.intensityBefore,
          'trap': t.trap,
          'evidence_for': t.evidenceFor,
          'evidence_against': t.evidenceAgainst,
          'balanced_thought': t.balancedThought,
          'intensity_after': t.intensityAfter,
        },
      );

  Future<List<ThoughtRecord>> thoughtRecords() async {
    final rows = await _db.query('thought_record', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        ThoughtRecord(
          id: r['id'] as int,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          situation: r['situation'] as String?,
          automaticThought: r['automatic_thought'] as String?,
          feeling: r['feeling'] as String?,
          intensityBefore: r['intensity_before'] as int?,
          trap: r['trap'] as String?,
          evidenceFor: r['evidence_for'] as String?,
          evidenceAgainst: r['evidence_against'] as String?,
          balancedThought: r['balanced_thought'] as String?,
          intensityAfter: r['intensity_after'] as int?,
        ),
    ];
  }

  Future<void> deleteThoughtRecord(int id) =>
      _db.delete('thought_record', where: 'id = ?', whereArgs: [id]);

  /// Deletes the database file and every secret, then starts a fresh, empty
  /// database with a new key.
  Future<void> eraseEverything() async {
    final path = _db.path;
    await _db.close();
    await deleteDatabase(path);
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('$path$suffix');
      if (await f.exists()) await f.delete();
    }
    await _keys.eraseAll();
    _db = await _open(_keys);
  }
}
