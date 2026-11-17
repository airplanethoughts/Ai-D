import 'package:flutter/material.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.info, required this.date});

  final Map info;
  final String date;

  @override
  Widget build(BuildContext context) {
    final image = (info['picURL'] ?? '').toString();
    final reflection = (info['AI_response'] ?? '').toString().trim();
    return Scaffold(
      appBar: AppBar(title: Text(date)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                (info['title_for_today'] ?? 'Your reflection').toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text('Mood · ${info['happiness_level'] ?? '—'}/10'),
              const SizedBox(height: 24),
              if (image.isNotEmpty) ...[
                Image.network(
                  image,
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text('Image unavailable'),
                ),
                const SizedBox(height: 24),
              ],
              SelectableText(
                (info['mood_of_the_day'] ?? '').toString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (reflection.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Divider(),
                Text(
                  'AI reflection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(reflection),
                const SizedBox(height: 12),
                const Text('A reflection aid, not professional advice.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
