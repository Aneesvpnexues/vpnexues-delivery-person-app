import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/core/session_lifecycle.dart';
import 'package:vpnexues_partner/state/app_state.dart';

import 'fakes.dart';

class RecordingAppState extends AppState {
  RecordingAppState(super.api);

  int resumeCalls = 0;

  @override
  Future<void> resumeSession() async {
    resumeCalls++;
  }
}

void main() {
  testWidgets('app resume triggers session validation through the lifecycle observer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = RecordingAppState(
      ApiClient(prefs, vault: MemoryVault()),
    );

    await tester.pumpWidget(
      SessionLifecycle(state: state, child: const SizedBox.shrink()),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(state.resumeCalls, 1);
  });
}
