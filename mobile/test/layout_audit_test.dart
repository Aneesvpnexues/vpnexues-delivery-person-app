import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vpnexues_partner/core/api_client.dart';
import 'package:vpnexues_partner/l10n/generated/app_localizations.dart';
import 'package:vpnexues_partner/screens/about_screen.dart';
import 'package:vpnexues_partner/screens/add_payout_screen.dart';
import 'package:vpnexues_partner/screens/bank_screen.dart';
import 'package:vpnexues_partner/screens/delivered_screen.dart';
import 'package:vpnexues_partner/screens/docs_screen.dart';
import 'package:vpnexues_partner/screens/document_upload_screen.dart';
import 'package:vpnexues_partner/screens/handover_screen.dart';
import 'package:vpnexues_partner/screens/home_shell.dart';
import 'package:vpnexues_partner/screens/home_tab.dart';
import 'package:vpnexues_partner/screens/login_screen.dart';
import 'package:vpnexues_partner/screens/money_tab.dart';
import 'package:vpnexues_partner/screens/notifications_screen.dart';
import 'package:vpnexues_partner/screens/order_detail_screen.dart';
import 'package:vpnexues_partner/screens/orders_tab.dart';
import 'package:vpnexues_partner/screens/otp_screen.dart';
import 'package:vpnexues_partner/screens/personal_info_screen.dart';
import 'package:vpnexues_partner/screens/pickup_qr_screen.dart';
import 'package:vpnexues_partner/screens/profile_tab.dart';
import 'package:vpnexues_partner/screens/reset_password_screen.dart';
import 'package:vpnexues_partner/screens/root_gate.dart';
import 'package:vpnexues_partner/screens/settings_screen.dart';
import 'package:vpnexues_partner/screens/set_password_screen.dart';
import 'package:vpnexues_partner/screens/signup_screen.dart';
import 'package:vpnexues_partner/screens/sos_screen.dart';
import 'package:vpnexues_partner/screens/support_screen.dart';
import 'package:vpnexues_partner/screens/transactions_screen.dart';
import 'package:vpnexues_partner/screens/trip_screen.dart';
import 'package:vpnexues_partner/screens/upload_docs.dart';
import 'package:vpnexues_partner/screens/vehicle_screen.dart';
import 'package:vpnexues_partner/screens/zone_screen.dart';
import 'package:vpnexues_partner/state/app_state.dart';
import 'package:vpnexues_partner/ui/design.dart';

