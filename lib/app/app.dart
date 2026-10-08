import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/exit/calculator_screen.dart';
import '../features/lock/lock_screen.dart';
import 'router.dart';
import 'state.dart';
import 'theme.dart';

class MindMapApp extends ConsumerStatefulWidget {
  const MindMapApp({super.key});

  @override
  ConsumerState<MindMapApp> createState() => _MindMapAppState();
}

class _MindMapAppState extends ConsumerState<MindMapApp>
    with WidgetsBindingObserver {
  late final GoRouter _router =
      buildRouter(onboarded: ref.read(settingsProvider).onboarded);

  /// Hides content in the app switcher (Android also sets FLAG_SECURE).
  bool _covered = false;

  // Triple-tap tracking.
  final _taps = <({DateTime at, Offset where})>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused) {
      ref.read(lockProvider.notifier).lock();
    }
    if (_covered == active) setState(() => _covered = !active);
  }

  void _quickExit() {
    ref.read(exitProvider.notifier).exit();
    // Clear the navigation stack so nothing sensitive is one "back" away.
    if (ref.read(settingsProvider).onboarded) _router.go('/');
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!ref.read(settingsProvider).tripleTapExit) return;
    final now = DateTime.now();
    _taps.removeWhere((t) =>
        now.difference(t.at) > const Duration(milliseconds: 600) ||
        (t.where - e.position).distance > 48);
    _taps.add((at: now, where: e.position));
    if (_taps.length >= 3) {
      _taps.clear();
      _quickExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MindMap Youth',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: _router,
      builder: (context, child) {
        final exited = ref.watch(exitProvider);
        final locked = ref.watch(lockProvider).locked;
        final hidden = exited || locked || _covered;
        final media = MediaQuery.of(context);
        final keyboardOpen = media.viewInsets.bottom > 0;
        final showBar = !keyboardOpen;

        return Listener(
          onPointerDown: hidden ? null : _onPointerDown,
          child: Stack(
            children: [
              ExcludeSemantics(
                excluding: hidden,
                child: Column(
                  children: [
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: showBar,
                        child: child!,
                      ),
                    ),
                    if (showBar)
                      _CrisisBar(onTap: () {
                        final path = _router.state.uri.path;
                        if (path != '/crisis') _router.push('/crisis');
                      }),
                  ],
                ),
              ),
              if (!hidden)
                Positioned(
                  top: media.padding.top + 4,
                  right: 8,
                  child: _ExitButton(onTap: _quickExit),
                ),
              if (locked && !exited) const LockScreen(),
              if (exited)
                CalculatorScreen(
                  onReturn: () => ref.read(exitProvider.notifier).comeBack(),
                ),
              if (_covered)
                ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Quick exit. Hides this app right away.',
      excludeSemantics: true,
      child: Material(
        color: scheme.inverseSurface,
        shape: const StadiumBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 20, color: scheme.onInverseSurface),
                  const SizedBox(width: 6),
                  Text(
                    'Exit',
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrisisBar extends StatelessWidget {
  const _CrisisBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = crisisButtonStyle(context);
    final bg = style.backgroundColor!.resolve({})!;
    final fg = style.foregroundColor!.resolve({})!;
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support, color: fg),
                const SizedBox(width: 8),
                Text(
                  'Need help now?',
                  style: TextStyle(
                      color: fg, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
