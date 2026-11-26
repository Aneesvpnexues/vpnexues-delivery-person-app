import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/screens/sos_screen.dart';
import 'package:vpnexues_partner/state/app_state.dart';

/// The SOS hold button used to be driven by a GestureDetector: because it sits
/// inside a SingleChildScrollView, any finger movement past the ~18px touch
/// slop rejected the tap, fired onTapCancel and silently killed the hold — the
/// countdown reset and *no* haptic ever fired. On top of that, once an alert
/// had been sent `_sent` stayed true forever, so every later press did
/// nothing. These tests pin down the replacement behaviour.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> haptics;

  Future<void> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(ApiClient(prefs));

    haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          // HapticFeedback.vibrate() sends no payload; the impacts send a
          // HapticFeedbackType.* string.
          haptics.add(call.arguments?.toString() ?? 'vibrate');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    // The screen loads contacts from the network, which is unavailable (and
    // intentionally noisy) inside a test.
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('HTTP_') ||
          msg.contains('SocketException') ||
          msg.contains('ClientException') ||
          msg.contains('Request failed')) {
        return;
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    await tester.pumpWidget(MaterialApp(home: SosScreen(state: state)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Offset sosCenter(WidgetTester tester) => tester.getCenter(find.text('SOS'));

  int count(String haptic) => haptics.where((h) => h == haptic).length;

  /// Presses the SOS button and renders the frame the hold starts on. A ticker
  /// reports zero elapsed time on its first frame, so that frame has to be
  /// consumed before the countdown durations below are meaningful.
  Future<TestGesture> pressSos(WidgetTester tester) async {
    final gesture = await tester.startGesture(sosCenter(tester));
    await tester.pump();
    return gesture;
  }

  testWidgets('hold ticks a haptic on touch-down and per countdown second',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Hold 3 seconds'), findsOneWidget);

    final gesture = await pressSos(tester);

    // Feedback on touch-down, plus the "Sending in 3…" label.
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
    expect(find.text('Sending in 3…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Sending in 2…'), findsOneWidget);
    expect(count('HapticFeedbackType.mediumImpact'), greaterThanOrEqualTo(1));

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Sending in 1…'), findsOneWidget);
    expect(count('HapticFeedbackType.mediumImpact'), greaterThanOrEqualTo(2));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hold 3 seconds'), findsOneWidget);
  });

  testWidgets('a sideways finger wiggle does not cancel the hold',
      (tester) async {
    await pumpScreen(tester);

    final gesture = await pressSos(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // 30px of horizontal jitter used to reject the tap outright.
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 400));

    // 1200ms in: still holding, counting down, ticking along.
    expect(find.text('Sending in 2…'), findsOneWidget);
    expect(count('HapticFeedbackType.mediumImpact'), greaterThanOrEqualTo(1));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hold 3 seconds'), findsOneWidget);
  });

  testWidgets('a completed hold fires the trigger pattern and the button can '
      'be used again', (tester) async {
    await pumpScreen(tester);

    final gesture = await pressSos(tester);
    await tester.pump(const Duration(seconds: 3));
    // The trigger pattern is paced with 120ms gaps — give it time to play out.
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      count('HapticFeedbackType.heavyImpact'),
      greaterThanOrEqualTo(2),
    );
    expect(haptics, contains('vibrate'));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // The POST fails inside a test, so the screen either armed itself again
    // (sent state + "start a new alert") or fell back to idle.
    final rearm = find.text('START A NEW ALERT');
    if (rearm.evaluate().isNotEmpty) {
      await tester.tap(rearm);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Hold 3 seconds'), findsOneWidget);

    // The regression: `_sent` used to stay true forever, so a second press
    // silently did nothing — no countdown, no haptics.
    final second = await pressSos(tester);

    expect(find.text('Sending in 3…'), findsOneWidget);
    expect(count('HapticFeedbackType.lightImpact'), greaterThanOrEqualTo(2));

    await second.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hold 3 seconds'), findsOneWidget);
  });
}
