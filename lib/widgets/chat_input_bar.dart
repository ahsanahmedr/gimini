import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final bool isTyping; // Bot typing ho to button disable

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.isTyping,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  static const _primary = Color(0xFF6C47FF);

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isTyping) return;

    // Vibrate on send (Claude jaisa feel)
    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      Vibration.vibrate(duration: 30, amplitude: 50);
    }

    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 130),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 15),
                  onChanged: (val) =>
                      setState(() => _hasText = val.trim().isNotEmpty),
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Color(0xFFB0B3C5)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _hasText && !widget.isTyping
                    ? _primary
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _hasText && !widget.isTyping ? _send : null,
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}