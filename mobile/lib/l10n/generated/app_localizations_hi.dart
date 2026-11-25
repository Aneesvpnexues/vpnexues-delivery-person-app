// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get navHome => 'होम';

  @override
  String get navOrders => 'ऑर्डर';

  @override
  String get navEarnings => 'कमाई';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String stepOf5(num step) {
    return '5 में से चरण $step';
  }

  @override
  String get languageTitle => 'भाषा';

  @override
  String get langDefault => 'डिफ़ॉल्ट';

  @override
  String get langEn => 'अंग्रेज़ी';

  @override
  String get langTa => 'तमिल';

  @override
  String get langSi => 'सिंहली';

  @override
  String get notAdded => 'जोड़ा नहीं गया';

  @override
  String get statusAssigned => 'नया ऑर्डर';

  @override
  String get statusAccepted => 'स्वीकार किया गया';

  @override
  String get statusAtPickup => 'पिकअप स्थान पर';

  @override
  String get statusPickedUp => 'पिकअप किया गया';

  @override
  String get statusArrived => 'पहुंच गया';

  @override
  String get statusDelivered => 'डिलीवर किया गया';

  @override
  String get statusCancelled => 'रद्द किया गया';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get secDeliveries => 'डिलीवरी';

  @override
  String get autoAcceptTitle => 'पास के ऑर्डर अपने आप स्वीकार करें';

  @override
  String get autoAcceptSub => 'आपकी लोकेशन से 2 किमी के भीतर';

  @override
  String get zoneTitle => 'शहर, हब और डिलीवरी क्षेत्र';

  @override
  String get noHub => 'कोई हब नहीं';

  @override
  String get navTitle => 'नेविगेशन';

  @override
  String get navInApp => 'ऐप के अंदर के मैप';

  @override
  String get navGoogleMaps => 'Google Maps · चरण-दर-चरण';

  @override
  String get secAlerts => 'अलर्ट';

  @override
  String get newOrderSoundTitle => 'नए ऑर्डर की आवाज़';

  @override
  String get newOrderSoundSub => 'साइलेंट मोड में भी बजेगा';

  @override
  String get payoutAlertsTitle => 'भुगतान और बोनस अलर्ट';

  @override
  String get offersTitle => 'ऑफ़र और अभियान';

  @override
  String get secApp => 'ऐप';

  @override
  String get darkModeTitle => 'रात की शिफ्ट के लिए डार्क मोड';

  @override
  String get dataSaverTitle => 'डेटा सेवर';

  @override
  String get dataSaverSub => '3G / कमजोर सिग्नल पर हल्के मैप';

  @override
  String get secSecurity => 'सुरक्षा';

  @override
  String get changePasswordTitle => 'पासवर्ड बदलें';

  @override
  String get fingerprintTitle => 'फ़िंगरप्रिंट से अनलॉक';

  @override
  String get loadingSettings => 'सेटिंग्स लोड हो रही हैं…';

  @override
  String get errLoadSettings => 'सेटिंग्स लोड नहीं हो सकीं';

  @override
  String get errSaveSetting => 'यह सेटिंग सेव नहीं हो सकी';

  @override
  String get appLanguageTitle => 'ऐप की भाषा';

  @override
  String get appLanguageDesc =>
      'मेनू, अलर्ट और वॉइस नेविगेशन के लिए भाषा चुनें।';

  @override
  String get voiceNavTitle => 'उसी भाषा में वॉइस नेविगेशन';

  @override
  String get voiceNavSub => 'चरण-दर-चरण निर्देश';

  @override
  String get saving => 'सेव हो रहा है…';

  @override
  String get apply => 'लागू करें';

  @override
  String languageSetTo(String name) {
    return 'भाषा $name पर सेट की गई';
  }

  @override
  String get errChangeLanguage => 'भाषा नहीं बदली जा सकी';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get kycVerified => 'KYC सत्यापित';

  @override
  String get kycInReview => 'KYC की समीक्षा जारी है';

  @override
  String get kycNotStarted => 'KYC शुरू नहीं हुआ';

  @override
  String get kycNeedsAttention => 'KYC पर ध्यान देना आवश्यक है';

  @override
  String partnerId(String code, String place) {
    return 'पार्टनर ID $code · $place';
  }

  @override
  String get statRating => 'रेटिंग';

  @override
  String get statDeliveries => 'डिलीवरी';

  @override
  String get statPartnerSince => 'पार्टनर बने';

  @override
  String get secAccount => 'खाता';

  @override
  String get personalInfoTitle => 'व्यक्तिगत जानकारी';

  @override
  String get documentsTitle => 'दस्तावेज़';

  @override
  String docsToUpload(num count) {
    return 'अपलोड करने के लिए $count';
  }

  @override
  String docsExpiring(num count) {
    return '$count की समय-सीमा समाप्त हो रही है';
  }

  @override
  String get bankTitle => 'बैंक और UPI';

  @override
  String get vehicleTitle => 'वाहन';

  @override
  String get secAppSupport => 'ऐप और सहायता';

  @override
  String get helpSupport => 'मदद और सहायता';

  @override
  String get sosContacts => 'SOS और आपातकालीन संपर्क';

  @override
  String get aboutApp => 'VP Nexues के बारे में';

  @override
  String get logoutRow => 'लॉग आउट';

  @override
  String get logoutTitle => 'लॉग आउट करें?';

  @override
  String get logoutBody => 'दोबारा लॉग इन करने तक आपको नए ऑर्डर नहीं मिलेंगे।';

  @override
  String get logoutBtn => 'लॉग आउट';

  @override
  String get cancelBtn => 'रद्द करें';

  @override
  String get greetingMorning => 'सुप्रभात';

  @override
  String get greetingAfternoon => 'नमस्कार';

  @override
  String get greetingEvening => 'शुभ संध्या';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get change => 'बदलें';

  @override
  String get newOrderPill => 'नया ऑर्डर · स्वीकार करने के लिए टैप करें';

  @override
  String nextPill(String status) {
    return 'अगला · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code रास्ते में है';
  }

  @override
  String orderAtHub(String code) {
    return '#$code हब पर इंतज़ार कर रहा है';
  }

  @override
  String get viewOrder => 'ऑर्डर देखें';

  @override
  String get continueBtn => 'जारी रखें';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count क्रेट',
      one: '$count क्रेट',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'ऑर्डर जाँचे जा रहे हैं…';

  @override
  String get allCaughtUp => 'सब कुछ अपडेट है';

  @override
  String get loadingOrders => 'आपके ऑर्डर लोड हो रहे हैं';

  @override
  String get noOrders => 'अभी कोई ऑर्डर नहीं है';

  @override
  String get stayOnline =>
      'अपने क्षेत्र में ऑनलाइन रहें। हब द्वारा असाइन किए जाते ही नए ऑर्डर यहाँ दिखेंगे।';

  @override
  String get goOnline => 'अपने हब से ऑर्डर पाने के लिए ऑनलाइन जाएँ।';

  @override
  String get creating => 'बनाया जा रहा है…';

  @override
  String get createDemo => 'डेमो ऑर्डर बनाएँ (ट्रायल)';

  @override
  String get thenDeliverTo => 'इसके बाद यहाँ डिलीवर करें';

  @override
  String get yourDaySoFar => 'आज का आपका काम';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डिलीवरी आज',
      one: '$count डिलीवरी आज',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'ऑर्डर सौंपते ही कमाई खाते में जमा हो जाती है';

  @override
  String get viewEarnings => 'कमाई देखें →';

  @override
  String todayEarned(String amount) {
    return 'आज की कमाई: $amount';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'निकासी के लिए उपलब्ध: $amount';
  }

  @override
  String moreQueued(num count) {
    return '$count और कतार में';
  }

  @override
  String get errStatus => 'आपका स्टेटस बदला नहीं जा सका';

  @override
  String demoCreated(String code, String demoCode) {
    return 'डेमो ऑर्डर $code बनाया गया · डिलीवरी कोड $demoCode';
  }

  @override
  String get errDemo => 'डेमो ऑर्डर नहीं बनाया जा सका';
}
