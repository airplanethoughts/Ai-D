import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_social_app_v2/chat_page.dart';
import 'package:jack_social_app_v2/deployment_features.dart';
import 'package:jack_social_app_v2/services/ai_service.dart';
import 'package:jack_social_app_v2/users/gpt_summary.dart';

void main() {
  const freeBuild = !DeploymentFeatures.aiEnabled;
  test('disabled AI never sends a request', () async {
    var calls = 0;
    final service = AiService(
      send: (_, _) async {
        calls++;
        return 'unexpected';
      },
    );
    await expectLater(
      service.reply([
        {'role': 'user', 'content': 'test'},
      ]),
      throwsA(isA<AiServiceException>()),
    );
    expect(calls, 0);
  }, skip: !freeBuild);
  testWidgets('free build offers written prompts and no chat composer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GPTSummaryScreen()));
    expect(
      find.text('Self-reflection · written prompts, not AI-generated'),
      findsOneWidget,
    );
    expect(
      find.text('What gave you a little energy today, and what drained it?'),
      findsOneWidget,
    );
    await tester.tap(find.text('New prompt'));
    await tester.pump();
    expect(
      find.text(
        'What is one small thing you would like to do differently tomorrow?',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('AI chat is not enabled'), findsOneWidget);
  }, skip: !freeBuild);
}
