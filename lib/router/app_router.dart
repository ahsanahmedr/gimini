import 'package:go_router/go_router.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    
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