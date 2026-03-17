import 'package:excuse_me/main.dart';
import 'package:excuse_me/models/alibi_style.dart';
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
      excuse: 'A raccoon sabotaged the tram schedule.',
      detectedLanguage: 'en',
      style: style.apiValue,
    );
  }
}

void main() {
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

  testWidgets('generation renders returned excuse', (tester) async {
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
    expect(api.lastStyle, AlibiStyle.goofy);
  });

  testWidgets('wall tab renders streamed posts', (tester) async {
    final wallService = WallService(
      postsStreamFactory: () => Stream.value(
        [
          const WallPost(
            id: '1',
            truth: 'I overslept.',
            excuse: 'A raccoon sabotaged the tram schedule.',
            style: 'goofy',
            language: 'en',
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
        ),
      ),
    );

    await tester.tap(find.text('Wall of Shame'));
    await tester.pumpAndSettle();

    expect(find.text('A raccoon sabotaged the tram schedule.'), findsOneWidget);
    expect(find.text('😂 4'), findsOneWidget);
    expect(find.text('🔥 2'), findsOneWidget);
    expect(find.text('💀 1'), findsOneWidget);
  });
}
