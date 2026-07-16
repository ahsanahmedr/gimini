import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';


class DoctorChatScreen extends StatefulWidget {
  final String specialistId;
  final String specialistTitle;
  final String specialistEmoji;
    final List<String> symptoms;     // ✅ naya
  final String duration;           // ✅ naya
  final String severity;   

  const DoctorChatScreen({
    super.key,
    required this.specialistId,
    required this.specialistTitle,
    required this.specialistEmoji,
        required this.symptoms,
    required this.duration,
    required this.severity,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DoctorMessage> _messages = [];
  bool _isTyping = false;
  late ChatSession _chat;

  static const _apiKey = 'AQ.Ab8RN6I4nuQGRQ5d3xWkgmdxLO46ltRIQ8Jv0Q1Y8XLxZvdkrA'; 
  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);

  // Har specialist ka system prompt
  static const _prompts = {
  'cardiologist':
      'You are a strict AI Cardiologist. You ONLY answer questions related to heart and cardiovascular system — chest pain, palpitations, hypertension, arrhythmia, heart failure, cholesterol, ECG, etc. '
      'If the user asks about ANY other medical condition or body part (e.g. teeth, eyes, brain, blood, diet), you must respond with: '
      '"I\'m a Cardiologist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end heart-related answers with a reminder to consult a real cardiologist.',

  'neurologist':
      'You are a strict AI Neurologist. You ONLY answer questions related to the brain, nervous system, and neurological conditions — headaches, migraines, seizures, dizziness, memory loss, nerve pain, stroke, Parkinson\'s, MS, etc. '
      'If the user asks about ANY other medical issue (e.g. heart, teeth, blood, diet, eyes), respond with: '
      '"I\'m a Neurologist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end neurological answers with a reminder to consult a real neurologist.',

  'hematologist':
      'You are a strict AI Hematologist. You ONLY answer questions related to blood and blood disorders — anemia, leukemia, clotting disorders, sickle cell, blood counts, bleeding disorders, bone marrow, etc. '
      'If the user asks about ANY other medical condition (e.g. heart, brain, teeth, eyes, diet), respond with: '
      '"I\'m a Hematologist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end blood-related answers with a reminder to consult a real hematologist.',

  'dentist':
      'You are a strict AI Dentist. You ONLY answer questions related to oral health — toothache, cavities, gum disease, tooth sensitivity, braces, dental hygiene, mouth ulcers, wisdom teeth, etc. '
      'If the user asks about ANY other medical issue (e.g. heart, brain, blood, diet, eyes), respond with: '
      '"I\'m a Dentist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end dental answers with a reminder to consult a real dentist.',

  'nutritionist':
      'You are a strict AI Nutritionist. You ONLY answer questions related to diet, nutrition, food, vitamins, minerals, weight management, meal planning, nutritional deficiencies, and healthy eating habits. '
      'If the user asks about ANY medical condition unrelated to nutrition (e.g. heart disease treatment, neurological disorders, blood diseases, dental procedures, eye surgery), respond with: '
      '"I\'m a Nutritionist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end nutrition answers with evidence-based advice.',

  'eye_specialist':
      'You are a strict AI Eye Specialist (Ophthalmologist). You ONLY answer questions related to eyes and vision — blurry vision, dry eyes, eye infections, glaucoma, cataracts, retina issues, glasses, contact lenses, etc. '
      'If the user asks about ANY other medical issue (e.g. heart, brain, blood, teeth, diet), respond with: '
      '"I\'m an Eye Specialist and that\'s outside my area of expertise. Please consult the relevant specialist for this concern." '
      'Never answer out-of-scope questions even if the user insists. Always end eye-related answers with a reminder to consult a real ophthalmologist.',
};

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
  final systemPrompt = _prompts[widget.specialistId] ?? '';

  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
    systemInstruction: Content.system(systemPrompt),
  );

  _chat = model.startChat();

  // ✅ Structured prompt Gemini ko bhejo
  final structuredPrompt =
      'Patient Report:\n'
      '• Symptoms: ${widget.symptoms.join(', ')}\n'
      '• Duration: ${widget.duration}\n'
      '• Severity: ${widget.severity}\n\n'
      'Please analyze these symptoms and provide your assessment.';

  // Welcome message UI mein dikhao
  setState(() {
    _messages.add(_DoctorMessage(
      text: 'Hello! I\'m your AI ${widget.specialistTitle} ${widget.specialistEmoji}\n\n'
            'I can see you are experiencing:\n'
            '${widget.symptoms.map((s) => '• $s').join('\n')}\n\n'
            '**Duration:** ${widget.duration} | **Severity:** ${widget.severity}\n\n'
            'Let me analyze this for you...',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
  });

  // ✅ Auto first message bhejo
  _sendStructuredPrompt(structuredPrompt);
}

Future<void> _sendStructuredPrompt(String prompt) async {
  final botMsg = _DoctorMessage(
    text: '',
    isUser: false,
    timestamp: DateTime.now(),
  );
  setState(() => _messages.add(botMsg));

  String fullResponse = '';
  bool firstChunk = true;

  try {
    await for (final chunk
        in _chat.sendMessageStream(Content.text(prompt))) {
      fullResponse += chunk.text ?? '';
      setState(() {
        if (firstChunk) {
          firstChunk = false;
          _isTyping = false;
        }
        _messages[_messages.length - 1] = _DoctorMessage(
          text: fullResponse,
          isUser: false,
          timestamp: botMsg.timestamp,
        );
      });
      _scrollToBottom();
    }
  } catch (e) {
    setState(() {
      _isTyping = false;
      _messages[_messages.length - 1] = _DoctorMessage(
        text: 'Sorry, something went wrong. Please try again.',
        isUser: false,
        timestamp: botMsg.timestamp,
      );
    });
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    _controller.clear();

    setState(() {
      _messages.add(_DoctorMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Streaming bot response
    final botMsg = _DoctorMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(botMsg));

    String fullResponse = '';
    bool firstChunk = true;

    try {
      await for (final chunk
          in _chat.sendMessageStream(Content.text(text))) {
        final chunkText = chunk.text ?? '';
        fullResponse += chunkText;

        setState(() {
          if (firstChunk) {
            firstChunk = false;
            _isTyping = false;
          }
          _messages[_messages.length - 1] = _DoctorMessage(
            text: fullResponse,
            isUser: false,
            timestamp: botMsg.timestamp,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages[_messages.length - 1] = _DoctorMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
          timestamp: botMsg.timestamp,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.specialistEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI ${widget.specialistTitle}',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTyping ? _primary : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(_DoctorMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: msg.text.isEmpty
                  ? _buildTypingDots()
                  : isUser
                      ? Text(
                          msg.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15, height: 1.4),
                        )
                      : MarkdownBody(
                          data: msg.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                color: _dark, fontSize: 15, height: 1.5),
                          ),
                        ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF1D4E89),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
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
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 15),
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Describe your symptoms...',
                    hintStyle: TextStyle(color: Color(0xFFB0B3C5)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isTyping ? Colors.grey.shade300 : _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _DoctorMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}