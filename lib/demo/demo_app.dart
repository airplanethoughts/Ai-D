import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoEntry {
  final String id, title, body;
  final int mood;
  DemoEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.mood,
  });
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'mood': mood,
  };
  static DemoEntry? fromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['title'] is! String ||
        raw['body'] is! String ||
        raw['mood'] is! int) {
      return null;
    }
    final mood = raw['mood'] as int;
    if (mood < 0 || mood > 10) return null;
    return DemoEntry(
      id: raw['id'],
      title: raw['title'],
      body: raw['body'],
      mood: mood,
    );
  }
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ai-D',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const DemoHome(),
  );
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});
  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final List<DemoEntry> _entries = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('aid-demo-journal-v1');
      final data = raw == null ? [] : jsonDecode(raw);
      if (data is! List) throw const FormatException();
      final entries = data
          .map(DemoEntry.fromJson)
          .whereType<DemoEntry>()
          .toList();
      if (mounted) setState(() => _entries.addAll(entries));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not read local journals. Stored data was not overwritten.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _persist(List<DemoEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(
        'aid-demo-journal-v1',
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
      if (!ok) throw StateError('Storage unavailable');
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Local storage is unavailable. The change was not saved.',
        );
      }
      return false;
    }
  }

  Future<void> _edit([DemoEntry? entry]) async {
    final changed = await Navigator.of(context).push<DemoEntry>(
      MaterialPageRoute(builder: (_) => DemoEditor(entry: entry)),
    );
    if (changed == null) return;
    final next = [..._entries];
    final index = next.indexWhere((e) => e.id == changed.id);
    if (index < 0) {
      next.insert(0, changed);
    } else {
      next[index] = changed;
    }
    if (await _persist(next) && mounted) {
      setState(() {
        _entries
          ..clear()
          ..addAll(next);
        _error = null;
      });
    }
  }

  Future<void> _delete(DemoEntry entry) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this local journal?'),
        content: const Text('This cannot be undone.'),
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
    if (yes != true) return;
    final next = _entries.where((e) => e.id != entry.id).toList();
    if (await _persist(next) && mounted) {
      setState(
        () => _entries
          ..clear()
          ..addAll(next),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ai-D · local demo')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Local demo: journals stay in this browser/device. No account, cloud sync, or AI requests. Clearing app storage removes them.',
          ),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
        Expanded(
          child: _page == 0
              ? _journals()
              : _page == 1
              ? _prompts()
              : _activities(),
        ),
      ],
    ),
    floatingActionButton: _page == 0 && !_loading
        ? FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Write a journal'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _page,
      onDestinationSelected: (i) => setState(() => _page = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          label: 'Your Journey',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outline),
          label: 'Reflect',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Explore',
        ),
      ],
    ),
  );
  Widget _journals() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_entries.isEmpty) {
      return const Center(child: Text('Your first reflection starts here.'));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        for (final e in _entries)
          Card(
            child: ListTile(
              title: Text(e.title),
              subtitle: Text(
                '${e.mood}/10 · ${e.body}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _edit(e),
              trailing: IconButton(
                tooltip: 'Delete ${e.title}',
                onPressed: () => _delete(e),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
      ],
    );
  }

  Widget _prompts() => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Reflection prompts', style: TextStyle(fontSize: 24)),
      Text(
        'These are written prompts, not AI-generated advice. Connected AI chat is available only after you configure Firebase and the backend.',
      ),
      Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('What took energy today, and what gave some back?'),
        ),
      ),
      Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Who helped you feel connected? What small step could you take tomorrow?',
          ),
        ),
      ),
    ],
  );
  Widget _activities() => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Sample activities', style: TextStyle(fontSize: 24)),
      Text('Illustrative ideas — these are not live local events.'),
      ListTile(
        leading: Icon(Icons.park_outlined),
        title: Text('Take a short walk'),
        subtitle: Text('Choose a route that feels comfortable to you.'),
      ),
      ListTile(
        leading: Icon(Icons.chat_bubble_outline),
        title: Text('Check in with a friend'),
        subtitle: Text(
          'A short, low-pressure message can be a starting point.',
        ),
      ),
    ],
  );
}

class DemoEditor extends StatefulWidget {
  final DemoEntry? entry;
  const DemoEditor({super.key, this.entry});
  @override
  State<DemoEditor> createState() => _DemoEditorState();
}

class _DemoEditorState extends State<DemoEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.entry?.title);
  late final _body = TextEditingController(text: widget.entry?.body);
  late double _mood = (widget.entry?.mood ?? 5).toDouble();
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your reflection')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Add a title' : null,
            ),
            TextFormField(
              controller: _body,
              maxLength: 2000,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'What happened today?',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Write a reflection' : null,
            ),
            Text('How did today feel? ${_mood.round()}/10'),
            Slider(
              value: _mood,
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_mood.round()}/10',
              onChanged: (v) => setState(() => _mood = v),
            ),
            FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    DemoEntry(
                      id:
                          widget.entry?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      title: _title.text.trim(),
                      body: _body.text.trim(),
                      mood: _mood.round(),
                    ),
                  );
                }
              },
              child: const Text('Save journal'),
            ),
          ],
        ),
      ),
    ),
  );
}
