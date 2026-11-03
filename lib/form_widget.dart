import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/ai_service.dart';
import 'package:jack_social_app_v2/auth/auth.dart';
import 'package:jack_social_app_v2/main.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  bool userInteracts() =>
      title.trim().isNotEmpty && description.trim().isNotEmpty && !isLoading;
  final database = FirebaseDatabase.instance.ref();
  final storageRef = FirebaseStorage.instance.ref();

  late User user;
  late TextEditingController controller;
  final phoneController = TextEditingController();

  String? photoURL;

  bool showSaveButton = false;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  DateTime date = DateTime.now();
  double maxValue = 0;
  bool? brushedTeeth = false;
  bool enableFeature = false;
  XFile? imageFile;
  final AiService _aiService = AiService();
  StreamSubscription<User?>? _authSubscription;

  @override
  void dispose() {
    _authSubscription?.cancel();
    phoneController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    user = auth.currentUser!;

    _authSubscription = auth.userChanges().listen((event) {
      if (event != null && mounted) {
        setState(() {
          user = event;
        });
      }
    });

    super.initState();
  }

  TextEditingController descriptionController = TextEditingController();

  Future updateYourDay() async {
    // ignore: use_build_context_synchronously
    ScaffoldSnackbar.of(context).show('Your Day has been updated');
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        //textScanning = true;
        imageFile = pickedImage;
        //getRecognisedText(pickedImage);
        setState(() {});
      }
    } catch (e) {
      //textScanning = false;
      imageFile = null;
      //scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  Future<String> uploadTodaysPics(String key) async {
    if (imageFile == null) return "";
    final file = storageRef.child('JackSocialApp/Users/${user.uid}/$key.jpg');
    final bytes = await imageFile!.readAsBytes();
    if (bytes.length >= 5 * 1024 * 1024) {
      throw StateError('Image must be smaller than 5 MB');
    }
    await file.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return file.getDownloadURL();
  }

  Future<String> _handleSubmit(String text) => _aiService.reply([
    {'role': 'user', 'content': text},
  ], mode: 'journal');

  Future<void> _saveJournal() async {
    if (!userInteracts()) return;
    setState(() => isLoading = true);
    try {
      final ref = database.child('users/${user.uid}').push();
      final picURL = await uploadTodaysPics(ref.key!);
      await ref.set({
        'date': date.millisecondsSinceEpoch,
        'title_for_today': title.trim(),
        'mood_of_the_day': description.trim(),
        'happiness_level': maxValue,
        'picURL': picURL,
        'AI_response': '',
      });
      String response = '';
      try {
        response = await _handleSubmit(description.trim());
        await ref.child('AI_response').set(response);
      } catch (_) {
        // The journal is already saved: optional AI must never block reflection.
      }
      if (!mounted) return;
      ScaffoldSnackbar.of(context).show(
        response.isEmpty
            ? 'Journal saved. AI reflection is unavailable right now.'
            : 'Journal saved.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldSnackbar.of(
          context,
        ).show('Could not save. Your text is still here; please retry.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stories of your day")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Scrollbar(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Card(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...[
                              TextFormField(
                                decoration: const InputDecoration(
                                  filled: true,
                                  hintText: 'Reason...',
                                  labelText: 'Rate today /10',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    setState(() => title = value);
                                  });
                                },
                              ),
                              TextFormField(
                                //controller: descriptionController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  hintText:
                                      'Write anything that happened today in 200 words...',
                                  labelText: 'Mood for the day',
                                  counterText:
                                      "Word count: ${200 - description.length} ",
                                  // counter:
                                  //     Text("${descriptionController.text.length}"),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    setState(() => description = value);
                                  });
                                },
                                maxLines: 5,
                                maxLength: 200,
                              ),
                              _FormDatePicker(
                                date: date,
                                onChanged: (value) {
                                  setState(() {
                                    date = value;
                                  });
                                },
                              ),
                              Center(
                                child: SingleChildScrollView(
                                  child: Container(
                                    margin: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        //if (textScanning) const CircularProgressIndicator(),
                                        if (imageFile ==
                                            null) //!textScanning &&
                                          Container(
                                            width: 300,
                                            height: 300,
                                            color: Colors.grey[300]!,
                                          ),
                                        if (imageFile != null)
                                          FutureBuilder<Uint8List>(
                                            future: imageFile!.readAsBytes(),
                                            builder: (context, snapshot) =>
                                                snapshot.hasData
                                                ? Image.memory(snapshot.data!)
                                                : const SizedBox(height: 80),
                                          ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.grey,
                                                  shadowColor: Colors.grey[400],
                                                  elevation: 10,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  getImage(ImageSource.gallery);
                                                },
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 5,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.image,
                                                        size: 30,
                                                      ),
                                                      Text(
                                                        "Gallery",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.grey,
                                                  shadowColor: Colors.grey[400],
                                                  elevation: 10,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  getImage(ImageSource.camera);
                                                },
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 5,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.camera_alt,
                                                        size: 30,
                                                      ),
                                                      Text(
                                                        "Camera",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Happiness Level',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    intl.NumberFormat.currency(
                                      symbol: "",
                                      decimalDigits: 0,
                                    ).format(maxValue),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Slider(
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    value: maxValue,
                                    onChanged: (value) {
                                      setState(() {
                                        maxValue = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ].expand(
                              (widget) => [widget, const SizedBox(height: 24)],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: userInteracts() ? _saveJournal : null,
              child: const Text("Update your Diary Now!"),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormDatePicker extends StatefulWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _FormDatePicker({required this.date, required this.onChanged});

  @override
  State<_FormDatePicker> createState() => _FormDatePickerState();
}

class _FormDatePickerState extends State<_FormDatePicker> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Date', style: Theme.of(context).textTheme.bodyLarge),
            Text(
              intl.DateFormat.yMd().format(widget.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        TextButton(
          child: const Text('Edit'),
          onPressed: () async {
            var newDate = await showDatePicker(
              context: context,
              initialDate: widget.date,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );

            // Don't change the date if the date picker returns null.
            if (newDate == null) {
              return;
            }

            widget.onChanged(newDate);
          },
        ),
      ],
    );
  }
}
