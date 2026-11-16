import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jack_social_app_v2/demo/demo_app.dart';
import 'package:jack_social_app_v2/specific_journal.dart';

void main() {
  testWidgets(
    'unreadable journal data is preserved and cannot be overwritten',
    (tester) async {
      final damaged = jsonEncode([
        {'id': 'one', 'title': 'A saved entry', 'body': 'Keep this', 'mood': 6},
        {'id': 'two', 'mood': 'invalid'},
      ]);
      SharedPreferences.setMockInitialValues({'aid-demo-journal-v1': damaged});
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Stored data was not overwritten'),
        findsOneWidget,
      );
      expect(find.text('Write a journal'), findsNothing);
      await tester.tap(find.text('Reflect'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('What took energy today, and what gave some back?'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DemoEditor), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'aid-demo-journal-v1',
        ),
        damaged,
      );
    },
  );

  testWidgets('a reflection prompt opens an editor and saves a real journal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reflect'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('What took energy today, and what gave some back?'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DemoEditor), findsOneWidget);
    expect(
      find.text('What took energy today, and what gave some back?'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'A small reset');
    await tester.enterText(find.byType(TextFormField).at(1), 'A walk helped.');
    await tester.ensureVisible(find.text('Save journal'));
    await tester.tap(find.text('Save journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your Journey'));
    await tester.pumpAndSettle();
    expect(find.text('A small reset'), findsOneWidget);
    expect(find.text('1 saved reflection'), findsOneWidget);
  });

  testWidgets(
    'journal details show mood and text without an empty AI section',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DayDetailScreen(
            date: 'Nov 16, 2026',
            info: {
              'title_for_today': 'A good day',
              'mood_of_the_day': 'Time with a friend.',
              'happiness_level': 8,
              'AI_response': '',
            },
          ),
        ),
      );
      expect(find.text('A good day'), findsOneWidget);
      expect(find.text('Mood · 8/10'), findsOneWidget);
      expect(find.text('Time with a friend.'), findsOneWidget);
      expect(find.text('AI reflection'), findsNothing);
    },
  );

  testWidgets('small screens fit navigation and journal editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write a journal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Mobile reflection',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'A short note.');
    await tester.ensureVisible(find.text('Save journal'));
    await tester.tap(find.text('Save journal'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile reflection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
