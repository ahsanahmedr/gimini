import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  
  int _currentPage = 0;
  

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbitAnim;

  static const _purple = Color(0xFF6C47FF);
  static const _purpleLight = Color(0xFF9B7FFF);
  static const _purpleDark = Color(0xFF3D1FCC);
  static const _bg = Color(0xFF0A0A14);
  static const _cardBg = Color(0xFF12121F);
  static const _white = Colors.white;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      title: 'Meet your\nAI companion',
      subtitle:
          'Ask anything, get instant answers. Powered by Google Gemini — the world\'s most capable AI.',
      illustration: _IllustrationType.brain,
    ),
    _OnboardPage(
      title: 'Remember\neverything',
      subtitle:
          'Every conversation is saved. Pick up right where you left off — your history, always at hand.',
      illustration: _IllustrationType.history,
    ),
    _OnboardPage(
      title: 'Just start\ntalking',
      subtitle:
          'Type naturally, ask follow-ups, explore ideas. Your AI is ready whenever you are.',
      illustration: _IllustrationType.chat,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

_fadeController = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 400)); // ✅ 600 → 400

_slideController = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 400)); // ✅ 600 → 400
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _orbitController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _orbitAnim =
        CurvedAnimation(parent: _orbitController, curve: Curves.linear);

    _fadeController.forward();
    _slideController.forward();
  }

void _onPageChanged(int index) {
  setState(() => _currentPage = index);
  
  // ✅ Reset ki jagah seedha forward — no blink
  _fadeController.forward(from: 0.0);
  _slideController.forward(from: 0.0);
}

void _nextPage() {
  if (_currentPage < _pages.length - 1) {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400), // ✅ 999 → 400
      curve: Curves.easeInOut,
    );
  } else {
    _finish();
  }
}

