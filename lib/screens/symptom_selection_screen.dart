import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SymptomSelectionScreen extends StatefulWidget {
  final String specialistId;
  final String specialistTitle;
  final String specialistEmoji;

  const SymptomSelectionScreen({
    super.key,
    required this.specialistId,
    required this.specialistTitle,
    required this.specialistEmoji,
  });

  @override
  State<SymptomSelectionScreen> createState() =>
      _SymptomSelectionScreenState();
}

class _SymptomSelectionScreenState extends State<SymptomSelectionScreen> {
  final Set<String> _selectedSymptoms = {};
  String? _selectedDuration;
  String? _selectedSeverity;

  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);

  static const _specialistSymptoms = {
    'cardiologist': [
      'Chest Pain', 'Palpitations', 'Shortness of Breath',
      'High Blood Pressure', 'Dizziness', 'Fatigue',
      'Swollen Legs', 'Irregular Heartbeat', 'Cold Sweats',
    ],
    'neurologist': [
      'Headache', 'Migraine', 'Dizziness', 'Memory Loss',
      'Seizures', 'Numbness', 'Tremors', 'Sleep Issues',
      'Blurred Vision', 'Confusion',
    ],
    'hematologist': [
      'Fatigue', 'Pale Skin', 'Easy Bruising', 'Excessive Bleeding',
      'Frequent Infections', 'Bone Pain', 'Night Sweats',
      'Swollen Lymph Nodes', 'Shortness of Breath',
    ],
    'dentist': [
      'Toothache', 'Bleeding Gums', 'Tooth Sensitivity', 'Bad Breath',
      'Swollen Gums', 'Tooth Decay', 'Jaw Pain',
      'Loose Teeth', 'Mouth Ulcers',
    ],
    'nutritionist': [
      'Weight Gain', 'Weight Loss', 'Fatigue', 'Hair Fall',
      'Weak Immunity', 'Digestive Issues', 'Vitamin Deficiency',
      'Poor Appetite', 'Muscle Weakness', 'Skin Problems',
    ],
    'eye_specialist': [
      'Blurry Vision', 'Dry Eyes', 'Eye Redness', 'Eye Pain',
      'Watery Eyes', 'Light Sensitivity', 'Floaters',
      'Double Vision', 'Itchy Eyes',
    ],
  };

  static const _durations = [
    ('Today', '📅'),
    ('2-3 Days', '🗓️'),
    ('1 Week', '📆'),
    ('1 Month+', '⏳'),
  ];

  static const _severities = [
    ('Mild', '🟢', Color(0xFF16A34A)),
    ('Moderate', '🟡', Color(0xFFD97706)),
    ('Severe', '🔴', Color(0xFFDC2626)),
  ];

  bool get _canProceed =>
      _selectedSymptoms.isNotEmpty &&
      _selectedDuration != null &&
      _selectedSeverity != null;

  void _analyze() {
    if (!_canProceed) return;

    context.push(
      '/ai-doctor/chat',
      extra: {
        'id': widget.specialistId,
        'title': widget.specialistTitle,
        'emoji': widget.specialistEmoji,
        'symptoms': _selectedSymptoms.toList(),
        'duration': _selectedDuration,
        'severity': _selectedSeverity,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final symptoms =
        _specialistSymptoms[widget.specialistId] ?? [];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(widget.specialistEmoji,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'AI ${widget.specialistTitle}',
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Step 1 — Symptoms
                _stepCard(
                  step: '1',
                  title: 'Select Your Symptoms',
                  subtitle: 'Choose all that apply',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptoms.map((symptom) {
                      final selected =
                          _selectedSymptoms.contains(symptom);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.remove(symptom);
                            } else {
                              _selectedSymptoms.add(symptom);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? _primary
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _primary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Step 2 — Duration
                _stepCard(
                  step: '2',
                  title: 'How long have you had these symptoms?',
                  subtitle: 'Select duration',
                  child: Row(
                    children: _durations.map((d) {
                      final selected = _selectedDuration == d.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDuration = d.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? _primary
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(d.$2,
                                    style:
                                        const TextStyle(fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(
                                  d.$1,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Step 3 — Severity
                _stepCard(
                  step: '3',
                  title: 'How severe are your symptoms?',
                  subtitle: 'Select severity level',
                  child: Row(
                    children: _severities.map((s) {
                      final selected = _selectedSeverity == s.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSeverity = s.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? s.$3.withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? s.$3
                                    : const Color(0xFFE2E8F0),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(s.$2,
                                    style:
                                        const TextStyle(fontSize: 22)),
                                const SizedBox(height: 6),
                                Text(
                                  s.$1,
                                  style: TextStyle(
                                    color: selected
                                        ? s.$3
                                        : const Color(0xFF475569),
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom — Analyze button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Selected summary
                if (_selectedSymptoms.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedSymptoms.length} symptom(s) selected'
                      '${_selectedDuration != null ? ' • $_selectedDuration' : ''}'
                      '${_selectedSeverity != null ? ' • $_selectedSeverity' : ''}',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _canProceed ? _analyze : null,
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Analyze Symptoms'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFCBD5E1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _stepCard({
    required String step,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}