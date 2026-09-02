import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/screens/chat_screen.dart';
import 'package:poppylo/screens/matches_screen.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/chat_api.dart';
import 'package:poppylo/state/profile_controller.dart';

import '../support/fake_chat_api.dart';
import '../support/fake_profile_api.dart';
import '../support/mock_network_images.dart';

GoRouter _router(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME')),
        GoRoute(
          path: '/chats',
          builder: (_, __) => const MatchesScreen(),
        ),
        GoRoute(
          path: '/chat/:matchId',
          builder: (_, s) => ChatScreen(matchId: s.pathParameters['matchId']!),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester t, {
  required String initial,
  required FakeChatApi chat,
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        chatApiProvider.overrideWithValue(chat),
        meProvider.overrideWith((ref) async => sampleUserMe()), // id: 'u1'
      ],
      child: MaterialApp.router(routerConfig: _router(initial)),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() => HttpOverrides.global = MockNetworkImagesHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  testWidgets('empty chat shows the friendly empty state', (t) async {
    final chat = FakeChatApi(messages: []);
    await _pump(t, initial: '/chat/m1', chat: chat);

    expect(find.text('Start the conversation ☕'), findsOneWidget);
    expect(
      find.text('Say hello and make your coffee meet a little easier.'),
      findsOneWidget,
    );
    expect(chat.markReadCalls, greaterThanOrEqualTo(1)); // read on open

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('renders messages with correct sender alignment', (t) async {
    final chat = FakeChatApi(messages: [
      msg(id: '1', senderId: 'u2', text: 'Hi from Ben'),
      msg(id: '2', senderId: 'u1', text: 'Hey Ben'),
    ]);
    await _pump(t, initial: '/chat/m1', chat: chat);
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Hi from Ben'), findsOneWidget);
    expect(find.text('Hey Ben'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget); // header = participant name

    // mine (u1) is inside a primary-coloured bubble aligned right
    final mineBubble = t.widget<Container>(
      find
          .ancestor(of: find.text('Hey Ben'), matching: find.byType(Container))
          .first,
    );
    final theirsBubble = t.widget<Container>(
      find
          .ancestor(
              of: find.text('Hi from Ben'), matching: find.byType(Container))
          .first,
    );
    final mineColor = (mineBubble.decoration as BoxDecoration).color;
    final theirsColor = (theirsBubble.decoration as BoxDecoration).color;
    expect(mineColor, isNot(equals(theirsColor)));

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('sending a message calls the API and clears the input',
      (t) async {
    final chat = FakeChatApi(messages: []);
    await _pump(t, initial: '/chat/m1', chat: chat);

    await t.enterText(find.byType(TextField), 'See you Saturday!');
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_upward));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    expect(chat.sentTexts, ['See you Saturday!']);
    expect(find.text('See you Saturday!'), findsOneWidget); // in the list
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('403 shows the locked message', (t) async {
    final chat = FakeChatApi()..getError = ApiException(403, 'locked');
    await _pump(t, initial: '/chat/m1', chat: chat);

    expect(
      find.textContaining(
          'Chat becomes available once your match is confirmed'),
      findsOneWidget,
    );

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('network error while sending does not crash', (t) async {
    final chat = FakeChatApi(messages: [])
      ..sendError = ApiException(0, 'offline');
    await _pump(t, initial: '/chat/m1', chat: chat);

    await t.enterText(find.byType(TextField), 'hello?');
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_upward));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    // the optimistic message stays visible marked "Not sent", app still alive
    expect(find.text('hello?'), findsWidgets);
    expect(find.textContaining('Not sent'), findsOneWidget);
    expect(tester_takeException(t), isNull);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a failed message retries the send', (t) async {
    final chat = FakeChatApi(messages: [])
      ..sendError = ApiException(0, 'offline');
    await _pump(t, initial: '/chat/m1', chat: chat);

    await t.enterText(find.byType(TextField), 'retry me');
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_upward));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Not sent'), findsOneWidget);

    // Clear the field so the only "retry me" left is the failed bubble.
    await t.enterText(find.byType(TextField), '');
    await t.pump();

    // Recover, then tap the failed bubble → it re-sends and is accepted.
    chat.sendError = null;
    await t.tap(find.text('retry me'));
    await t.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Not sent'), findsNothing);
    expect(find.text('retry me'), findsOneWidget);
    expect(tester_takeException(t), isNull);

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Chats tab lists conversations and opens one', (t) async {
    final chat = FakeChatApi(
      chatList: [
        ChatSummary(
          chatId: 'c1',
          matchId: 'm7',
          participant: sampleParticipant(name: 'Priya'),
          lastMessage: 'See you tomorrow!',
          lastMessageAt: DateTime.now(),
          unreadCount: 2,
        ),
      ],
    );
    await _pump(t, initial: '/chats', chat: chat);

    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('See you tomorrow!'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // unread badge

    await t.tap(find.text('Priya'));
    await t.pumpAndSettle();
    // opened the chat screen for m7
    expect(find.byType(TextField), findsOneWidget);
  });
}

Object? tester_takeException(WidgetTester t) => t.takeException();
