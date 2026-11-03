import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'form_widget.dart';
import 'specific_journal.dart';

class YourJournals extends StatefulWidget {
  const YourJournals({super.key});
  @override
  State<YourJournals> createState() => _YourJournalsState();
}

class _YourJournalsState extends State<YourJournals> {
  late final _ref = FirebaseDatabase.instance.ref(
    'users/${auth.currentUser!.uid}',
  );
  late final _stream = _ref.orderByChild('date').limitToLast(100).onValue;
  Future<void> _delete(DataSnapshot entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this journal?'),
        content: const Text(
          'The entry and its uploaded image will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final data = entry.value as Map;
      final url = data['picURL'];
      if (url is String && url.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      }
      await entry.ref.remove();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not finish deleting. Please retry.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your Journey')),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Write a journal',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FormPage()),
      ),
      child: const Icon(Icons.add),
    ),
    body: StreamBuilder<DatabaseEvent>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Could not load journals. Check your connection and permissions.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!.snapshot.children
            .toList()
            .reversed
            .toList();
        if (entries.isEmpty) {
          return const Center(child: Text('Write your first reflection.'));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            for (final entry in entries)
              if (entry.value is Map) _tile(entry),
          ],
        );
      },
    ),
  );
  Widget _tile(DataSnapshot entry) {
    final data = entry.value as Map;
    final date = DateTime.fromMillisecondsSinceEpoch(
      data['date'] is num ? (data['date'] as num).toInt() : 0,
    );
    final formatted = DateFormat.yMMMd().format(date);
    return Card(
      child: ListTile(
        title: Text((data['title_for_today'] ?? 'Reflection').toString()),
        subtitle: Text('$formatted · ${data['happiness_level'] ?? '—'}/10'),
        trailing: IconButton(
          tooltip: 'Delete journal',
          onPressed: () => _delete(entry),
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayDetailScreen(info: data, date: formatted),
          ),
        ),
      ),
    );
  }
}
