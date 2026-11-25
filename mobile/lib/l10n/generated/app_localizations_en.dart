// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get navProfile => 'Profile';

  @override
  String stepOf5(num step) {
    return 'Step $step of 5';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get langDefault => 'Default';

  @override
  String get langEn => 'English';

  @override
  String get langTa => 'தமிழ்';

  @override
  String get langSi => 'සිංහල';

  @override
  String get notAdded => 'Not added';

  @override
  String get statusAssigned => 'New order';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusAtPickup => 'At pickup';

  @override
  String get statusPickedUp => 'Picked up';

  @override
  String get statusArrived => 'Arrived';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get secDeliveries => 'DELIVERIES';

  @override
  String get autoAcceptTitle => 'Auto-accept nearby orders';

  @override
  String get autoAcceptSub => 'Within 2 km of your location';

  @override
  String get zoneTitle => 'City, hub & delivery radius';

  @override
  String get noHub => 'No hub';

  @override
  String get navTitle => 'Navigation';

  @override
  String get navInApp => 'In-app maps';

  @override
  String get navGoogleMaps => 'Google Maps · turn-by-turn';

  @override
  String get secAlerts => 'ALERTS';

  @override
  String get newOrderSoundTitle => 'New order sound';

  @override
  String get newOrderSoundSub => 'Plays even on silent';

  @override
  String get payoutAlertsTitle => 'Payout & bonus alerts';

  @override
  String get offersTitle => 'Offers & campaigns';

  @override
  String get secApp => 'APP';

  @override
  String get darkModeTitle => 'Dark mode for night shifts';

  @override
  String get dataSaverTitle => 'Data saver';

  @override
  String get dataSaverSub => 'Lighter maps on 3G / weak signal';

  @override
  String get secSecurity => 'SECURITY';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get fingerprintTitle => 'Fingerprint unlock';

  @override
  String get loadingSettings => 'Loading settings…';

  @override
  String get errLoadSettings => 'Could not load settings';

  @override
  String get errSaveSetting => 'Could not save that setting';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageDesc =>
      'Choose the language for menus, alerts and voice navigation.';

  @override
  String get voiceNavTitle => 'Voice navigation in same language';

  @override
  String get voiceNavSub => 'Turn-by-turn directions';

  @override
  String get saving => 'SAVING…';

  @override
  String get apply => 'APPLY';

  @override
  String languageSetTo(String name) {
    return 'Language set to $name';
  }

  @override
  String get errChangeLanguage => 'Could not change the language';

  @override
  String get profileTitle => 'Profile';

  @override
  String get kycVerified => 'KYC verified';

  @override
  String get kycInReview => 'KYC in review';

  @override
  String get kycNotStarted => 'KYC not started';

  @override
  String get kycNeedsAttention => 'KYC needs attention';

  @override
  String partnerId(String code, String place) {
    return 'Partner ID $code · $place';
  }

  @override
  String get statRating => 'Rating';

  @override
  String get statDeliveries => 'Deliveries';

  @override
  String get statPartnerSince => 'Partner since';

  @override
  String get secAccount => 'ACCOUNT';

  @override
  String get personalInfoTitle => 'Personal info';

  @override
  String get documentsTitle => 'Documents';

  @override
  String docsToUpload(num count) {
    return '$count to upload';
  }

  @override
  String docsExpiring(num count) {
    return '$count expiring';
  }

  @override
  String get bankTitle => 'Bank & UPI';

  @override
  String get vehicleTitle => 'Vehicle';

  @override
  String get secAppSupport => 'APP & SUPPORT';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get sosContacts => 'SOS & emergency contacts';

  @override
  String get aboutApp => 'About VP Nexues';

  @override
  String get logoutRow => 'Log out';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutBody =>
      'You’ll stop receiving new orders until you log in again.';

  @override
  String get logoutBtn => 'LOG OUT';

  @override
  String get cancelBtn => 'CANCEL';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get change => 'Change';

  @override
  String get newOrderPill => 'New order · tap to accept';

  @override
  String nextPill(String status) {
    return 'Next · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code is on its way';
  }

  @override
  String orderAtHub(String code) {
    return '#$code is waiting at the hub';
  }

  @override
  String get viewOrder => 'View order';

  @override
  String get continueBtn => 'Continue';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crates',
      one: '$count crate',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'Checking orders…';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get loadingOrders => 'Loading your orders';

  @override
  String get noOrders => 'No orders right now';

  @override
  String get stayOnline =>
      'Stay online inside your zone. New orders appear here the moment the hub assigns them.';

  @override
  String get goOnline => 'Go online to start receiving orders from your hub.';

  @override
  String get creating => 'CREATING…';

  @override
  String get createDemo => 'CREATE A DEMO ORDER (TRIAL)';

  @override
  String get thenDeliverTo => 'Then deliver to';

  @override
  String get yourDaySoFar => 'Your day so far';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deliveries today',
      one: '$count delivery today',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'Earnings are credited the moment you hand over';

  @override
  String get viewEarnings => 'View earnings →';

  @override
  String todayEarned(String amount) {
    return 'Today: $amount earned';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'Available to withdraw: $amount';
  }

  @override
  String moreQueued(num count) {
    return '$count more queued';
  }

  @override
  String get errStatus => 'Could not change your status';

  @override
  String demoCreated(String code, String demoCode) {
    return 'Demo order $code created · delivery code $demoCode';
  }

  @override
  String get errDemo => 'Could not create a demo order';
}
