import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
          'This deletes every check-in, thought record, your PIN, and your '
          'settings from this phone. There is no copy anywhere else, so it '
          'can\'t be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Erase everything')),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(servicesProvider).db.eraseEverything();
    ref.read(lockProvider.notifier).reset();
    ref.read(settingsProvider.notifier).reset();
    ref.read(positionProvider.notifier).set(null);
    ref.invalidate(moodEntriesProvider);
    ref.invalidate(thoughtRecordsProvider);
    router.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final hasPin = ref.watch(lockProvider).hasPin;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 110, 8),
            child: Text('Settings', style: t.headlineMedium),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(hasPin ? 'Change PIN' : 'Set a PIN'),
            subtitle: const Text('Locks the app whenever you leave it.'),
            onTap: () => context.push('/pin'),
          ),
          if (hasPin)
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: const Text('Remove PIN'),
              onTap: () => ref.read(lockProvider.notifier).removePin(),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.touch_app_outlined),
            title: const Text('Triple-tap to exit'),
            subtitle: const Text(
                'Tap anywhere three times fast to hide the app.'),
            value: settings.tripleTapExit,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTripleTapExit(v),
          ),
          const ListTile(
            leading: Icon(Icons.calculate_outlined),
            title: Text('Coming back after Exit'),
            subtitle: Text(
                'Exit shows a calculator. Press and hold the number at the top to return.'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Erase everything'),
            subtitle: const Text('Delete all entries, PIN, and settings.'),
            onTap: () => _erase(context, ref),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy'),
            subtitle: Text(
              'No account, no tracking, no ads. Entries are stored encrypted '
              'on this phone only and are left out of cloud backups, so if '
              'you lose the phone they are gone. The app can\'t monitor you '
              'or notify anyone. The only internet use is map pictures and '
              'links you tap.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text(
              'MindMap Youth is a self-reflection and skills tool inspired by '
              'CBT. It is not a medical device, not therapy, not a diagnosis, '
              'and not for emergencies. In danger? Call 911. Need to talk? '
              'Call or text 988.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Sources'),
            subtitle: Text(
              'Each listing shows where it came from and when it was last '
              'verified. Map data © OpenStreetMap contributors.',
            ),
          ),
        ],
      ),
    );
  }
}
