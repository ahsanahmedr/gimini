import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final VoidCallback? onMenuTap;
  const ChatScreen({super.key, required this.sessionId, this.onMenuTap});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends ConsumerState<ChatScreen> {
final _scrollController = ScrollController();
final SpeechToText _speech = SpeechToText();

  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _bg = Color(0xFFF8FAFC);

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
@override
void initState() {
  super.initState();
  _initSpeech();
}

Future<void> _initSpeech() async {
  await _speech.initialize();
}
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.sessionId));
    final notifier = ref.read(chatProvider(widget.sessionId).notifier);

    // Naye message pe auto scroll
    _scrollToBottom();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        
        backgroundColor: Colors.white,
        elevation: 0,
                leading: IconButton(
  icon: const Icon(Icons.menu_rounded, color: _dark, size: 24),
  onPressed: widget.onMenuTap, // ✅ MainScreen ka drawer khulega
),
       
        
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Assistant',
                    style: TextStyle(
                        color: _dark,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                Text(
                  chatState.isTyping ? 'Typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: chatState.isTyping ? _primary : Colors.green,
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
            child: chatState.messages.isEmpty
                ? const _WelcomeHint()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: chatState.messages.length +
                        (chatState.isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (chatState.isTyping &&
                          i == chatState.messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: chatState.messages[i]);
                    },
                  ),
          ),
          ChatInputBar(
            isTyping: chatState.isTyping,
            onSend: (text) => notifier.sendMessage(text),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  static const _primary = Color(0xFF1D4E89);
  static const _muted = Color(0xFF475569);

  const _WelcomeHint();

  @override

  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: _primary, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'How can I help you?',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask me anything!',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}