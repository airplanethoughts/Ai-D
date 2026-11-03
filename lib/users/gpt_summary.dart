import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class GPTSummaryScreen extends StatefulWidget {
  final AiService? service;
  const GPTSummaryScreen({super.key, this.service});
  @override
  State<GPTSummaryScreen> createState() => _GPTSummaryScreenState();
}

class _GPTSummaryScreenState extends State<GPTSummaryScreen> {
  late Future<String> _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _message = (widget.service ?? AiService()).reply([
      {
        'role': 'user',
        'content': 'Offer one brief, practical reflection prompt for today.',
      },
    ], mode: 'encouragement');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('A moment of encouragement')),
    body: FutureBuilder<String>(
      future: _message,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SelectableText(
                snapshot.hasError
                    ? 'Could not load a message. Check your connection or AI setup.'
                    : snapshot.data ?? '',
              ),
              TextButton(
                onPressed: () => setState(_load),
                child: Text(snapshot.hasError ? 'Retry' : 'New prompt'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