const double _w = kDesignW;
const double _h = kDesignH;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('layout audit across all screens', (tester) async {
    // flutter_test defaults to the Ahem font (every glyph is a square em),
    // which doubles horizontal text metrics vs the real Inter font and
    // creates false positives. Load the real Inter faces first.
    await tester.runAsync(() async {
      for (final f in [
        'Inter-Regular',
        'Inter-Medium',
        'Inter-SemiBold',
        'Inter-Bold',
        'Inter-ExtraBold',
        'Inter-Black',
      ]) {
        final bytes = await File('assets/fonts/$f.ttf').readAsBytes();
        final loader = FontLoader('Inter')
          ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(ApiClient(prefs));
    state.partner = <String, dynamic>{
      'id': 'prt_demo',
      'fullName': 'Anees Rahman',
      'phone': '9876543210',
      'email': 'anees@example.com',
      'rating': 4.8,
      'isOnline': true,
      'kycStatus': 'approved',
      'language': 'en',
      'zoneName': 'Kozhikode',
      'cityName': 'Kozhikode',
    };
    state.unread = 3;

    void onOpenTab(int tab) {}

    final cases = <String, Widget Function(AppState)>{
      'SplashScreen': (s) => SplashScreen(state: s),
      'LoginScreen': (s) => LoginScreen(state: s),
      'SignupScreen': (s) => SignupScreen(state: s),
      'OtpScreen': (s) => OtpScreen(state: s, phone: '9876543210', purpose: 'login'),
      'SetPasswordScreen': (s) => SetPasswordScreen(state: s),
      'SetPasswordScreen.fromSettings': (s) => SetPasswordScreen(state: s, fromSettings: true),
      'UploadDocsScreen': (s) => UploadDocsScreen(state: s),
      'ResetPasswordScreen': (s) => ResetPasswordScreen(state: s),
      'HomeShell': (s) => HomeShell(state: s),
      'HomeTab': (s) => HomeTab(state: s, onOpenTab: onOpenTab),
      'OrdersTab': (s) => OrdersTab(state: s, onOpenTab: onOpenTab),
      'MoneyTab': (s) => MoneyTab(state: s, onOpenTab: onOpenTab),
      'ProfileTab': (s) => ProfileTab(state: s, onOpenTab: onOpenTab),
      'OrderDetailScreen': (s) => OrderDetailScreen(state: s, orderId: 'ord_demo'),
      'PickupQrScreen': (s) => PickupQrScreen(state: s, orderId: 'ord_demo'),
      'TripScreen': (s) => TripScreen(state: s, orderId: 'ord_demo'),
      'HandOverScreen': (s) => HandOverScreen(state: s, orderId: 'ord_demo'),
      'DeliveredScreen': (s) => DeliveredScreen(state: s, orderId: 'ord_demo'),
      'TransactionsScreen': (s) => TransactionsScreen(state: s),
      'PersonalInfoScreen': (s) => PersonalInfoScreen(state: s),
      'BankScreen': (s) => BankScreen(state: s),
      'AddPayoutScreen.bank': (s) => AddPayoutScreen(state: s, mode: 'bank'),
      'AddPayoutScreen.upi': (s) => AddPayoutScreen(state: s, mode: 'upi'),
      'DocsScreen': (s) => DocsScreen(state: s),
      'DocumentUploadScreen': (s) => DocumentUploadScreen(state: s, type: 'selfie'),
      'NotificationsScreen': (s) => NotificationsScreen(state: s),
      'SettingsScreen': (s) => SettingsScreen(state: s),
      'LanguageScreen': (s) => LanguageScreen(state: s),
      'ZoneScreen': (s) => ZoneScreen(state: s),
      'ChangeCityScreen': (s) => ChangeCityScreen(state: s),
      'VehicleScreen': (s) => VehicleScreen(state: s),
      'SupportScreen': (s) => SupportScreen(state: s),
      'SupportChatScreen': (s) => SupportChatScreen(state: s),
      'SosScreen': (s) => SosScreen(state: s),
      'AboutScreen': (s) => AboutScreen(state: s),
    };

    final findings = <String>[];
    final oldOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = oldOnError);

    for (final entry in cases.entries) {
      final overflows = <String>[];
      final errors = <String>[];
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        final first = msg.split('\n').first;
        if (msg.contains('overflowed')) {
          final lines = msg.split('\n');
          final where = <String>[];
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].contains('error-causing widget')) {
              where.addAll(lines.skip(i).take(4).map((l) => l.trim()));
              break;
            }
          }
          overflows.add('$first | ${where.join(' ~ ')}');
        } else if (msg.contains('HTTP_') ||
            msg.contains('SocketException') ||
            msg.contains('ClientException') ||
            msg.contains('Request failed')) {
          return; // network noise
        } else {
          final frames = (details.stack ?? StackTrace.empty).toString().split('\n');
          final src = frames
              .firstWhere((f) => f.contains('partner/lib/screens') || f.contains('partner/lib/ui'), orElse: () => 'no-screen-frame')
              .replaceAll(RegExp(r'^\s*'), '');
          errors.add('$first | $src');
        }
      };

      tester.view.physicalSize = const Size(_w, _h);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: entry.value(state),
      ));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 400));

      inspect(tester, entry.key, findings);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 300));
      // drain any exceptions recorded by the binding itself
      // ignore: literal_only_boolean_expressions
      while (true) {
        final e = tester.takeException();
        if (e == null) break;
        final m = e.toString().split('\n').first;
        if (m.contains('overflowed')) {
          overflows.add(m);
        } else if (!m.contains('HTTP') && !m.contains('Request failed')) {
          errors.add(m);
        }
      }
      FlutterError.onError = oldOnError;
      tester.view.reset();

      for (final o in overflows) {
        findings.add('[OVERFLOW] ${entry.key}: $o');
      }
      for (final e in errors) {
        findings.add('[ERROR] ${entry.key}: $e');
      }
    }

    // ignore: avoid_print
    print('=== LAYOUT AUDIT: ${findings.length} findings ===');
    for (final f in findings) {
      // ignore: avoid_print
      print(f);
    }
    // Report only — findings are triaged manually to avoid false-positive failures.
  });
}

