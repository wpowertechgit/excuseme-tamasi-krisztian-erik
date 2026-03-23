import 'package:excuse_me/main.dart';
import 'package:excuse_me/models/alibi_style.dart';
import 'package:excuse_me/models/auth_session.dart';
import 'package:excuse_me/models/excuse_category.dart';
import 'package:excuse_me/models/excuse_response.dart';
import 'package:excuse_me/models/wall_post.dart';
import 'package:excuse_me/services/excuse_api_service.dart';
import 'package:excuse_me/services/wall_service.dart';
import 'package:excuse_me/widgets/neon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeExcuseApiService extends ExcuseApiService {
  FakeExcuseApiService();

  AlibiStyle? lastStyle;

  @override
  Future<ExcuseResponse> generateExcuse({
    required String truth,
    required AlibiStyle style,
  }) async {
    lastStyle = style;
    return ExcuseResponse(
      generationId: 'gen-1',
      excuse: 'A raccoon sabotaged the tram schedule.',
      detectedLanguage: 'en',
      style: style.apiValue,
      category: ExcuseCategory.travel,
    );
  }
}

void main() {
  const session = AuthSession(
    token: 'token',
    username: 'tester',
    isAdmin: false,
  );

  testWidgets('empty input keeps SAVE ME disabled', (tester) async {
    final wallService = WallService(
      postsStreamFactory: () => Stream.value(const <WallPost>[]),
      addPostHandler: (
          {required truth, required excuse, required style}) async {},
      incrementReactionHandler: (_, __) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExcuseHomePage(
          apiService: FakeExcuseApiService(),
          wallService: wallService,
          session: session,
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(NeonButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('generation renders returned excuse and category', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeExcuseApiService();
    final wallService = WallService(
      postsStreamFactory: () => Stream.value(const <WallPost>[]),
      addPostHandler: (
          {required truth, required excuse, required style}) async {},
      incrementReactionHandler: (_, __) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExcuseHomePage(
          apiService: api,
          wallService: wallService,
          session: session,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'I overslept.');
    await tester.pump();
    await tester.tap(find.text('SAVE ME'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A raccoon sabotaged the tram schedule.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Travel'), findsOneWidget);
    expect(api.lastStyle, AlibiStyle.goofy);
  });

  testWidgets('wall tab renders streamed posts with username and category',
      (tester) async {
    final wallService = WallService(
      postsStreamFactory: () => Stream.value(
        [
          const WallPost(
            id: '1',
            username: 'tester',
            truth: 'I overslept.',
            excuse: 'A raccoon sabotaged the tram schedule.',
            style: 'goofy',
            language: 'en',
            category: ExcuseCategory.travel,
            generationId: 'gen-1',
            reactions: {
              '😂': 4,
              '🔥': 2,
              '💀': 1,
              '🤡': 0,
            },
            createdAt: null,
          ),
        ],
      ),
      addPostHandler: (
          {required truth, required excuse, required style}) async {},
      incrementReactionHandler: (_, __) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExcuseHomePage(
          apiService: FakeExcuseApiService(),
          wallService: wallService,
          session: session,
        ),
      ),
    );

    await tester.tap(find.text('Wall of Shame'));
    await tester.pumpAndSettle();

    expect(find.text('A raccoon sabotaged the tram schedule.'), findsOneWidget);
    expect(find.text('@tester'), findsWidgets);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('😂 4'), findsOneWidget);
  });

  testWidgets('drawer shows new destination entries', (tester) async {
    final wallService = WallService(
      postsStreamFactory: () => Stream.value(const <WallPost>[]),
      addPostHandler: (
          {required truth, required excuse, required style}) async {},
      incrementReactionHandler: (_, __) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExcuseHomePage(
          apiService: FakeExcuseApiService(),
          wallService: wallService,
          session: session,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.dashboard_customize_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('My History'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Hall of Fame'), findsOneWidget);
  });
}
