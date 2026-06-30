import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false; // voice mode on/off (bar transform)
  String _liveText = '';
  final Random _rand = Random();

  static const int _barCount = 24;
  final List<double> _barLevels = List.filled(_barCount, 0.1);

  // ---- Continuous recording control ----
  // Accumulates the latest recognized words. No auto-send: only the
  // manual check button sends, only the manual X button cancels. This
  // avoids any race between a silence-timer and the user's own tap.
  String _accumulatedText = '';

  static const _primary = Color(0xFF1D4E89);

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isTyping) return;

    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      Vibration.vibrate(duration: 30, amplitude: 50);
    }

    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  // ---------------- Voice mode (inline, ChatGPT-style) ----------------
  // Pure "voice recording" experience: no live text shown, recording keeps
  // running (very long pauseFor so short pauses never cut it off), and
  // ONLY stops/sends when the user taps the check button, or cancels
  // with X. No automatic anything.

  Future<void> _startVoiceMode() async {
    if (widget.isTyping) return;

    // Always fully reset the engine before starting a new session -- this
    // is what fixes the "second time tapping check cancels instead of
    // sending" bug: stale state from the previous session was leaking in.
    await _speech.stop();
    await _speech.cancel();

    final available = await _speech.initialize(
      onError: (err) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );

    if (!available || !mounted) return;

    setState(() {
      _isListening = true;
      _accumulatedText = '';
      _liveText = '';
      for (int i = 0; i < _barCount; i++) {
        _barLevels[i] = 0.1;
      }
    });

    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        // Always keep the latest recognized words (partial or final).
        _accumulatedText = result.recognizedWords;
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          final normalized = (level / 10).clamp(0.0, 1.0);
          final jitter = _rand.nextDouble() * 0.15;
          for (int i = 0; i < _barCount - 1; i++) {
            _barLevels[i] = _barLevels[i + 1];
          }
          _barLevels[_barCount - 1] =
              (0.1 + normalized * 0.9 + jitter).clamp(0.1, 1.0);
        });
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onDevice: false,
        // Stopping/sending is entirely up to the user via X / check.
      ),
    );
  }

  // Cancel (X) -> discard everything, go back to normal text bar
  Future<void> _cancelVoice() async {
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _liveText = '';
      _accumulatedText = '';
    });
  }

  // Confirm (check) -> stop listening and send whatever was recognized.
  Future<void> _confirmVoice() async {
    await _speech.stop();
    if (!mounted) return;

    final text = _accumulatedText.trim();
    setState(() {
      _isListening = false;
      _liveText = '';
      _accumulatedText = '';
    });

    if (text.isEmpty) return;

    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      Vibration.vibrate(duration: 30, amplitude: 50);
    }

    widget.onSend(text);
  }

  @override
  void dispose() {
    _speech.stop();
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _isListening ? _buildVoiceBar() : _buildTextBar(),
        ),
      ),
    );
  }

  // Normal typing bar (unchanged behaviour)
  Widget _buildTextBar() {
    return Row(
      key: const ValueKey('textBar'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 130),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Mic button -> switches the bar into voice mode
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: widget.isTyping ? null : _startVoiceMode,
            icon: const Icon(Icons.mic_none, color: Colors.white),
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
                : const Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _hasText && !widget.isTyping ? _send : null,
            icon: const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // Voice mode bar: replaces the text field area with cancel / waveform / confirm
  Widget _buildVoiceBar() {
    return Row(
      key: const ValueKey('voiceBar'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cancel (X)
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _cancelVoice,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF334155)),
          ),
        ),
        const SizedBox(width: 10),

        // Waveform + live text, inside the same field-styled container
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Small pulsing mic indicator
                const Icon(Icons.mic_rounded, color: _primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: _liveText.isEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _barLevels.map((level) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 110),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5),
                              width: 3,
                              height: 6 + level * 26,
                              decoration: BoxDecoration(
                                color: _primary
                                    .withValues(alpha: 0.5 + level * 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          _liveText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Confirm (check) -> sends immediately, ChatGPT style
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: _primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _confirmVoice,
            icon: const Icon(Icons.check_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}