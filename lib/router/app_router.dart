import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/history_provider.dart'; // exposes appDatabaseProvider
import '../screens/onboarding_screen.dart';
import '../screens/main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final seen = await database.getBool('onboarding_seen');

      if (!seen && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      // ✅ Agar onboarding dekh li aur abhi bhi /onboarding pe hai
      if (seen && state.matchedLocation == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
});