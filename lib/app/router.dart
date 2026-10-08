import 'package:go_router/go_router.dart';

import '../features/crisis_hub/crisis_hub_screen.dart';
import '../features/home/home_shell.dart';
import '../features/locator/resource_detail_screen.dart';
import '../features/mood/checkin_screen.dart';
import '../features/mood/thought_record_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/set_pin_screen.dart';

GoRouter buildRouter({required bool onboarded}) => GoRouter(
      initialLocation: onboarded ? '/' : '/welcome',
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/', builder: (_, _) => const HomeShell()),
        GoRoute(path: '/crisis', builder: (_, _) => const CrisisHubScreen()),
        GoRoute(
          path: '/resource/:id',
          builder: (_, s) => ResourceDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/checkin', builder: (_, _) => const CheckinScreen()),
        GoRoute(path: '/thought', builder: (_, _) => const ThoughtRecordScreen()),
        GoRoute(path: '/pin', builder: (_, _) => const SetPinScreen()),
      ],
    );
