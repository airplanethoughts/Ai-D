import 'package:flutter/material.dart';
import 'services/ai_service.dart';

class ChatPage extends StatefulWidget {
  final String character;
  final AiService? service;
  const ChatPage({
    super.key,
    this.character = 'supportive companion',
    this.service,
  });
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _history = [];
  late final AiService _service = widget.service ?? AiService();
  bool _busy = false;
  String? _pending;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? submitted]) async {
    if (_busy) return;
    final text = _pending ?? (submitted ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      setState(() => _error = 'Keep messages to 2,000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _pending = text;
    });
    _controller.clear();
    // Keep ten complete prior turns in chronological order, then the new message.
    final start = _history.length > 20 ? _history.length - 20 : 0;
    final request = [
      ..._history.skip(start),
      {'role': 'user', 'content': text},
    ];
    try {
      final response = await _service.reply(request);
      if (!mounted) return;
      setState(() {
        _history.addAll([
          {'role': 'user', 'content': text},
          {'role': 'assistant', 'content': response},
        ]);
        _pending = null;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AiServiceException
              ? e.message
              : 'Could not send. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI companion')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'An AI reflection companion, not a therapist. Messages are sent to your configured server and AI provider. Recent conversation history is included.',
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_history.isEmpty)
                const Text('What would you like to reflect on today?'),
              for (final message in _history)
                ListTile(
                  title: Text(message['role'] == 'user' ? 'You' : 'Assistant'),
                  subtitle: SelectableText(message['content']!),
                ),
              if (_pending != null)
                ListTile(title: const Text('You'), subtitle: Text(_pending!)),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(_error!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => _send(),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _controller.text = _pending ?? '';
                              _pending = null;
                              _error = null;
                            }),
                      child: const Text('Edit message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_busy && _pending == null,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Message'),
                  onSubmitted: _send,
                ),
              ),
              IconButton(
                tooltip: 'Send message',
                onPressed: _busy || _pending != null ? null : () => _send(),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
