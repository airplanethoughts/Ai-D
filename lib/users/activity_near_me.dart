import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityNearMePage extends StatefulWidget {
  const ActivityNearMePage({super.key});
  @override
  State<ActivityNearMePage> createState() => _ActivityNearMePageState();
}

class _ActivityNearMePageState extends State<ActivityNearMePage> {
  late final _stream = FirebaseFirestore.instance
      .collection('JackSocialAppAdminPosts')
      .orderBy('date', descending: true)
      .limit(50)
      .snapshots();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Explore activities')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Could not load activities. Check your connection and permissions.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No activities published yet.'));
        }
        return ListView(
          children: [
            for (final doc in snapshot.data!.docs)
              Card(
                child: ListTile(
                  title: Text((doc.data()['title'] ?? 'Activity').toString()),
                  subtitle: Text((doc.data()['content'] ?? '').toString()),
                  isThreeLine: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text(
                            (doc.data()['title'] ?? 'Activity').toString(),
                          ),
                        ),
                        body: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            if ((doc.data()['picURL'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Image.network(
                                doc.data()['picURL'],
                                errorBuilder: (_, _, _) =>
                                    const Text('Image unavailable'),
                              ),
                            SelectableText(
                              (doc.data()['content'] ?? '').toString(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
