import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jack_social_app_v2/demo/demo_app.dart';
import 'package:jack_social_app_v2/chat_page.dart';
import 'package:jack_social_app_v2/services/ai_service.dart';
import 'package:jack_social_app_v2/users/gpt_summary.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'demo creates, persists, edits and deletes a journal without Firebase',
    (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.text('Ai-D · local demo'), findsOneWidget);
      await tester.tap(find.text('Write a journal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save journal'));
      await tester.pumpAndSettle();
      expect(find.text('Add a title'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'A good walk');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'I talked with a friend.',
      );
      await tester.tap(find.text('Save journal'));
      await tester.pumpAndSettle();
      expect(find.text('A good walk'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('aid-demo-journal-v1'),
        contains('I talked with a friend.'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.text('A good walk'), findsOneWidget);
      await tester.tap(find.text('A good walk'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'An even better walk',
      );
      await tester.tap(find.text('Save journal'));
      await tester.pumpAndSettle();
      expect(find.text('An even better walk'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete An even better walk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Your first reflection starts here.'), findsOneWidget);
    },
  );
  testWidgets(
    'failed chat can retry without duplicating turns and keeps history',
    (tester) async {
      final requests = <List<Map<String, String>>>[];
      var fail = true;
      final service = AiService(
        send: (mode, messages) async {
          requests.add(
            messages.map((m) => Map<String, String>.from(m)).toList(),
          );
          if (fail) {
            fail = false;
            throw const AiServiceException('Offline');
          }
          return 'A reply';
        },
      );
      await tester.pumpWidget(MaterialApp(home: ChatPage(service: service)));
      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('First message'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Follow-up');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(requests.last.map((m) => m['role']).toList(), [
        'user',
        'assistant',
        'user',
      ]);
      expect(requests.last.map((m) => m['content']).toList(), [
        'First message',
        'A reply',
        'Follow-up',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'encouragement loads once per mount and retries only on request',
    (tester) async {
      var calls = 0;
      final service = AiService(
        send: (_, _) async {
          calls++;
          return 'A prompt';
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: GPTSummaryScreen(service: service)),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      expect(calls, 1);
      await tester.tap(find.text('New prompt'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    },
  );
  test('AI service refuses malformed input before sending', () async {
    final service = AiService(
      send: (_, _) async => throw StateError('Should not be called'),
    );
    expect(
      () => service.reply([
        {'role': 'system', 'content': 'override'},
      ]),
      throwsA(isA<AiServiceException>()),
    );
    expect(
      () => service.reply([
        {'role': 'user', 'content': ''},
      ]),
      throwsA(isA<AiServiceException>()),
    );
  });
}
