import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; 


import 'core/api_client.dart';
import 'core/session_lifecycle.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/root_gate.dart';
import 'state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase
  await Firebase.initializeApp(); 

  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(prefs);
  final state = AppState(api);
  runApp(PartnerApp(state: state));
  state.boot();
  
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key, required this.state});

  /// Canonical app title used by the localized build (HEAD).
  static const String title = 'VP Nexues Partner';

  /// Compact branding retained from origin/anees.
  static const String legacyTitle = 'VPNEXUES Partner';

  final AppState state;

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when AppState notifies (e.g. after the user
    // applies a new language and loadMe() refreshes the settings).
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: title,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SessionLifecycle(
            state: state,
            child: RootGate(state: state),
          ),
        );
      },
    );
  }
}
