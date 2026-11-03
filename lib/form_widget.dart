import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'services/ai_service.dart';
import 'deployment_features.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(), _body = TextEditingController();
  Uint8List? _image;
  double _mood = 5;
  bool _busy = false, _requestAi = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (!DeploymentFeatures.uploadsEnabled) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length >= 5 * 1024 * 1024) throw StateError('Image too large');
      if (mounted) {
        setState(() {
          _image = bytes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Choose an image smaller than 5 MB.');
      }
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    bool saved = false;
    Reference? upload;
    try {
      final uid = auth.currentUser!.uid;
      final entry = FirebaseDatabase.instance.ref('users/$uid').push();
      String picURL = '';
      if (DeploymentFeatures.uploadsEnabled && _image != null) {
        upload = FirebaseStorage.instance.ref(
          'JackSocialApp/Users/$uid/${entry.key}.jpg',
        );
        await upload.putData(
          _image!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        picURL = await upload.getDownloadURL();
      }
      await entry.set({
        'date': DateTime.now().millisecondsSinceEpoch,
        'title_for_today': _title.text.trim(),
        'mood_of_the_day': _body.text.trim(),
        'happiness_level': _mood,
        'picURL': picURL,
        'AI_response': '',
      });
      saved = true;
      bool aiSucceeded = false;
      if (DeploymentFeatures.aiEnabled && _requestAi) {
        try {
          final reply = await AiService().reply([
            {'role': 'user', 'content': _body.text.trim()},
          ], mode: 'journal');
          await entry.child('AI_response').set(reply);
          aiSucceeded = true;
        } catch (_) {
          /* The journal is already saved; AI is optional. */
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _requestAi && !aiSucceeded
                ? 'Journal saved. AI reflection is unavailable right now.'
                : 'Journal saved.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!saved && upload != null) {
        try {
          await upload.delete();
        } catch (_) {
          /* Retryable orphan cleanup. */
        }
      }
      if (mounted) {
        setState(
          () =>
              _error = 'Could not save. Your text is still here; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Write a journal')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              enabled: !_busy,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Add a title' : null,
            ),
            TextFormField(
              controller: _body,
              enabled: !_busy,
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
              onChanged: _busy ? null : (v) => setState(() => _mood = v),
            ),
            if (_image != null) Image.memory(_image!, height: 180),
            if (DeploymentFeatures.uploadsEnabled)
              TextButton(
                onPressed: _busy ? null : _pick,
                child: const Text('Choose optional image'),
              ),
            if (_image != null)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _image = null),
                child: const Text('Remove image'),
              ),
            if (!DeploymentFeatures.uploadsEnabled)
              const Text(
                'Photo uploads are not enabled in this deployment. Your text journal saves normally.',
              ),
            if (DeploymentFeatures.aiEnabled)
              CheckboxListTile(
                value: _requestAi,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _requestAi = v ?? false),
                title: const Text('Request an AI reflection'),
                subtitle: const Text(
                  'Sends this reflection to your configured AI server and provider. Your journal saves first.',
                ),
              ),
            if (_error != null) Text(_error!),
            if (_busy) const LinearProgressIndicator(),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save journal'),
            ),
          ],
        ),
      ),
    ),
  );
}
