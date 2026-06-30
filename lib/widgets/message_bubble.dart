import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  static const _primary = Color(0xFF6C47FF);
  static const _dark = Color(0xFF12132A);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

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
            // ✅ Animate sirf pehli baar — key se bind karo
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        message.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.4),
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              color: _dark, fontSize: 15, height: 1.5),
                          code: TextStyle(
                            backgroundColor: Colors.grey.shade100,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
              ),
            ),

            // Timestamp
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    ).animate(
      // ✅ message.id se bind — sirf naye bubble pe animation chalegi
      key: ValueKey(message.id),
      effects: [
        FadeEffect(duration: 300.ms),
        SlideEffect(
          begin: Offset(isUser ? 0.3 : -0.3, 0),
          end: Offset.zero,
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
      ],
    );
  }
}