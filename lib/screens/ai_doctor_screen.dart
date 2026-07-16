import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiDoctorScreen extends StatelessWidget {
  const AiDoctorScreen({super.key});

  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);

  static const _specialists = [
    (
      id: 'cardiologist',
      emoji: '❤️',
      title: 'Cardiologist',
      subtitle: 'Heart & cardiovascular issues',
      color: Color(0xFFFFE4E4),
    ),
    (
      id: 'neurologist',
      emoji: '🧠',
      title: 'Neurologist',
      subtitle: 'Brain, nerves & headaches',
      color: Color(0xFFEDE9FE),
    ),
    (
      id: 'hematologist',
      emoji: '🩸',
      title: 'Hematologist',
      subtitle: 'Blood disorders & conditions',
      color: Color(0xFFFFEDD5),
    ),
    (
      id: 'dentist',
      emoji: '🦷',
      title: 'Dentist',
      subtitle: 'Teeth, gums & oral health',
      color: Color(0xFFE0F2FE),
    ),
    (
      id: 'nutritionist',
      emoji: '🥗',
      title: 'Nutritionist',
      subtitle: 'Diet, nutrition & healthy eating',
      color: Color(0xFFDCFCE7),
    ),
    (
      id: 'eye_specialist',
      emoji: '👁️',
      title: 'Eye Specialist',
      subtitle: 'Vision & eye conditions',
      color: Color(0xFFFEF9C3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 18),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'AI Doctor',
          style: TextStyle(
              color: _dark, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4E89), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Select a Specialist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Choose a doctor type and describe\nyour symptoms for AI guidance.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('🏥', style: TextStyle(fontSize: 48)),
              ],
            ),
          ),

          // Disclaimer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For informational purposes only. Always consult a real doctor.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Available Specialists',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Specialists grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 0.95, // ← 1.1 se kam kiya
),
              itemCount: _specialists.length,
              itemBuilder: (_, i) {
                final s = _specialists[i];
                return _SpecialistCard(
                  id: s.id,
                  emoji: s.emoji,
                  title: s.title,
                  subtitle: s.subtitle,
                  color: s.color,
onTap: () => context.push(
  '/ai-doctor/symptoms', // 
  extra: {
    'id': s.id,
    'title': s.title,
    'emoji': s.emoji,
  },
),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SpecialistCard({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
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