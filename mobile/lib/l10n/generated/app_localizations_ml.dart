// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get navHome => 'ഹോം';

  @override
  String get navOrders => 'ഓർഡറുകൾ';

  @override
  String get navEarnings => 'വരുമാനം';

  @override
  String get navProfile => 'പ്രൊഫൈൽ';

  @override
  String stepOf5(num step) {
    return '5-ൽ $step-ാം ഘട്ടം';
  }

  @override
  String get languageTitle => 'ഭാഷ';

  @override
  String get langDefault => 'സ്ഥിരസ്ഥിതി';

  @override
  String get langEn => 'ഇംഗ്ലീഷ്';

  @override
  String get langTa => 'തമിഴ്';

  @override
  String get langSi => 'സിംഹള';

  @override
  String get notAdded => 'ചേർത്തിട്ടില്ല';

  @override
  String get statusAssigned => 'പുതിയ ഓർഡർ';

  @override
  String get statusAccepted => 'സ്വീകരിച്ചു';

  @override
  String get statusAtPickup => 'പിക്കപ്പ് സ്ഥലത്ത്';

  @override
  String get statusPickedUp => 'പിക്കപ്പ് ചെയ്തു';

  @override
  String get statusArrived => 'എത്തി';

  @override
  String get statusDelivered => 'വിതരണം ചെയ്തു';

  @override
  String get statusCancelled => 'റദ്ദാക്കി';

  @override
  String get settingsTitle => 'ക്രമീകരണങ്ങൾ';

  @override
  String get secDeliveries => 'ഡെലിവറികൾ';

  @override
  String get autoAcceptTitle => 'സമീപമുള്ള ഓർഡറുകൾ സ്വയമേവ സ്വീകരിക്കുക';

  @override
  String get autoAcceptSub => 'നിങ്ങളുടെ സ്ഥാനത്തിൽ നിന്ന് 2 കി.മീ. പരിധിയിൽ';

  @override
  String get zoneTitle => 'നഗരം, ഹബ്, ഡെലിവറി പരിധി';

  @override
  String get noHub => 'ഹബ് ഇല്ല';

  @override
  String get navTitle => 'നാവിഗേഷൻ';

  @override
  String get navInApp => 'ആപ്പിലെ മാപ്പുകൾ';

  @override
  String get navGoogleMaps => 'Google Maps · ഘട്ടംഘട്ടമായുള്ള വഴികാട്ടൽ';

  @override
  String get secAlerts => 'അറിയിപ്പുകൾ';

  @override
  String get newOrderSoundTitle => 'പുതിയ ഓർഡർ ശബ്ദം';

  @override
  String get newOrderSoundSub => 'സൈലന്റ് മോഡിലും ശബ്ദിക്കും';

  @override
  String get payoutAlertsTitle => 'പേയ്മെന്റ്, ബോണസ് അറിയിപ്പുകൾ';

  @override
  String get offersTitle => 'ഓഫറുകളും ക്യാമ്പെയ്‌നുകളും';

  @override
  String get secApp => 'ആപ്പ്';

  @override
  String get darkModeTitle => 'രാത്രി ഷിഫ്റ്റിനുള്ള ഡാർക്ക് മോഡ്';

  @override
  String get dataSaverTitle => 'ഡാറ്റ സേവിംഗ്';

  @override
  String get dataSaverSub => '3G / കുറഞ്ഞ സിഗ്നലിൽ ലഘുവായ മാപ്പുകൾ';

  @override
  String get secSecurity => 'സുരക്ഷ';

  @override
  String get changePasswordTitle => 'പാസ്‌വേഡ് മാറ്റുക';

  @override
  String get fingerprintTitle => 'വിരലടയാളം ഉപയോഗിച്ച് തുറക്കുക';

  @override
  String get loadingSettings => 'ക്രമീകരണങ്ങൾ ലോഡ് ചെയ്യുന്നു…';

  @override
  String get errLoadSettings => 'ക്രമീകരണങ്ങൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get errSaveSetting => 'ആ ക്രമീകരണം സംരക്ഷിക്കാനായില്ല';

  @override
  String get appLanguageTitle => 'ആപ്പിന്റെ ഭാഷ';

  @override
  String get appLanguageDesc =>
      'മെനുകൾക്കും അറിയിപ്പുകൾക്കും വോയ്സ് നാവിഗേഷനും ഭാഷ തിരഞ്ഞെടുക്കുക.';

  @override
  String get voiceNavTitle => 'അതേ ഭാഷയിൽ വോയ്സ് നാവിഗേഷൻ';

  @override
  String get voiceNavSub => 'ഘട്ടംഘട്ടമായുള്ള നിർദ്ദേശങ്ങൾ';

  @override
  String get saving => 'സംരക്ഷിക്കുന്നു…';

  @override
  String get apply => 'പ്രയോഗിക്കുക';

  @override
  String languageSetTo(String name) {
    return 'ഭാഷ $name ആയി സജ്ജമാക്കി';
  }

  @override
  String get errChangeLanguage => 'ഭാഷ മാറ്റാനായില്ല';

  @override
  String get profileTitle => 'പ്രൊഫൈൽ';

  @override
  String get kycVerified => 'KYC സ്ഥിരീകരിച്ചു';

  @override
  String get kycInReview => 'KYC പരിശോധനയിലാണ്';

  @override
  String get kycNotStarted => 'KYC ആരംഭിച്ചിട്ടില്ല';

  @override
  String get kycNeedsAttention => 'KYC ശ്രദ്ധ ആവശ്യപ്പെടുന്നു';

  @override
  String partnerId(String code, String place) {
    return 'പാർട്ണർ ID $code · $place';
  }

  @override
  String get statRating => 'റേറ്റിംഗ്';

  @override
  String get statDeliveries => 'ഡെലിവറികൾ';

  @override
  String get statPartnerSince => 'പാർട്ണറായിട്ട്';

  @override
  String get secAccount => 'അക്കൗണ്ട്';

  @override
  String get personalInfoTitle => 'വ്യക്തിഗത വിവരങ്ങൾ';

  @override
  String get documentsTitle => 'രേഖകൾ';

  @override
  String docsToUpload(num count) {
    return 'അപ്‌ലോഡ് ചെയ്യാൻ $count';
  }

  @override
  String docsExpiring(num count) {
    return '$count കാലാവധി തീരുന്നു';
  }

  @override
  String get bankTitle => 'ബാങ്ക്, UPI';

  @override
  String get vehicleTitle => 'വാഹനം';

  @override
  String get secAppSupport => 'ആപ്പും സഹായവും';

  @override
  String get helpSupport => 'സഹായവും പിന്തുണയും';

  @override
  String get sosContacts => 'SOS, അടിയന്തര ബന്ധങ്ങൾ';

  @override
  String get aboutApp => 'VP Nexues-നെക്കുറിച്ച്';

  @override
  String get logoutRow => 'ലോഗ് ഔട്ട്';

  @override
  String get logoutTitle => 'ലോഗ് ഔട്ട് ചെയ്യണോ?';

  @override
  String get logoutBody =>
      'വീണ്ടും ലോഗിൻ ചെയ്യുന്നതുവരെ പുതിയ ഓർഡറുകൾ ലഭിക്കില്ല.';

  @override
  String get logoutBtn => 'ലോഗ് ഔട്ട്';

  @override
  String get cancelBtn => 'റദ്ദാക്കുക';

  @override
  String get greetingMorning => 'സുപ്രഭാതം';

  @override
  String get greetingAfternoon => 'ശുഭദിനം';

  @override
  String get greetingEvening => 'ശുഭസായാഹ്നം';

  @override
  String get online => 'ഓൺലൈൻ';

  @override
  String get offline => 'ഓഫ്‌ലൈൻ';

  @override
  String get change => 'മാറ്റുക';

  @override
  String get newOrderPill => 'പുതിയ ഓർഡർ · സ്വീകരിക്കാൻ ടാപ്പ് ചെയ്യുക';

  @override
  String nextPill(String status) {
    return 'അടുത്തത് · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code യാത്രയിലാണ്';
  }

  @override
  String orderAtHub(String code) {
    return '#$code ഹബ്ബിൽ കാത്തിരിക്കുന്നു';
  }

  @override
  String get viewOrder => 'ഓർഡർ കാണുക';

  @override
  String get continueBtn => 'തുടരുക';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ക്രേറ്റുകൾ',
      one: '$count ക്രേറ്റ്',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'ഓർഡറുകൾ പരിശോധിക്കുന്നു…';

  @override
  String get allCaughtUp => 'എല്ലാം പുതുക്കിയിട്ടുണ്ട്';

  @override
  String get loadingOrders => 'നിങ്ങളുടെ ഓർഡറുകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get noOrders => 'ഇപ്പോൾ ഓർഡറുകളില്ല';

  @override
  String get stayOnline =>
      'നിങ്ങളുടെ മേഖലയ്ക്കുള്ളിൽ ഓൺലൈനായി തുടരുക. ഹബ് ഓർഡർ നൽകുമ്പോൾ അത് ഇവിടെ കാണിക്കും.';

  @override
  String get goOnline => 'നിങ്ങളുടെ ഹബ്ബിൽ നിന്ന് ഓർഡറുകൾ ലഭിക്കാൻ ഓൺലൈനാകുക.';

  @override
  String get creating => 'സൃഷ്ടിക്കുന്നു…';

  @override
  String get createDemo => 'ഡെമോ ഓർഡർ സൃഷ്ടിക്കുക (ട്രയൽ)';

  @override
  String get thenDeliverTo => 'തുടർന്ന് ഇവിടെ എത്തിക്കുക';

  @override
  String get yourDaySoFar => 'ഇന്നത്തെ നിങ്ങളുടെ പ്രവർത്തനം';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഇന്നത്തെ ഡെലിവറികൾ',
      one: '$count ഇന്നത്തെ ഡെലിവറി',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'ഓർഡർ കൈമാറുന്ന ഉടൻ വരുമാനം ക്രെഡിറ്റ് ചെയ്യും';

  @override
  String get viewEarnings => 'വരുമാനം കാണുക →';

  @override
  String todayEarned(String amount) {
    return 'ഇന്ന് ലഭിച്ചത്: $amount';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'പിൻവലിക്കാൻ ലഭ്യം: $amount';
  }

  @override
  String moreQueued(num count) {
    return 'ക്യൂവിൽ ഇനി $count';
  }

  @override
  String get errStatus => 'നിങ്ങളുടെ സ്റ്റാറ്റസ് മാറ്റാനായില്ല';

  @override
  String demoCreated(String code, String demoCode) {
    return 'ഡെമോ ഓർഡർ $code സൃഷ്ടിച്ചു · ഡെലിവറി കോഡ് $demoCode';
  }

  @override
  String get errDemo => 'ഡെമോ ഓർഡർ സൃഷ്ടിക്കാനായില്ല';
}
