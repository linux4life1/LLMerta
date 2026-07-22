import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/game_table/game_table.dart';

void main() {
  DecisionContext ctx({int seat = 0}) => DecisionContext(
    seat: seat,
    role: Role.villager,
    day: 1,
    visibleEvents: const [],
    livingSeats: const [0, 1, 2],
  );

  test('text actions roundtrip through the request stream', () async {
    final controller = UiHumanController();
    addTearDown(controller.dispose);
    final seen = <HumanRequest?>[];
    controller.requests.listen(seen.add);

    final future = controller.speak(ctx());
    await Future<void>.delayed(Duration.zero);
    expect(controller.current?.kind, HumanActionKind.speak);
    expect(controller.current?.wantsText, isTrue);

    controller.current!.submitText('I was home all night.');
    expect(await future, 'I was home all night.');
    expect(controller.current, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, isNull);
  });

  test('choice actions carry targets and accept null where legal', () async {
    final controller = UiHumanController();
    addTearDown(controller.dispose);

    final voteFuture = controller.vote(ctx(), [1, 2]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.current?.targets, [1, 2]);
    expect(controller.current?.mustChoose, isFalse);
    controller.current!.submitChoice(null);
    expect(await voteFuture, isNull);

    final protectFuture = controller.doctorProtect(ctx(), [0, 1, 2]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.current?.kind, HumanActionKind.doctorProtect);
    expect(controller.current?.mustChoose, isTrue);
    controller.current!.submitChoice(2);
    expect(await protectFuture, 2);
  });

  test('every action kind maps through', () async {
    final controller = UiHumanController();
    addTearDown(controller.dispose);
    Future<void> roundtrip(
      Future<Object?> future,
      HumanActionKind kind,
      Object? answer,
    ) async {
      await Future<void>.delayed(Duration.zero);
      expect(controller.current?.kind, kind);
      if (answer is String) {
        controller.current!.submitText(answer);
      } else {
        controller.current!.submitChoice(answer as int?);
      }
      await future;
    }

    await roundtrip(controller.defend(ctx()), HumanActionKind.defend, 'no');
    await roundtrip(
      controller.lastWords(ctx()),
      HumanActionKind.lastWords,
      'remember me',
    );
    await roundtrip(
      controller.nominate(ctx(), [1]),
      HumanActionKind.nominate,
      1,
    );
    await roundtrip(
      controller.mafiaChat(ctx()),
      HumanActionKind.mafiaChat,
      'strike at dawn',
    );
    await roundtrip(
      controller.mafiaKillVote(ctx(), [2]),
      HumanActionKind.mafiaKillVote,
      2,
    );
    await roundtrip(
      controller.sheriffInvestigate(ctx(), [1, 2]),
      HumanActionKind.sheriffInvestigate,
      1,
    );
    await roundtrip(
      controller.assassinShoot(ctx(), [1, 2]),
      HumanActionKind.assassinShoot,
      null,
    );
  });
}
