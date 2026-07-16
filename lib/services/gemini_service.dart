import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';

class GeminiService {
  // Replace with your Gemini API key from Google AI Studio
  static const _apiKey = 'AQ.Ab8RN6LTx6EN1wC2Vt7KnMM6TfYN8vo2hk4Mm7caECweINmyOw';

  late final GenerativeModel _model;
  late ChatSession _chat; // Gemini's own chat session (keeps context)

  GeminiService() {
    // Initialize Gemini model
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(
        'You are a helpful, friendly AI assistant. '
        'Give clear and concise answers. '
        'Use markdown formatting when helpful.',
      ),
    );

    
    _chat = _model.startChat();
  }

  // Load existing messages into Gemini context (history restore karo)
void loadHistory(List<ChatMessage> previousMessages) {
  final validMessages = previousMessages
      .where((msg) => msg.text.trim().isNotEmpty) // ← Yeh line zaroori hai
      .toList();

  final history = validMessages.map((msg) {
    return Content(
      msg.isUser ? 'user' : 'model',
      [TextPart(msg.text)],
    );
  }).toList();

  _chat = _model.startChat(history: history);
}

  // Send message and get response — Stream for typing effect
  Stream<String> sendMessage(String userMessage) async* {
    try {
      developer.log('Gemini request started', name: 'GeminiService');
      final response = _chat.sendMessageStream(
        Content.text(userMessage),
      );

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          developer.log('Gemini response chunk received', name: 'GeminiService');
          yield text;
        }
      }
      developer.log('Gemini stream completed', name: 'GeminiService');
    } catch (e) {
      developer.log('Gemini error: $e', name: 'GeminiService');
      yield 'Sorry, something went wrong. Please try again.';
    }
  }
}