import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../app/theme.dart';
import '../../widgets/decor.dart';
import '../locator/locator_screen.dart';
import '../mood/reflect_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Quick Exit should not leave entries on screen for whoever comes back.
    ref.listen(exitProvider, (_, exited) {
      if (exited) setState(() => _tab = 0);
    });
    return Scaffold(
      body: LeafCorners(
        top: false,
        // Only where there is empty space; lists would run over the leaves.
        bottom: _tab == 0,
        child: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(onTab: (i) => setState(() => _tab = i)),
            const LocatorScreen(),
            const ReflectScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            label: 'Find Help',
          ),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Reflect'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onTab});
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
        children: [
          Text('Hi. How are you doing?', style: t.headlineMedium),
          const SizedBox(height: 4),
          Text('Everything here stays on this phone.', style: t.bodyMedium),
          const SizedBox(height: 20),
          _ActionCard(
            icon: Icons.mood,
            title: 'Check in',
            subtitle: 'Thirty seconds on how today feels.',
            onTap: () => context.push('/checkin'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.psychology_alt_outlined,
            title: 'Work through a thought',
            subtitle: 'Slow a stuck thought down, step by step.',
            onTap: () => context.push('/thought'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.place_outlined,
            title: 'Find help near you',
            subtitle: 'Counseling, teen centers, and people to talk to.',
            onTap: () => onTab(1),
          ),
          const SizedBox(height: 24),
          Text(
            'MindMap Youth is a self-reflection tool, not therapy or a diagnosis, '
            'and it is not for emergencies.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: coral,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: const Color(0xFF2A1A12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
