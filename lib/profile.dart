import 'package:flutter/material.dart';
import 'main.dart';
import 'form_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _name = TextEditingController(
    text: auth.currentUser?.displayName ?? '',
  );
  bool _busy = false;
  String? _status;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await auth.currentUser!.updateDisplayName(_name.text.trim());
      if (mounted) setState(() => _status = 'Name updated.');
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not update your name. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await auth.signOut();
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'Could not sign out. Try again.';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your profile')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(auth.currentUser?.email ?? 'Signed-in account'),
        TextField(
          controller: _name,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Display name'),
          enabled: !_busy,
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save name'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const FormPage())),
          child: const Text('Write a journal'),
        ),
        TextButton(
          onPressed: _busy ? null : _signOut,
          child: const Text('Sign out'),
        ),
        if (_status != null) Text(_status!),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
