// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navOrders => 'ஆர்டர்கள்';

  @override
  String get navEarnings => 'வருமானம்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String stepOf5(num step) {
    return 'படி $step / 5';
  }

  @override
  String get languageTitle => 'மொழி';

  @override
  String get langDefault => 'இயல்புநிலை';

  @override
  String get langEn => 'English';

  @override
  String get langTa => 'தமிழ்';

  @override
  String get langSi => 'සිංහල';

  @override
  String get notAdded => 'சேர்க்கப்படவில்லை';

  @override
  String get statusAssigned => 'புதிய ஆர்டர்';

  @override
  String get statusAccepted => 'ஏற்கப்பட்டது';

  @override
  String get statusAtPickup => 'எடுப்பிடத்தில்';

  @override
  String get statusPickedUp => 'எடுக்கப்பட்டது';

  @override
  String get statusArrived => 'வந்தடைந்தது';

  @override
  String get statusDelivered => 'வழங்கப்பட்டது';

  @override
  String get statusCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get secDeliveries => 'டெலிவரிகள்';

  @override
  String get autoAcceptTitle => 'அருகிலுள்ள ஆர்டர்களை தானாக ஏற்கவும்';

  @override
  String get autoAcceptSub => 'உங்கள் இடத்திலிருந்து 2 கி.மீ. உள்ளே';

  @override
  String get zoneTitle => 'நகரம், ஹப் & டெலிவரி சுற்றளவு';

  @override
  String get noHub => 'ஹப் இல்லை';

  @override
  String get navTitle => 'வழிசெலுத்தல்';

  @override
  String get navInApp => 'இன்-ஆப் வரைபடங்கள்';

  @override
  String get navGoogleMaps => 'Google Maps · படிப்படியான வழிகாட்டுதல்';

  @override
  String get secAlerts => 'எச்சரிக்கைகள்';

  @override
  String get newOrderSoundTitle => 'புதிய ஆர்டர் ஒலி';

  @override
  String get newOrderSoundSub => 'அமைதி பயன்முறையிலும் இயங்கும்';

  @override
  String get payoutAlertsTitle => 'பணம் & போனஸ் எச்சரிக்கைகள்';

  @override
  String get offersTitle => 'சலுகைகள் & பிரச்சாரங்கள்';

  @override
  String get secApp => 'செயலி';

  @override
  String get darkModeTitle => 'இரவு ஷிஃப்ட்களுக்கு இருண்ட பயன்முறை';

  @override
  String get dataSaverTitle => 'தரவு சேமிப்பு';

  @override
  String get dataSaverSub => '3G / பலவீனமான சமிக்ஞையில் இலகுவான வரைபடங்கள்';

  @override
  String get secSecurity => 'பாதுகாப்பு';

  @override
  String get changePasswordTitle => 'கடவுச்சொல்லை மாற்றவும்';

  @override
  String get fingerprintTitle => 'கைரேகை திறப்பு';

  @override
  String get loadingSettings => 'அமைப்புகள் ஏற்றப்படுகின்றன…';

  @override
  String get errLoadSettings => 'அமைப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get errSaveSetting => 'அந்த அமைப்பை சேமிக்க முடியவில்லை';

  @override
  String get appLanguageTitle => 'செயலி மொழி';

  @override
  String get appLanguageDesc =>
      'மெனுக்கள், எச்சரிக்கைகள் மற்றும் குரல் வழிசெலுத்தலுக்கான மொழியைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get voiceNavTitle => 'அதே மொழியில் குரல் வழிசெலுத்தல்';

  @override
  String get voiceNavSub => 'படிப்படியான வழிகாட்டுதல்';

  @override
  String get saving => 'சேமிக்கப்படுகிறது…';

  @override
  String get apply => 'பயன்படுத்து';

  @override
  String languageSetTo(String name) {
    return 'மொழி $name ஆக அமைக்கப்பட்டது';
  }

  @override
  String get errChangeLanguage => 'மொழியை மாற்ற முடியவில்லை';

  @override
  String get profileTitle => 'சுயவிவரம்';

  @override
  String get kycVerified => 'KYC சரிபார்க்கப்பட்டது';

  @override
  String get kycInReview => 'KYC மதிப்பாய்வில்';

  @override
  String get kycNotStarted => 'KYC தொடங்கப்படவில்லை';

  @override
  String get kycNeedsAttention => 'KYC கவனம் தேவை';

  @override
  String partnerId(String code, String place) {
    return 'பார்ட்னர் ஐடி $code · $place';
  }

  @override
  String get statRating => 'மதிப்பீடு';

  @override
  String get statDeliveries => 'டெலிவரிகள்';

  @override
  String get statPartnerSince => 'பார்ட்னர் முதல்';

  @override
  String get secAccount => 'கணக்கு';

  @override
  String get personalInfoTitle => 'தனிப்பட்ட தகவல்';

  @override
  String get documentsTitle => 'ஆவணங்கள்';

  @override
  String docsToUpload(num count) {
    return '$count பதிவேற்ற வேண்டும்';
  }

  @override
  String docsExpiring(num count) {
    return '$count காலாவதியாகிறது';
  }

  @override
  String get bankTitle => 'வங்கி & UPI';

  @override
  String get vehicleTitle => 'வாகனம்';

  @override
  String get secAppSupport => 'செயலி & ஆதரவு';

  @override
  String get helpSupport => 'உதவி & ஆதரவு';

  @override
  String get sosContacts => 'SOS & அவசர தொடர்புகள்';

  @override
  String get aboutApp => 'VP Nexues பற்றி';

  @override
  String get logoutRow => 'வெளியேறு';

  @override
  String get logoutTitle => 'வெளியேறவா?';

  @override
  String get logoutBody => 'மீண்டும் உள்நுழையும் வரை புதிய ஆர்டர்கள் வராது.';

  @override
  String get logoutBtn => 'வெளியேறு';

  @override
  String get cancelBtn => 'ரத்து';

  @override
  String get greetingMorning => 'காலை வணக்கம்';

  @override
  String get greetingAfternoon => 'மதிய வணக்கம்';

  @override
  String get greetingEvening => 'மாலை வணக்கம்';

  @override
  String get online => 'ஆன்லைனில்';

  @override
  String get offline => 'ஆஃப்லைனில்';

  @override
  String get change => 'மாற்று';

  @override
  String get newOrderPill => 'புதிய ஆர்டர் · ஏற்க தட்டவும்';

  @override
  String nextPill(String status) {
    return 'அடுத்து · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code வழியில் உள்ளது';
  }

  @override
  String orderAtHub(String code) {
    return '#$code ஹப்பில் காத்திருக்கிறது';
  }

  @override
  String get viewOrder => 'ஆர்டரைக் காண்க';

  @override
  String get continueBtn => 'தொடரவும்';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count கூடைகள்',
      one: '$count கூடை',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'ஆர்டர்கள் சரிபார்க்கப்படுகின்றன…';

  @override
  String get allCaughtUp => 'அனைத்தும் முடிந்தது';

  @override
  String get loadingOrders => 'உங்கள் ஆர்டர்கள் ஏற்றப்படுகின்றன';

  @override
  String get noOrders => 'இப்போது ஆர்டர்கள் இல்லை';

  @override
  String get stayOnline =>
      'உங்கள் மண்டலத்திற்குள் ஆன்லைனில் இருங்கள். ஹப் ஒதுக்கியதும் புதிய ஆர்டர்கள் இங்கே தோன்றும்.';

  @override
  String get goOnline => 'ஹப்பிலிருந்து ஆர்டர்களைப் பெற ஆன்லைனில் செல்லுங்கள்.';

  @override
  String get creating => 'உருவாக்கப்படுகிறது…';

  @override
  String get createDemo => 'டெமோ ஆர்டர் உருவாக்கு (சோதனை)';

  @override
  String get thenDeliverTo => 'பின்னர் இங்கே வழங்கவும்';

  @override
  String get yourDaySoFar => 'இன்றைய உங்கள் நாள்';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'இன்று $count டெலிவரிகள்',
      one: 'இன்று $count டெலிவரி',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'நீங்கள் ஒப்படைத்ததும் வருமானம் வரவு வைக்கப்படும்';

  @override
  String get viewEarnings => 'வருமானத்தைக் காண்க →';

  @override
  String todayEarned(String amount) {
    return 'இன்று: $amount சம்பாதித்தது';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'திரும்பப் பெற கிடைப்பது: $amount';
  }

  @override
  String moreQueued(num count) {
    return '$count மேலும் வரிசையில்';
  }

  @override
  String get errStatus => 'உங்கள் நிலையை மாற்ற முடியவில்லை';

  @override
  String demoCreated(String code, String demoCode) {
    return 'டெமோ ஆர்டர் $code உருவாக்கப்பட்டது · டெலிவரி கோடு $demoCode';
  }

  @override
  String get errDemo => 'டெமோ ஆர்டரை உருவாக்க முடியவில்லை';
}
