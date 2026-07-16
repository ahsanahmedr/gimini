import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/ai_doctor_screen.dart';
import '../screens/doctor_chat_screen.dart';
import '../screens/symptom_selection_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
        GoRoute(
    path: '/',
    builder: (context, state) => const HomeScreen(),
  ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
  path: '/ai-doctor',
  builder: (context, state) => const AiDoctorScreen(),
),
// ✅ Symptom selection screen
GoRoute(
  path: '/ai-doctor/symptoms',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return SymptomSelectionScreen(
      specialistId: extra['id'],
      specialistTitle: extra['title'],
      specialistEmoji: extra['emoji'],
    );
  },
),

// ✅ Doctor chat — symptoms bhi accept kare
GoRoute(
  path: '/ai-doctor/chat',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return DoctorChatScreen(
      specialistId: extra['id'],
      specialistTitle: extra['title'],
      specialistEmoji: extra['emoji'],
      symptoms: List<String>.from(extra['symptoms'] ?? []),
      duration: extra['duration'] ?? '',
      severity: extra['severity'] ?? '',
    );
  },
),
    ],
  );
});