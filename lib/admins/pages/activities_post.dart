import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';

class AdminActivitiesPostPage extends StatefulWidget {
  const AdminActivitiesPostPage({super.key});
  @override
  State<AdminActivitiesPostPage> createState() =>
      _AdminActivitiesPostPageState();
}

class _AdminActivitiesPostPageState extends State<AdminActivitiesPostPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(), _body = TextEditingController();
  Uint8List? _image;
  bool _busy = false;
  String? _status;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
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
          _status = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Choose an image smaller than 5 MB.');
      }
    }
  }

  Future<void> _publish() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final uid = auth.currentUser!.uid;
      final ref = FirebaseFirestore.instance
          .collection('JackSocialAppAdminPosts')
          .doc();
      String url = '';
      if (_image != null) {
        final file = FirebaseStorage.instance.ref(
          'activities/$uid/${ref.id}.jpg',
        );
        await file.putData(
          _image!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        url = await file.getDownloadURL();
      }
      await ref.set({
        'title': _title.text.trim(),
        'content': _body.text.trim(),
        'picURL': url,
        'postOwner': uid,
        'date': DateTime.now().millisecondsSinceEpoch,
        'likes': 0,
        'comments': <String>[],
      });
      if (mounted) {
        setState(() {
          _status = 'Activity published.';
          _title.clear();
          _body.clear();
          _image = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Could not publish. Check your connection and administrator permissions.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Publish an activity')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Activity title'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Add a title' : null,
            ),
            TextFormField(
              controller: _body,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Add a description' : null,
            ),
            if (_image != null) Image.memory(_image!, height: 180),
            TextButton(
              onPressed: _busy ? null : _pick,
              child: const Text('Choose optional image'),
            ),
            FilledButton(
              onPressed: _busy ? null : _publish,
              child: const Text('Publish activity'),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    ),
  );
}
