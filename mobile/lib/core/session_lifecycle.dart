import 'package:flutter/widgets.dart';

import '../state/app_state.dart';

/// Revalidates the session when the app returns to the foreground.
/// Kept outside the screens so login/logout UI remains untouched.
class SessionLifecycle extends StatefulWidget {
  const SessionLifecycle({
    super.key,
    required this.state,
    required this.child,
  });

  final AppState state;
  final Widget child;

  @override
  State<SessionLifecycle> createState() => _SessionLifecycleState();
}

class _SessionLifecycleState extends State<SessionLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      widget.state.resumeSession();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
