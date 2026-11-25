// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get navHome => 'హోమ్';

  @override
  String get navOrders => 'ఆర్డర్లు';

  @override
  String get navEarnings => 'ఆదాయం';

  @override
  String get navProfile => 'ప్రొఫైల్';

  @override
  String stepOf5(num step) {
    return '5లో $stepవ దశ';
  }

  @override
  String get languageTitle => 'భాష';

  @override
  String get langDefault => 'డిఫాల్ట్';

  @override
  String get langEn => 'ఆంగ్లం';

  @override
  String get langTa => 'తమిళం';

  @override
  String get langSi => 'సింహళం';

  @override
  String get notAdded => 'జోడించబడలేదు';

  @override
  String get statusAssigned => 'కొత్త ఆర్డర్';

  @override
  String get statusAccepted => 'ఆమోదించబడింది';

  @override
  String get statusAtPickup => 'పికప్ ప్రదేశంలో ఉంది';

  @override
  String get statusPickedUp => 'పికప్ చేయబడింది';

  @override
  String get statusArrived => 'చేరుకుంది';

  @override
  String get statusDelivered => 'డెలివరీ చేయబడింది';

  @override
  String get statusCancelled => 'రద్దు చేయబడింది';

  @override
  String get settingsTitle => 'సెట్టింగ్‌లు';

  @override
  String get secDeliveries => 'డెలివరీలు';

  @override
  String get autoAcceptTitle =>
      'దగ్గరలోని ఆర్డర్‌లను ఆటోమేటిక్‌గా అంగీకరించండి';

  @override
  String get autoAcceptSub => 'మీ స్థానం నుండి 2 కి.మీ పరిధిలో';

  @override
  String get zoneTitle => 'నగరం, హబ్ మరియు డెలివరీ ప్రాంతం';

  @override
  String get noHub => 'హబ్ లేదు';

  @override
  String get navTitle => 'నావిగేషన్';

  @override
  String get navInApp => 'యాప్‌లోని మ్యాప్‌లు';

  @override
  String get navGoogleMaps => 'Google Maps · దశలవారీ మార్గదర్శకం';

  @override
  String get secAlerts => 'అలర్ట్‌లు';

  @override
  String get newOrderSoundTitle => 'కొత్త ఆర్డర్ శబ్దం';

  @override
  String get newOrderSoundSub => 'సైలెంట్ మోడ్‌లో కూడా శబ్దం వస్తుంది';

  @override
  String get payoutAlertsTitle => 'చెల్లింపు మరియు బోనస్ అలర్ట్‌లు';

  @override
  String get offersTitle => 'ఆఫర్‌లు మరియు ప్రచారాలు';

  @override
  String get secApp => 'యాప్';

  @override
  String get darkModeTitle => 'రాత్రి షిఫ్ట్ కోసం డార్క్ మోడ్';

  @override
  String get dataSaverTitle => 'డేటా సేవర్';

  @override
  String get dataSaverSub =>
      '3G / బలహీనమైన సిగ్నల్‌లో తక్కువ డేటా ఉపయోగించే మ్యాప్‌లు';

  @override
  String get secSecurity => 'భద్రత';

  @override
  String get changePasswordTitle => 'పాస్‌వర్డ్ మార్చండి';

  @override
  String get fingerprintTitle => 'వేలిముద్రతో అన్‌లాక్ చేయండి';

  @override
  String get loadingSettings => 'సెట్టింగ్‌లు లోడ్ అవుతున్నాయి…';

  @override
  String get errLoadSettings => 'సెట్టింగ్‌లను లోడ్ చేయలేకపోయాము';

  @override
  String get errSaveSetting => 'ఈ సెట్టింగ్‌ను సేవ్ చేయలేకపోయాము';

  @override
  String get appLanguageTitle => 'యాప్ భాష';

  @override
  String get appLanguageDesc =>
      'మెనూలు, అలర్ట్‌లు మరియు వాయిస్ నావిగేషన్ కోసం భాషను ఎంచుకోండి.';

  @override
  String get voiceNavTitle => 'అదే భాషలో వాయిస్ నావిగేషన్';

  @override
  String get voiceNavSub => 'దశలవారీ సూచనలు';

  @override
  String get saving => 'సేవ్ అవుతోంది…';

  @override
  String get apply => 'వర్తింపజేయండి';

  @override
  String languageSetTo(String name) {
    return 'భాష $nameకి మార్చబడింది';
  }

  @override
  String get errChangeLanguage => 'భాషను మార్చలేకపోయాము';

  @override
  String get profileTitle => 'ప్రొఫైల్';

  @override
  String get kycVerified => 'KYC ధృవీకరించబడింది';

  @override
  String get kycInReview => 'KYC పరిశీలనలో ఉంది';

  @override
  String get kycNotStarted => 'KYC ప్రారంభించబడలేదు';

  @override
  String get kycNeedsAttention => 'KYCపై శ్రద్ధ అవసరం';

  @override
  String partnerId(String code, String place) {
    return 'పార్ట్నర్ ID $code · $place';
  }

  @override
  String get statRating => 'రేటింగ్';

  @override
  String get statDeliveries => 'డెలివరీలు';

  @override
  String get statPartnerSince => 'పార్ట్నర్ అయిన తేదీ';

  @override
  String get secAccount => 'ఖాతా';

  @override
  String get personalInfoTitle => 'వ్యక్తిగత సమాచారం';

  @override
  String get documentsTitle => 'పత్రాలు';

  @override
  String docsToUpload(num count) {
    return 'అప్‌లోడ్ చేయాల్సినవి $count';
  }

  @override
  String docsExpiring(num count) {
    return '$count పత్రాల గడువు ముగియబోతోంది';
  }

  @override
  String get bankTitle => 'బ్యాంక్ మరియు UPI';

  @override
  String get vehicleTitle => 'వాహనం';

  @override
  String get secAppSupport => 'యాప్ మరియు సహాయం';

  @override
  String get helpSupport => 'సహాయం మరియు మద్దతు';

  @override
  String get sosContacts => 'SOS మరియు అత్యవసర సంప్రదింపులు';

  @override
  String get aboutApp => 'VP Nexues గురించి';

  @override
  String get logoutRow => 'లాగ్ అవుట్';

  @override
  String get logoutTitle => 'లాగ్ అవుట్ చేయాలా?';

  @override
  String get logoutBody => 'మళ్లీ లాగిన్ అయ్యే వరకు మీకు కొత్త ఆర్డర్‌లు రావు.';

  @override
  String get logoutBtn => 'లాగ్ అవుట్';

  @override
  String get cancelBtn => 'రద్దు చేయండి';

  @override
  String get greetingMorning => 'శుభోదయం';

  @override
  String get greetingAfternoon => 'శుభ మధ్యాహ్నం';

  @override
  String get greetingEvening => 'శుభ సాయంత్రం';

  @override
  String get online => 'ఆన్‌లైన్';

  @override
  String get offline => 'ఆఫ్‌లైన్';

  @override
  String get change => 'మార్చండి';

  @override
  String get newOrderPill => 'కొత్త ఆర్డర్ · అంగీకరించడానికి నొక్కండి';

  @override
  String nextPill(String status) {
    return 'తదుపరి · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code మార్గంలో ఉంది';
  }

  @override
  String orderAtHub(String code) {
    return '#$code హబ్‌లో వేచి ఉంది';
  }

  @override
  String get viewOrder => 'ఆర్డర్ చూడండి';

  @override
  String get continueBtn => 'కొనసాగించండి';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count క్రేట్‌లు',
      one: '$count క్రేట్',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'ఆర్డర్‌లను తనిఖీ చేస్తున్నాము…';

  @override
  String get allCaughtUp => 'అన్నీ అప్‌డేట్ అయ్యాయి';

  @override
  String get loadingOrders => 'మీ ఆర్డర్‌లు లోడ్ అవుతున్నాయి';

  @override
  String get noOrders => 'ప్రస్తుతం ఆర్డర్‌లు ఏవీ లేవు';

  @override
  String get stayOnline =>
      'మీ ప్రాంతంలో ఆన్‌లైన్‌లో ఉండండి. హబ్ ఆర్డర్‌లను కేటాయించినప్పుడు అవి ఇక్కడ కనిపిస్తాయి.';

  @override
  String get goOnline =>
      'మీ హబ్ నుండి ఆర్డర్‌లను పొందడానికి ఆన్‌లైన్‌లోకి వెళ్లండి.';

  @override
  String get creating => 'సృష్టిస్తోంది…';

  @override
  String get createDemo => 'డెమో ఆర్డర్ సృష్టించండి (ట్రయల్)';

  @override
  String get thenDeliverTo => 'తర్వాత ఇక్కడ డెలివరీ చేయండి';

  @override
  String get yourDaySoFar => 'ఈరోజు మీ పని';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ఈరోజు $count డెలివరీలు',
      one: 'ఈరోజు $count డెలివరీ',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'ఆర్డర్‌ను అప్పగించిన వెంటనే మీ ఆదాయం ఖాతాలో జమ అవుతుంది';

  @override
  String get viewEarnings => 'ఆదాయాన్ని చూడండి →';

  @override
  String todayEarned(String amount) {
    return 'ఈరోజు సంపాదన: $amount';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'విత్‌డ్రా చేసుకోవడానికి అందుబాటులో ఉంది: $amount';
  }

  @override
  String moreQueued(num count) {
    return 'మరో $count క్యూలో ఉన్నాయి';
  }

  @override
  String get errStatus => 'మీ స్థితిని మార్చలేకపోయాము';

  @override
  String demoCreated(String code, String demoCode) {
    return 'డెమో ఆర్డర్ $code సృష్టించబడింది · డెలివరీ కోడ్ $demoCode';
  }

  @override
  String get errDemo => 'డెమో ఆర్డర్‌ను సృష్టించలేకపోయాము';
}
