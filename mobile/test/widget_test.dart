import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/core/format.dart';
import 'package:vpnexues_partner/l10n/generated/app_localizations.dart';
import 'package:vpnexues_partner/screens/login_screen.dart';
import 'package:vpnexues_partner/state/app_state.dart';
import 'package:vpnexues_partner/ui/theme.dart';

void main() {
  test('money formats paise as rupees', () {
    expect(money(25000), '₹250');
    expect(money(8300), '₹83');
    expect(money(1234), '₹12.34');
  });

  test('status labels are human friendly', () {
    expect(statusLabel('at_pickup'), 'At pickup');
    expect(statusLabel('in_review'), 'In review');
    expect(statusLabel('something_new'), 'something new');
  });

  test('initials take first and last name', () {
    expect(initials('Demo Partner'), 'DP');
    expect(initials('Anees'), 'A');
  });

  testWidgets('login screen renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(ApiClient(prefs));

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginScreen(state: state),
    ));

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
  });
}
