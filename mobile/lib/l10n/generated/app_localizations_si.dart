// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navOrders => 'ඇණවුම්';

  @override
  String get navEarnings => 'ආදායම';

  @override
  String get navProfile => 'පැතිකඩ';

  @override
  String stepOf5(num step) {
    return 'පියවර $step / 5';
  }

  @override
  String get languageTitle => 'භාෂාව';

  @override
  String get langDefault => 'පෙරනිමි';

  @override
  String get langEn => 'English';

  @override
  String get langTa => 'தமிழ்';

  @override
  String get langSi => 'සිංහල';

  @override
  String get notAdded => 'එකතු කර නැත';

  @override
  String get statusAssigned => 'නව ඇණවුම';

  @override
  String get statusAccepted => 'පිළිගත්තා';

  @override
  String get statusAtPickup => 'ඇරඹුම් ස්ථානයේ';

  @override
  String get statusPickedUp => 'ආ ගත්තා';

  @override
  String get statusArrived => 'පැමිණුනා';

  @override
  String get statusDelivered => 'භාර දුන්නා';

  @override
  String get statusCancelled => 'අවලංගු කළා';

  @override
  String get settingsTitle => 'සැකසුම්';

  @override
  String get secDeliveries => 'බෙදාහැරීම්';

  @override
  String get autoAcceptTitle => 'ආසන්න ඇණවුම් ස්වයංක්‍රීයව පිළිගන්න';

  @override
  String get autoAcceptSub => 'ඔබේ පිහිටීමෙන් කි.මී. 2 ක් ඇතුළත';

  @override
  String get zoneTitle => 'නගරය, හබ් සහ බෙදාහැරීම් ව්‍යාප්තිය';

  @override
  String get noHub => 'හබ් නැත';

  @override
  String get navTitle => 'මාර්ගෝපදේශනය';

  @override
  String get navInApp => 'ඇප් තුළ සිතියම්';

  @override
  String get navGoogleMaps => 'Google Maps · පියවරෙන් පියවර මාර්ගෝපදේශනය';

  @override
  String get secAlerts => 'අනතුරු ඇඟවීම්';

  @override
  String get newOrderSoundTitle => 'නව ඇණවුම් ශබ්දය';

  @override
  String get newOrderSoundSub => 'නිශ්ශබ්ද ප්‍රකාරයේදීත් වාදනය වේ';

  @override
  String get payoutAlertsTitle => 'ගෙවීම් සහ බෝනස් අනතුරු ඇඟවීම්';

  @override
  String get offersTitle => 'පිරිනැමීම් සහ ප්‍රචාරණ';

  @override
  String get secApp => 'යෙදුම';

  @override
  String get darkModeTitle => 'රාත්‍රී වැඩ සඳහා අඳුරු ප්‍රකාරය';

  @override
  String get dataSaverTitle => 'දත්ත ඉතිරිකිරීම';

  @override
  String get dataSaverSub => '3G / දුර්වල සංඥාවේදී සැහැල්ලු සිතියම්';

  @override
  String get secSecurity => 'ආරක්ෂාව';

  @override
  String get changePasswordTitle => 'මුරපදය වෙනස් කරන්න';

  @override
  String get fingerprintTitle => 'ඇඟිල්ලේ සලකුණු විවෘත කිරීම';

  @override
  String get loadingSettings => 'සැකසුම් පූරණය වෙමින්…';

  @override
  String get errLoadSettings => 'සැකසුම් පූරණය කළ නොහැක';

  @override
  String get errSaveSetting => 'ඒ සැකසුම සුරක්‍ය කළ නොහැක';

  @override
  String get appLanguageTitle => 'යෙදුම් භාෂාව';

  @override
  String get appLanguageDesc =>
      'මෙනු, අනතුරු ඇඟවීම් සහ ශබ්ද මාර්ගෝපදේශනය සඳහා භාෂාව තෝරන්න.';

  @override
  String get voiceNavTitle => 'එකම භාෂාවෙන් ශබ්ද මාර්ගෝපදේශනය';

  @override
  String get voiceNavSub => 'පියවරෙන් පියවර මාර්ගෝපදේශනය';

  @override
  String get saving => 'සුරක්‍ය වෙමින්…';

  @override
  String get apply => 'යොදන්න';

  @override
  String languageSetTo(String name) {
    return 'භාෂාව $name ලෙස සකසන ලදී';
  }

  @override
  String get errChangeLanguage => 'භාෂාව වෙනස් කළ නොහැක';

  @override
  String get profileTitle => 'පැතිකඩ';

  @override
  String get kycVerified => 'KYC තහවුරු කර ඇත';

  @override
  String get kycInReview => 'KYC විභාගයේ';

  @override
  String get kycNotStarted => 'KYC ආරම්භ කර නැත';

  @override
  String get kycNeedsAttention => 'KYC අවධානය අවශ්‍යයි';

  @override
  String partnerId(String code, String place) {
    return 'සහභාගී හැඳුනුම්පත $code · $place';
  }

  @override
  String get statRating => 'ශ්‍රේණිගත කිරීම';

  @override
  String get statDeliveries => 'බෙදාහැරීම්';

  @override
  String get statPartnerSince => 'සහභාගී වූ දිනය';

  @override
  String get secAccount => 'ගිණුම';

  @override
  String get personalInfoTitle => 'පුද්ගලික තොරතුරු';

  @override
  String get documentsTitle => 'ලේඛන';

  @override
  String docsToUpload(num count) {
    return 'උඩුගත කළ යුතු $countක්';
  }

  @override
  String docsExpiring(num count) {
    return '$countක් කල් ඉකුත් වේ';
  }

  @override
  String get bankTitle => 'බැංකුව සහ UPI';

  @override
  String get vehicleTitle => 'වාහනය';

  @override
  String get secAppSupport => 'යෙදුම සහ සහායනය';

  @override
  String get helpSupport => 'උදව් සහ සහායනය';

  @override
  String get sosContacts => 'SOS සහ හදිසි අමතන අංක';

  @override
  String get aboutApp => 'VP Nexues පිළිබඳව';

  @override
  String get logoutRow => 'ඉවත් වන්න';

  @override
  String get logoutTitle => 'ඉවත් වනවාද?';

  @override
  String get logoutBody => 'නැවත පිවිසෙන තුරු නව ඇණවුම් නොලැබේ.';

  @override
  String get logoutBtn => 'ඉවත් වන්න';

  @override
  String get cancelBtn => 'අවලංගු කරන්න';

  @override
  String get greetingMorning => 'බියර් සුබ දවසක්';

  @override
  String get greetingAfternoon => 'සුබ දහවල්';

  @override
  String get greetingEvening => 'සුබ සන්ධ්‍යාවක්';

  @override
  String get online => 'සබැඳියි';

  @override
  String get offline => 'අසබැඳියි';

  @override
  String get change => 'වෙනස් කරන්න';

  @override
  String get newOrderPill => 'නව ඇණවුම · පිළිගැනීමට තට්ටු කරන්න';

  @override
  String nextPill(String status) {
    return 'ඊළඟ · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code මාර්ගයේ';
  }

  @override
  String orderAtHub(String code) {
    return '#$code හබ් එකේ බලා සිටී';
  }

  @override
  String get viewOrder => 'ඇණවුම බලන්න';

  @override
  String get continueBtn => 'දිගට යන්න';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count කොටු',
      one: '$count කොටුව',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'ඇණවුම් පරීක්ෂා වෙමින්…';

  @override
  String get allCaughtUp => 'සියල්ල ඉවරයි';

  @override
  String get loadingOrders => 'ඔබේ ඇණවුම් පූරණය වෙමින්';

  @override
  String get noOrders => 'දැනට ඇණවුම් නැත';

  @override
  String get stayOnline =>
      'ඔබේ කලාපය තුළ සබැඳිව සිටින්න. හබ් එකෙන් වෙන් කළ විට නව ඇණවුම් මෙහි දිස්වේ.';

  @override
  String get goOnline => 'හබ් එකෙන් ඇණවුම් ලැබීමට සබැඳිවන්න.';

  @override
  String get creating => 'සෑදෙමින්…';

  @override
  String get createDemo => 'උදාහරණ ඇණවුමක් සාදන්න (පරීක්ෂණ)';

  @override
  String get thenDeliverTo => 'එවිට මෙහි භාර දෙන්න';

  @override
  String get yourDaySoFar => 'අද ඔබේ දිනය';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'අද බෙදාහැරීම් $countක්',
      one: 'අද බෙදාහැරීම් $countක්',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote => 'ඔබ භාර දුන් වහාම ආදායම බැර වේ';

  @override
  String get viewEarnings => 'ආදායම බලන්න →';

  @override
  String todayEarned(String amount) {
    return 'අද: $amount උපයා ඇත';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'ඉවත් කිරීමට ඇත්තේ: $amount';
  }

  @override
  String moreQueued(num count) {
    return 'තව $countක් පෝලිමේ';
  }

  @override
  String get errStatus => 'ඔබේ තත්ත්වය වෙනස් කළ නොහැක';

  @override
  String demoCreated(String code, String demoCode) {
    return 'උදාහරණ ඇණවුම $code සාදන ලදී · බෙදාහැරීම් අංකය $demoCode';
  }

  @override
  String get errDemo => 'උදාහරණ ඇණවුමක් සෑදිය නොහැක';
}
