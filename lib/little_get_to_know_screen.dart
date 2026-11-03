import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart';

class LittleGetToKnowScreen extends StatefulWidget {
  const LittleGetToKnowScreen({super.key});
  @override
  State<LittleGetToKnowScreen> createState() => _LittleGetToKnowScreenState();
}

class _LittleGetToKnowScreenState extends State<LittleGetToKnowScreen> {
  final _note = TextEditingController();
  double _mood = 5;
  bool _busy = false;
  String? _status;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _note.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await FirebaseDatabase.instance
          .ref('users/${auth.currentUser!.uid}')
          .push()
          .set({
            'date': DateTime.now().millisecondsSinceEpoch,
            'title_for_today': 'Personal check-in',
            'mood_of_the_day': _note.text.trim(),
            'happiness_level': _mood,
            'picURL': '',
            'AI_response': '',
          });
      if (mounted) {
        setState(() {
          _status = 'Check-in saved in Your Journey.';
          _note.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not save. Your note is still here.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personal check-in')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'How are meals, rest, friendships and your goals feeling today?',
        ),
        TextField(
          controller: _note,
          maxLength: 2000,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Your check-in'),
        ),
        Text('How do you feel? ${_mood.round()}/10'),
        Slider(
          value: _mood,
          min: 0,
          max: 10,
          divisions: 10,
          onChanged: _busy ? null : (v) => setState(() => _mood = v),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save check-in'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_status != null) Text(_status!),
      ],
    ),
  );
}
