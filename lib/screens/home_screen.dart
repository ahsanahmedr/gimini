import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI Engine',
          style: TextStyle(
            color: _dark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _dark),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'What would you like to do?',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Do boxes — grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Box 1 — AI Doctor
                  _FeatureBox(
                    emoji: '👩‍⚕️',
                    title: 'AI Doctor',
                    subtitle: 'Get health advice & symptoms check',
                    color: const Color(0xFFE8F4FD),
                    iconColor: const Color(0xFF2196F3),
                    onTap: () => context.go('/ai-doctor'),
                  ),

                  // Box 2 — Chat with AI
                  _FeatureBox(
                    emoji: '🤖',
                    title: 'Chat with AI',
                    subtitle: 'Your personal AI assistant',
                    color: const Color(0xFFEEF2FF),
                    iconColor: _primary,
                    onTap: () => context.go('/main'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBox extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureBox({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
  padding: const EdgeInsets.all(16), // ← 20 se 16 kiya
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min, // ✅ Add karo
    children: [
      Container(
        width: 50, // ← 70 se 64 kiya
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 30)), // ← 36 se 30
        ),
      ),
      const SizedBox(height: 10), // ← 14 se 10
      Text(
        title,
        style: const TextStyle(
          fontSize: 12, // ← 15 se 14
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // ✅ Add karo
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
),
      ),
    );
  }
}