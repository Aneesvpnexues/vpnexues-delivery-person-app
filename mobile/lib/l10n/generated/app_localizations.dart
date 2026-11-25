import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ms'),
    Locale('ms', 'SG'),
    Locale('si'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @stepOf5.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 5'**
  String stepOf5(num step);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @langDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get langDefault;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langTa.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get langTa;

  /// No description provided for @langSi.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get langSi;

  /// No description provided for @notAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notAdded;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get statusAssigned;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusAtPickup.
  ///
  /// In en, this message translates to:
  /// **'At pickup'**
  String get statusAtPickup;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get statusPickedUp;

  /// No description provided for @statusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get statusArrived;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @secDeliveries.
  ///
  /// In en, this message translates to:
  /// **'DELIVERIES'**
  String get secDeliveries;

  /// No description provided for @autoAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept nearby orders'**
  String get autoAcceptTitle;

  /// No description provided for @autoAcceptSub.
  ///
  /// In en, this message translates to:
  /// **'Within 2 km of your location'**
  String get autoAcceptSub;

  /// No description provided for @zoneTitle.
  ///
  /// In en, this message translates to:
  /// **'City, hub & delivery radius'**
  String get zoneTitle;

  /// No description provided for @noHub.
  ///
  /// In en, this message translates to:
  /// **'No hub'**
  String get noHub;

  /// No description provided for @navTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navTitle;

  /// No description provided for @navInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app maps'**
  String get navInApp;

  /// No description provided for @navGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps · turn-by-turn'**
  String get navGoogleMaps;

  /// No description provided for @secAlerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS'**
  String get secAlerts;

  /// No description provided for @newOrderSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'New order sound'**
  String get newOrderSoundTitle;

  /// No description provided for @newOrderSoundSub.
  ///
  /// In en, this message translates to:
  /// **'Plays even on silent'**
  String get newOrderSoundSub;

  /// No description provided for @payoutAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout & bonus alerts'**
  String get payoutAlertsTitle;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers & campaigns'**
  String get offersTitle;

  /// No description provided for @secApp.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get secApp;

  /// No description provided for @darkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode for night shifts'**
  String get darkModeTitle;

  /// No description provided for @dataSaverTitle.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get dataSaverTitle;

  /// No description provided for @dataSaverSub.
  ///
  /// In en, this message translates to:
  /// **'Lighter maps on 3G / weak signal'**
  String get dataSaverSub;

  /// No description provided for @secSecurity.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get secSecurity;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @fingerprintTitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock'**
  String get fingerprintTitle;

  /// No description provided for @loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings…'**
  String get loadingSettings;

  /// No description provided for @errLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings'**
  String get errLoadSettings;

  /// No description provided for @errSaveSetting.
  ///
  /// In en, this message translates to:
  /// **'Could not save that setting'**
  String get errSaveSetting;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for menus, alerts and voice navigation.'**
  String get appLanguageDesc;

  /// No description provided for @voiceNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice navigation in same language'**
  String get voiceNavTitle;

  /// No description provided for @voiceNavSub.
  ///
  /// In en, this message translates to:
  /// **'Turn-by-turn directions'**
  String get voiceNavSub;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get saving;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get apply;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to {name}'**
  String languageSetTo(String name);

  /// No description provided for @errChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Could not change the language'**
  String get errChangeLanguage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'KYC verified'**
  String get kycVerified;

  /// No description provided for @kycInReview.
  ///
  /// In en, this message translates to:
  /// **'KYC in review'**
  String get kycInReview;

  /// No description provided for @kycNotStarted.
  ///
  /// In en, this message translates to:
  /// **'KYC not started'**
  String get kycNotStarted;

  /// No description provided for @kycNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'KYC needs attention'**
  String get kycNeedsAttention;

  /// No description provided for @partnerId.
  ///
  /// In en, this message translates to:
  /// **'Partner ID {code} · {place}'**
  String partnerId(String code, String place);

  /// No description provided for @statRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// No description provided for @statDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get statDeliveries;

  /// No description provided for @statPartnerSince.
  ///
  /// In en, this message translates to:
  /// **'Partner since'**
  String get statPartnerSince;

  /// No description provided for @secAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get secAccount;

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfoTitle;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @docsToUpload.
  ///
  /// In en, this message translates to:
  /// **'{count} to upload'**
  String docsToUpload(num count);

  /// No description provided for @docsExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring'**
  String docsExpiring(num count);

  /// No description provided for @bankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank & UPI'**
  String get bankTitle;

  /// No description provided for @vehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleTitle;

  /// No description provided for @secAppSupport.
  ///
  /// In en, this message translates to:
  /// **'APP & SUPPORT'**
  String get secAppSupport;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @sosContacts.
  ///
  /// In en, this message translates to:
  /// **'SOS & emergency contacts'**
  String get sosContacts;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About VP Nexues'**
  String get aboutApp;

  /// No description provided for @logoutRow.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutRow;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutBody.
  ///
  /// In en, this message translates to:
  /// **'You’ll stop receiving new orders until you log in again.'**
  String get logoutBody;

  /// No description provided for @logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logoutBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelBtn;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @newOrderPill.
  ///
  /// In en, this message translates to:
  /// **'New order · tap to accept'**
  String get newOrderPill;

  /// No description provided for @nextPill.
  ///
  /// In en, this message translates to:
  /// **'Next · {status}'**
  String nextPill(String status);

  /// No description provided for @orderOnWay.
  ///
  /// In en, this message translates to:
  /// **'#{code} is on its way'**
  String orderOnWay(String code);

  /// No description provided for @orderAtHub.
  ///
  /// In en, this message translates to:
  /// **'#{code} is waiting at the hub'**
  String orderAtHub(String code);

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get viewOrder;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @crates.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{{count} crate} other{{count} crates}}'**
  String crates(num count);

  /// No description provided for @checkingOrders.
  ///
  /// In en, this message translates to:
  /// **'Checking orders…'**
  String get checkingOrders;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading your orders'**
  String get loadingOrders;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders right now'**
  String get noOrders;

  /// No description provided for @stayOnline.
  ///
  /// In en, this message translates to:
  /// **'Stay online inside your zone. New orders appear here the moment the hub assigns them.'**
  String get stayOnline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online to start receiving orders from your hub.'**
  String get goOnline;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'CREATING…'**
  String get creating;

  /// No description provided for @createDemo.
  ///
  /// In en, this message translates to:
  /// **'CREATE A DEMO ORDER (TRIAL)'**
  String get createDemo;

  /// No description provided for @thenDeliverTo.
  ///
  /// In en, this message translates to:
  /// **'Then deliver to'**
  String get thenDeliverTo;

  /// No description provided for @yourDaySoFar.
  ///
  /// In en, this message translates to:
  /// **'Your day so far'**
  String get yourDaySoFar;

  /// No description provided for @deliveriesToday.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{{count} delivery today} other{{count} deliveries today}}'**
  String deliveriesToday(num count);

  /// No description provided for @earningsCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Earnings are credited the moment you hand over'**
  String get earningsCreditNote;

  /// No description provided for @viewEarnings.
  ///
  /// In en, this message translates to:
  /// **'View earnings →'**
  String get viewEarnings;

  /// No description provided for @todayEarned.
  ///
  /// In en, this message translates to:
  /// **'Today: {amount} earned'**
  String todayEarned(String amount);

  /// No description provided for @availableToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw: {amount}'**
  String availableToWithdraw(String amount);

  /// No description provided for @moreQueued.
  ///
  /// In en, this message translates to:
  /// **'{count} more queued'**
  String moreQueued(num count);

  /// No description provided for @errStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not change your status'**
  String get errStatus;

  /// No description provided for @demoCreated.
  ///
  /// In en, this message translates to:
  /// **'Demo order {code} created · delivery code {demoCode}'**
  String demoCreated(String code, String demoCode);

  /// No description provided for @errDemo.
  ///
  /// In en, this message translates to:
  /// **'Could not create a demo order'**
  String get errDemo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'ml',
    'ms',
    'si',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ms':
      {
        switch (locale.countryCode) {
          case 'SG':
            return AppLocalizationsMsSg();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ms':
      return AppLocalizationsMs();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
