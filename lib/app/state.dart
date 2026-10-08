import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pin_hasher.dart';
import '../core/secure_key_store.dart';
import '../data/app_database.dart';
import '../domain/resource.dart';

/// Everything loaded before the first frame. Overridden in main().
class AppServices {
  const AppServices({
    required this.keys,
    required this.db,
    required this.resources,
    required this.initialSettings,
    required this.hasPin,
  });

  final SecureKeyStore keys;
  final AppDatabase db;
  final List<Resource> resources;
  final Map<String, String> initialSettings;
  final bool hasPin;
}

final servicesProvider =
    Provider<AppServices>((_) => throw UnimplementedError('set in main()'));

// Settings

class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.county,
    this.tripleTapExit = false,
  });

  final bool onboarded;
  final String? county;
  final bool tripleTapExit;

  factory AppSettings.fromMap(Map<String, String> m) => AppSettings(
        onboarded: m['onboarded'] == '1',
        county: m['county'],
        tripleTapExit: m['triple_tap_exit'] == '1',
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      AppSettings.fromMap(ref.watch(servicesProvider).initialSettings);

  AppDatabase get _db => ref.read(servicesProvider).db;

  Future<void> _reload() async =>
      state = AppSettings.fromMap(await _db.settings());

  Future<void> setOnboarded() async {
    await _db.setSetting('onboarded', '1');
    await _reload();
  }

  Future<void> setCounty(String? county) async {
    await _db.setSetting('county', county);
    await _reload();
  }

  Future<void> setTripleTapExit(bool on) async {
    await _db.setSetting('triple_tap_exit', on ? '1' : '0');
    await _reload();
  }

  void reset() => state = const AppSettings();
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// Quick Exit

class ExitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Swaps the whole UI for the neutral screen. Data is not deleted.
  void exit() {
    state = true;
    ref.read(lockProvider.notifier).lock();
  }

  void comeBack() => state = false;
}

final exitProvider = NotifierProvider<ExitNotifier, bool>(ExitNotifier.new);

// PIN lock

class LockState {
  const LockState({
    required this.hasPin,
    required this.locked,
    this.lockedUntil,
  });

  final bool hasPin;
  final bool locked;

  /// Set after too many wrong PINs.
  final DateTime? lockedUntil;
}

class LockNotifier extends Notifier<LockState> {
  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  @override
  LockState build() {
    final hasPin = ref.watch(servicesProvider).hasPin;
    return LockState(hasPin: hasPin, locked: hasPin);
  }

  SecureKeyStore get _keys => ref.read(servicesProvider).keys;

  void lock() {
    if (state.hasPin && !state.locked) {
      state = LockState(hasPin: true, locked: true);
    }
  }

  Future<bool> unlock(String pin) async {
    final stored = await _keys.pin();
    if (stored == null) {
      state = const LockState(hasPin: false, locked: false);
      return true;
    }
    final f = await _keys.failures();
    if (f.lockedUntil != null && DateTime.now().isBefore(f.lockedUntil!)) {
      state = LockState(hasPin: true, locked: true, lockedUntil: f.lockedUntil);
      return false;
    }
    final hash = await compute(_hash, (pin, stored.salt));
    if (PinHasher.constantTimeEquals(hash, stored.hash)) {
      await _keys.saveFailures(0, null);
      state = const LockState(hasPin: true, locked: false);
      return true;
    }
    final fails = f.fails + 1;
    final until = fails >= maxAttempts ? DateTime.now().add(lockout) : null;
    await _keys.saveFailures(until == null ? fails : 0, until);
    state = LockState(hasPin: true, locked: true, lockedUntil: until);
    return false;
  }

  Future<void> setPin(String pin) async {
    final salt = PinHasher.newSalt();
    await _keys.savePin(salt, await compute(_hash, (pin, salt)));
    state = const LockState(hasPin: true, locked: false);
  }

  Future<void> removePin() async {
    await _keys.clearPin();
    state = const LockState(hasPin: false, locked: false);
  }

  void reset() => state = const LockState(hasPin: false, locked: false);
}

String _hash((String, String) a) => PinHasher.hash(a.$1, a.$2);

final lockProvider =
    NotifierProvider<LockNotifier, LockState>(LockNotifier.new);

// Journal data

final moodEntriesProvider = FutureProvider<List<MoodEntry>>(
    (ref) => ref.watch(servicesProvider).db.moodEntries());

final thoughtRecordsProvider = FutureProvider<List<ThoughtRecord>>(
    (ref) => ref.watch(servicesProvider).db.thoughtRecords());

/// Position shared for this session only. Never written to disk.
class PositionNotifier extends Notifier<({double lat, double lng})?> {
  @override
  ({double lat, double lng})? build() => null;
  void set(({double lat, double lng})? p) => state = p;
}

final positionProvider =
    NotifierProvider<PositionNotifier, ({double lat, double lng})?>(
        PositionNotifier.new);