// Ink-accurate bounds of a Text: the real painted glyph area, not the
// paragraph box (which usually spans the full constraint width).
Rect? inkRect(WidgetTester tester, Text t) {
  final data = t.data;
  if (data == null) return null;
  final f = find.byWidget(t);
  if (f.evaluate().isEmpty) return null;
  final Rect r;
  try {
    r = tester.getRect(f);
  } catch (_) {
    return null;
  }
  final tp = TextPainter(
    text: TextSpan(text: data, style: t.style),
    textDirection: TextDirection.ltr,
    textAlign: t.textAlign ?? TextAlign.start,
    maxLines: t.maxLines,
    ellipsis: t.overflow == TextOverflow.ellipsis ? '…' : null,
  )..layout(maxWidth: r.width);
  if (tp.height == 0) return null;
  // Widest laid-out line — TextPainter.width returns the constraint for
  // wrapped text, but line metrics carry the real ink width.
  var inkW = 0.0;
  for (final m in tp.computeLineMetrics()) {
    if (m.width > inkW) inkW = m.width;
  }
  if (inkW == 0) return null;
  final align = t.textAlign ?? TextAlign.start;
  double left;
  if (align == TextAlign.center) {
    left = r.center.dx - inkW / 2;
  } else if (align == TextAlign.right || align == TextAlign.end) {
    left = r.right - inkW;
  } else {
    left = r.left;
  }
  // Vertical bounds from glyph boxes: unlike line metrics, these exclude the
  // half-leading above/below the text, which otherwise reports phantom
  // overlaps between stacked lines that are visually clear.
  var top = 0.0;
  var bottom = tp.height;
  final boxes = tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: data.length));
  if (boxes.isNotEmpty) {
    top = boxes.map((b) => b.top).reduce((a, b) => a < b ? a : b);
    bottom = boxes.map((b) => b.bottom).reduce((a, b) => a > b ? a : b);
  }
  return Rect.fromLTRB(left, r.top + top, left + inkW, r.top + bottom);
}

void inspect(WidgetTester tester, String screen, List<String> findings) {
  // Convert to canvas-local coordinates: the design canvas is centred inside
  // the test window (y offset 15px at 412x915 because of the bottom slack).
  Offset origin = Offset.zero;
  final fitted = find.byType(FittedBox);
  if (fitted.evaluate().isNotEmpty) {
    origin = tester.getTopLeft(fitted.first);
  }

  final texts = tester.widgetList<Text>(find.byType(Text)).toList();
  final inks = <Text, Rect?>{};
  for (final t in texts) {
    // Transient SnackBar/toast copy (error banners after failed API calls)
    // intentionally sits above the nav bar — not a layout defect.
    final inSnack = find
        .ancestor(of: find.byWidget(t), matching: find.byType(SnackBar))
        .evaluate()
        .isNotEmpty;
    if (inSnack) continue;
    final ink = inkRect(tester, t);
    inks[t] = ink?.translate(-origin.dx, -origin.dy);
  }
  final live = texts.where((t) => inks[t] != null).toList();

  // 1. Ink overlap between different texts.
  for (var i = 0; i < live.length; i++) {
    for (var j = i + 1; j < live.length; j++) {
      final a = inks[live[i]]!, b = inks[live[j]]!;
      final inter = a.intersect(b);
      if (inter.width > 1.5 && inter.height > 1.5) {
        findings.add('[TEXT-OVERLAP] $screen: "${_t(live[i])}" ${inks[live[i]]} x "${_t(live[j])}" ${inks[live[j]]} at $inter');
      }
    }
  }

  // 2. Ink outside the design canvas (gets clipped).
  for (final t in live) {
    final r = inks[t]!;
    if (r.left < -0.5 || r.top < -0.5 || r.right > _w + 0.5 || r.bottom > _h + 0.5) {
      findings.add('[OFF-CANVAS] $screen: "${_t(t)}" ink=$r');
    }
  }

  // 3. Ink partially escaping a card it sits on (bleeding text).
  final boxes = tester.widgetList<DBox>(find.byType(DBox)).toList();
  for (final t in live) {
    final tr = inks[t]!;
    for (final box in boxes) {
      final bf = find.byWidget(box);
      if (bf.evaluate().isEmpty) continue;
      final Rect br;
      try {
        br = tester.getRect(bf).translate(-origin.dx, -origin.dy);
      } catch (_) {
        continue;
      }
      if (br.width < 4 || br.height < 4) continue;
      if (!tr.overlaps(br)) continue;
      final inter = tr.intersect(br);
      final frac = (inter.width * inter.height) / (tr.width * tr.height);
      if (frac > 0.15 && frac < 0.97) {
        findings.add('[ESCAPES-CARD] $screen: "${_t(t)}" ink=$tr card=$br covered=${(frac * 100).toStringAsFixed(0)}%');
      }
    }
  }
}

String _t(Text t) {
  final s = t.data ?? t.textSpan?.toPlainText() ?? '';
  final flat = s.replaceAll('\n', '⏎ ');
  return flat.length > 42 ? '${flat.substring(0, 42)}…' : flat;
}
