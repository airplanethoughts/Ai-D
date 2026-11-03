import 'package:cloud_functions/cloud_functions.dart';

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}

/// The client sends authenticated requests to our callable function, never API keys.
class AiService {
  final Future<String> Function(String, List<Map<String, String>>) _send;
  AiService({Future<String> Function(String, List<Map<String, String>>)? send})
    : _send = send ?? _call;

  static Future<String> _call(
    String mode,
    List<Map<String, String>> messages,
  ) async {
    try {
      final functions = FirebaseFunctions.instanceFor(
        region: const String.fromEnvironment(
          'FUNCTIONS_REGION',
          defaultValue: 'us-central1',
        ),
      );
      final result = await functions
          .httpsCallable(
            'aiReply',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 40)),
          )
          .call<Map<String, dynamic>>({'mode': mode, 'messages': messages});
      final text = result.data['text'];
      if (text is! String || text.trim().isEmpty) {
        throw const AiServiceException(
          'The assistant returned no text. Please try again.',
        );
      }
      return text.trim();
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw const AiServiceException(
            'Please sign in again to use the assistant.',
          );
        case 'resource-exhausted':
          throw const AiServiceException(
            'Your daily AI limit has been reached. Try again tomorrow.',
          );
        case 'unavailable':
        case 'deadline-exceeded':
          throw const AiServiceException(
            'The assistant is unavailable. Your text is safe; please retry.',
          );
        default:
          throw const AiServiceException(
            'Could not contact the assistant. Check your connection and setup.',
          );
      }
    }
  }

  Future<String> reply(
    List<Map<String, String>> messages, {
    String mode = 'chat',
  }) async {
    if (messages.isEmpty ||
        messages.length > 21 ||
        messages.last['role'] != 'user') {
      throw const AiServiceException(
        'A conversation must end with a user message.',
      );
    }
    for (final message in messages) {
      if (!['user', 'assistant'].contains(message['role']) ||
          (message['content'] ?? '').trim().isEmpty ||
          message['content']!.length > 2000) {
        throw const AiServiceException(
          'Messages must contain 1–2,000 characters.',
        );
      }
    }
    return _send(mode, messages);
  }
}