Future<void> _finish() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_seen', true);
  if (mounted) {
    context.go('/'); // ✅ /home → /
  }
}

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background gradient orbs
          _BackgroundOrbs(orbitAnim: _orbitAnim),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 24),
                    child: _currentPage < _pages.length - 1
                        ? TextButton(
                            onPressed: _finish,
                            child: Text('Skip',
                                style: TextStyle(
                                    color: _white.withValues(alpha: 0.4),
                                    fontSize: 15)),
                          )
                        : const SizedBox(height: 40),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _PageContent(
                      page: _pages[i],
                      fadeAnim: _fadeAnim,
                      slideAnim: _slideAnim,
                      pulseAnim: _pulseAnim,
                      orbitAnim: _orbitAnim,
                      purple: _purple,
                      purpleLight: _purpleLight,
                      white: _white,
                      cardBg: _cardBg,
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? _purple
                                  : _white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // CTA Button
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_purple, _purpleDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: _purple.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page content widget ──────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Animation<double> pulseAnim;
  final Animation<double> orbitAnim;
  final Color purple, purpleLight, white, cardBg;

  const _PageContent({
    required this.page,
    required this.fadeAnim,
    required this.slideAnim,
    required this.pulseAnim,
    required this.orbitAnim,
    required this.purple,
    required this.purpleLight,
    required this.white,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          FadeTransition(
            opacity: fadeAnim,
            child: ScaleTransition(
              scale: pulseAnim,
              child: _Illustration(
                type: page.illustration,
                purple: purple,
                purpleLight: purpleLight,
                orbitAnim: orbitAnim,
                cardBg: cardBg,
              ),
            ),
          ),
          const SizedBox(height: 52),

          // Title
          FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: white.withValues(alpha: 0.55),
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustrations ─────────────────────────────────────────────────────────────

enum _IllustrationType { brain, history, chat }

class _Illustration extends StatelessWidget {
  final _IllustrationType type;
  final Color purple, purpleLight, cardBg;
  final Animation<double> orbitAnim;

  const _Illustration({
    required this.type,
    required this.purple,
    required this.purpleLight,
    required this.orbitAnim,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: 220,
      child: switch (type) {
        _IllustrationType.brain => _BrainIllustration(
            purple: purple, purpleLight: purpleLight, orbitAnim: orbitAnim),
        _IllustrationType.history => _HistoryIllustration(
            purple: purple, purpleLight: purpleLight, cardBg: cardBg),
        _IllustrationType.chat => _ChatIllustration(
            purple: purple, purpleLight: purpleLight, cardBg: cardBg),
      },
    );
  }
}

// Page 1 — Glowing brain with orbiting dots
class _BrainIllustration extends StatelessWidget {
  final Color purple, purpleLight;
  final Animation<double> orbitAnim;

  const _BrainIllustration(
      {required this.purple,
      required this.purpleLight,
      required this.orbitAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbitAnim,
      builder: (context, _) {
        final angle = orbitAnim.value * 2 * 3.14159;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: purple.withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 20),
                ],
              ),
            ),
            // Main circle
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [purpleLight, purple]),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 56),
            ),
            // Orbiting dots
            for (int i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                  90 * (i == 0
                      ? 1
                      : i == 1
                          ? -0.5
                          : -0.5) *
                      (angle * 0 + 1),
                  0,
                ).scale(
                  90 * _cos(angle + i * 2.094),
                  90 * _sin(angle + i * 2.094),
                ),
                child: Container(
                  width: i == 0 ? 16 : 12,
                  height: i == 0 ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0
                        ? Colors.white
                        : purpleLight.withValues(alpha: 0.7),
                    boxShadow: [
                      BoxShadow(
                          color: purple.withValues(alpha: 0.5), blurRadius: 8),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _cos(double angle) => _mathCos(angle);
  double _sin(double angle) => _mathSin(angle);
  double _mathCos(double a) {
    // Simple cos approximation using dart:math
    return -1 * (a % (2 * 3.14159) > 3.14159 ? -1 : 1) *
        (1 - (a % 3.14159) / 3.14159 * 2).abs();
  }

  double _mathSin(double a) {
    final normalized = a % (2 * 3.14159);
    return normalized < 3.14159
        ? (normalized / 3.14159) * 2 - 1
        : -((normalized - 3.14159) / 3.14159) * 2 + 1;
  }
}

// Page 2 — Chat history cards stacked
class _HistoryIllustration extends StatelessWidget {
  final Color purple, purpleLight, cardBg;

  const _HistoryIllustration(
      {required this.purple, required this.purpleLight, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Back card
        Transform.translate(
          offset: const Offset(0, 30),
          child: Transform.rotate(
            angle: -0.1,
            child: _HistoryCard(
              purple: purple, cardBg: cardBg, opacity: 0.4,
              lines: const [0.7, 0.5],
            ),
          ),
        ),
        // Mid card
        Transform.translate(
          offset: const Offset(0, 15),
          child: Transform.rotate(
            angle: 0.05,
            child: _HistoryCard(
              purple: purple, cardBg: cardBg, opacity: 0.7,
              lines: const [0.9, 0.6, 0.4],
            ),
          ),
        ),
        // Front card
        _HistoryCard(
          purple: purple, cardBg: cardBg, opacity: 1.0,
          lines: const [0.8, 0.6, 0.9, 0.4],
          showIcon: true,
          purpleLight: purpleLight,
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Color purple, cardBg;
  final Color? purpleLight;
  final double opacity;
  final List<double> lines;
  final bool showIcon;

  const _HistoryCard({
    required this.purple,
    required this.cardBg,
    required this.opacity,
    required this.lines,
    this.showIcon = false,
    this.purpleLight,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: purple.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [purpleLight!, purple]),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
            ],
            ...lines.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: 160 * w,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// Page 3 — Chat bubbles
class _ChatIllustration extends StatelessWidget {
  final Color purple, purpleLight, cardBg;

  const _ChatIllustration(
      {required this.purple, required this.purpleLight, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // User bubble (right)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [purpleLight, purple]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: purple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: const Text('What is quantum computing?',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        // Bot bubble (left)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: purple.withValues(alpha: 0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          LinearGradient(colors: [purpleLight, purple]),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 10),
                  ),
                  const SizedBox(width: 6),
                  Text('Gemini',
                      style: TextStyle(
                          color: purpleLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Quantum computing uses quantum\nmechanics to process information...',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Background orbs ───────────────────────────────────────────────────────────

class _BackgroundOrbs extends StatelessWidget {
  final Animation<double> orbitAnim;
  const _BackgroundOrbs({required this.orbitAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbitAnim,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C47FF).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3D1FCC).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _OnboardPage {
  final String title;
  final String subtitle;
  final _IllustrationType illustration;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}