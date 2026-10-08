import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/state.dart';
import 'core/secure_key_store.dart';
import 'data/app_database.dart';
import 'data/resource_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keys = SecureKeyStore();
  final db = await AppDatabase.open(keys);
  final services = AppServices(
    keys: keys,
    db: db,
    resources: await ResourceRepository.load(),
    initialSettings: await db.settings(),
    hasPin: await keys.pin() != null,
  );
  runApp(ProviderScope(
    overrides: [servicesProvider.overrideWithValue(services)],
    child: const MindMapApp(),
  ));
}
