import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../deployment_features.dart';

class GPTSummaryScreen extends StatefulWidget {
  final AiService? service;
  const GPTSummaryScreen({super.key, this.service});
  @override
  State<GPTSummaryScreen> createState() => _GPTSummaryScreenState();
}

class _GPTSummaryScreenState extends State<GPTSummaryScreen> {
  late Future<String> _message;
  int _prompt = 0;
  static const _prompts = [
    'What gave you a little energy today, and what drained it?',
    'What is one small thing you would like to do differently tomorrow?',
    'When did you feel most connected to someone today?',
    'What went better than you expected?',
  ];
  @override
  void initState() {
    super.initState();
    if (DeploymentFeatures.aiEnabled) _load();
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
    body: !DeploymentFeatures.aiEnabled
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Self-reflection · written prompts, not AI-generated',
                ),
                const SizedBox(height: 16),
                SelectableText(_prompts[_prompt]),
                TextButton(
                  onPressed: () =>
                      setState(() => _prompt = (_prompt + 1) % _prompts.length),
                  child: const Text('New prompt'),
                ),
              ],
            ),
          )
        : FutureBuilder<String>(
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
