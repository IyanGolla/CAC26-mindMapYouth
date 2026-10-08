import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secrets kept in the OS Keychain / Keystore: the database key and the
/// salted PIN hash.
class SecureKeyStore {
  SecureKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.unlocked_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _dbKey = 'db_key';
  static const _pinSalt = 'pin_salt';
  static const _pinHash = 'pin_hash';
  static const _pinFails = 'pin_fails';
  static const _pinLockedUntil = 'pin_locked_until';

  /// Returns the database key, creating it on first run.
  Future<String> databaseKey() async {
    final existing = await _storage.read(key: _dbKey);
    if (existing != null) return existing;
    final r = Random.secure();
    final key = base64UrlEncode(List<int>.generate(32, (_) => r.nextInt(256)));
    await _storage.write(key: _dbKey, value: key);
    return key;
  }

  Future<({String salt, String hash})?> pin() async {
    final salt = await _storage.read(key: _pinSalt);
    final hash = await _storage.read(key: _pinHash);
    if (salt == null || hash == null) return null;
    return (salt: salt, hash: hash);
  }

  Future<void> savePin(String salt, String hash) async {
    await _storage.write(key: _pinSalt, value: salt);
    await _storage.write(key: _pinHash, value: hash);
    await saveFailures(0, null);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinSalt);
    await _storage.delete(key: _pinHash);
    await saveFailures(0, null);
  }

  Future<({int fails, DateTime? lockedUntil})> failures() async {
    final fails = int.tryParse(await _storage.read(key: _pinFails) ?? '') ?? 0;
    final until = int.tryParse(await _storage.read(key: _pinLockedUntil) ?? '');
    return (
      fails: fails,
      lockedUntil:
          until == null ? null : DateTime.fromMillisecondsSinceEpoch(until),
    );
  }

  Future<void> saveFailures(int fails, DateTime? lockedUntil) async {
    await _storage.write(key: _pinFails, value: '$fails');
    if (lockedUntil == null) {
      await _storage.delete(key: _pinLockedUntil);
    } else {
      await _storage.write(
        key: _pinLockedUntil,
        value: '${lockedUntil.millisecondsSinceEpoch}',
      );
    }
  }

  Future<void> eraseAll() => _storage.deleteAll();
}
