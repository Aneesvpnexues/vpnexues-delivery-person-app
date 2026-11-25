// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get navHome => 'Laman Utama';

  @override
  String get navOrders => 'Pesanan';

  @override
  String get navEarnings => 'Pendapatan';

  @override
  String get navProfile => 'Profil';

  @override
  String stepOf5(num step) {
    return 'Langkah $step daripada 5';
  }

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get langDefault => 'Lalai';

  @override
  String get langEn => 'Bahasa Inggeris';

  @override
  String get langTa => 'Bahasa Tamil';

  @override
  String get langSi => 'Bahasa Sinhala';

  @override
  String get notAdded => 'Belum ditambah';

  @override
  String get statusAssigned => 'Pesanan baharu';

  @override
  String get statusAccepted => 'Diterima';

  @override
  String get statusAtPickup => 'Di lokasi pengambilan';

  @override
  String get statusPickedUp => 'Telah diambil';

  @override
  String get statusArrived => 'Telah tiba';

  @override
  String get statusDelivered => 'Telah dihantar';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get secDeliveries => 'Penghantaran';

  @override
  String get autoAcceptTitle => 'Terima pesanan berdekatan secara automatik';

  @override
  String get autoAcceptSub => 'Dalam lingkungan 2 km dari lokasi anda';

  @override
  String get zoneTitle => 'Bandar, hab dan kawasan penghantaran';

  @override
  String get noHub => 'Tiada hab';

  @override
  String get navTitle => 'Navigasi';

  @override
  String get navInApp => 'Peta dalam aplikasi';

  @override
  String get navGoogleMaps => 'Google Maps · Panduan langkah demi langkah';

  @override
  String get secAlerts => 'Amaran';

  @override
  String get newOrderSoundTitle => 'Bunyi pesanan baharu';

  @override
  String get newOrderSoundSub =>
      'Bunyi akan dimainkan walaupun dalam mod senyap';

  @override
  String get payoutAlertsTitle => 'Amaran pembayaran dan bonus';

  @override
  String get offersTitle => 'Tawaran dan kempen';

  @override
  String get secApp => 'Aplikasi';

  @override
  String get darkModeTitle => 'Mod gelap untuk syif malam';

  @override
  String get dataSaverTitle => 'Penjimatan data';

  @override
  String get dataSaverSub => 'Peta ringan untuk 3G / isyarat lemah';

  @override
  String get secSecurity => 'Keselamatan';

  @override
  String get changePasswordTitle => 'Tukar kata laluan';

  @override
  String get fingerprintTitle => 'Buka kunci dengan cap jari';

  @override
  String get loadingSettings => 'Memuatkan tetapan…';

  @override
  String get errLoadSettings => 'Tetapan tidak dapat dimuatkan';

  @override
  String get errSaveSetting => 'Tetapan ini tidak dapat disimpan';

  @override
  String get appLanguageTitle => 'Bahasa aplikasi';

  @override
  String get appLanguageDesc =>
      'Pilih bahasa untuk menu, amaran dan navigasi suara.';

  @override
  String get voiceNavTitle => 'Navigasi suara dalam bahasa yang sama';

  @override
  String get voiceNavSub => 'Arahan langkah demi langkah';

  @override
  String get saving => 'Menyimpan…';

  @override
  String get apply => 'Gunakan';

  @override
  String languageSetTo(String name) {
    return 'Bahasa ditetapkan kepada $name';
  }

  @override
  String get errChangeLanguage => 'Bahasa tidak dapat ditukar';

  @override
  String get profileTitle => 'Profil';

  @override
  String get kycVerified => 'KYC disahkan';

  @override
  String get kycInReview => 'KYC sedang disemak';

  @override
  String get kycNotStarted => 'KYC belum dimulakan';

  @override
  String get kycNeedsAttention => 'KYC memerlukan perhatian';

  @override
  String partnerId(String code, String place) {
    return 'ID Rakan Kongsi $code · $place';
  }

  @override
  String get statRating => 'Penilaian';

  @override
  String get statDeliveries => 'Penghantaran';

  @override
  String get statPartnerSince => 'Rakan kongsi sejak';

  @override
  String get secAccount => 'Akaun';

  @override
  String get personalInfoTitle => 'Maklumat peribadi';

  @override
  String get documentsTitle => 'Dokumen';

  @override
  String docsToUpload(num count) {
    return '$count untuk dimuat naik';
  }

  @override
  String docsExpiring(num count) {
    return '$count akan tamat tempoh';
  }

  @override
  String get bankTitle => 'Bank dan UPI';

  @override
  String get vehicleTitle => 'Kenderaan';

  @override
  String get secAppSupport => 'Aplikasi dan sokongan';

  @override
  String get helpSupport => 'Bantuan dan sokongan';

  @override
  String get sosContacts => 'SOS dan kenalan kecemasan';

  @override
  String get aboutApp => 'Tentang VP Nexues';

  @override
  String get logoutRow => 'Log keluar';

  @override
  String get logoutTitle => 'Log keluar?';

  @override
  String get logoutBody =>
      'Anda tidak akan menerima pesanan baharu sehingga anda log masuk semula.';

  @override
  String get logoutBtn => 'Log keluar';

  @override
  String get cancelBtn => 'Batal';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat tengah hari';

  @override
  String get greetingEvening => 'Selamat petang';

  @override
  String get online => 'Dalam talian';

  @override
  String get offline => 'Luar talian';

  @override
  String get change => 'Tukar';

  @override
  String get newOrderPill => 'Pesanan baharu · Ketik untuk menerima';

  @override
  String nextPill(String status) {
    return 'Seterusnya · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code sedang dalam perjalanan';
  }

  @override
  String orderAtHub(String code) {
    return '#$code sedang menunggu di hab';
  }

  @override
  String get viewOrder => 'Lihat pesanan';

  @override
  String get continueBtn => 'Teruskan';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peti',
      one: '$count peti',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'Menyemak pesanan…';

  @override
  String get allCaughtUp => 'Semua sudah dikemas kini';

  @override
  String get loadingOrders => 'Memuatkan pesanan anda';

  @override
  String get noOrders => 'Tiada pesanan buat masa ini';

  @override
  String get stayOnline =>
      'Kekal dalam talian di kawasan anda. Pesanan baharu akan muncul di sini apabila diberikan oleh hab.';

  @override
  String get goOnline =>
      'Pergi dalam talian untuk menerima pesanan daripada hab anda.';

  @override
  String get creating => 'Sedang mencipta…';

  @override
  String get createDemo => 'Cipta pesanan demo (percubaan)';

  @override
  String get thenDeliverTo => 'Kemudian hantar ke sini';

  @override
  String get yourDaySoFar => 'Aktiviti anda hari ini';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penghantaran hari ini',
      one: '$count penghantaran hari ini',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'Pendapatan dikreditkan ke akaun anda sebaik sahaja pesanan diserahkan';

  @override
  String get viewEarnings => 'Lihat pendapatan →';

  @override
  String todayEarned(String amount) {
    return 'Pendapatan hari ini: $amount';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'Tersedia untuk dikeluarkan: $amount';
  }

  @override
  String moreQueued(num count) {
    return '$count lagi dalam barisan';
  }

  @override
  String get errStatus => 'Status anda tidak dapat ditukar';

  @override
  String demoCreated(String code, String demoCode) {
    return 'Pesanan demo $code telah dicipta · Kod penghantaran $demoCode';
  }

  @override
  String get errDemo => 'Pesanan demo tidak dapat dicipta';
}

/// The translations for Malay, as used in Singapore (`ms_SG`).
class AppLocalizationsMsSg extends AppLocalizationsMs {
  AppLocalizationsMsSg() : super('ms_SG');

  @override
  String get navHome => 'Laman Utama';

  @override
  String get navOrders => 'Pesanan';

  @override
  String get navEarnings => 'Pendapatan';

  @override
  String get navProfile => 'Profil';

  @override
  String stepOf5(num step) {
    return 'Langkah $step daripada 5';
  }

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get langDefault => 'Lalai';

  @override
  String get langEn => 'Inggeris';

  @override
  String get langTa => 'Tamil';

  @override
  String get langSi => 'Sinhala';

  @override
  String get notAdded => 'Belum ditambah';

  @override
  String get statusAssigned => 'Pesanan baharu';

  @override
  String get statusAccepted => 'Diterima';

  @override
  String get statusAtPickup => 'Di lokasi pengambilan';

  @override
  String get statusPickedUp => 'Telah diambil';

  @override
  String get statusArrived => 'Telah tiba';

  @override
  String get statusDelivered => 'Telah dihantar';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get secDeliveries => 'PENGHANTARAN';

  @override
  String get autoAcceptTitle => 'Terima pesanan berdekatan secara automatik';

  @override
  String get autoAcceptSub => 'Dalam lingkungan 2 km dari lokasi anda';

  @override
  String get zoneTitle => 'Bandar, hab & kawasan penghantaran';

  @override
  String get noHub => 'Tiada hab';

  @override
  String get navTitle => 'Navigasi';

  @override
  String get navInApp => 'Peta dalam aplikasi';

  @override
  String get navGoogleMaps => 'Google Maps · panduan langkah demi langkah';

  @override
  String get secAlerts => 'PEMBERITAHUAN';

  @override
  String get newOrderSoundTitle => 'Bunyi pesanan baharu';

  @override
  String get newOrderSoundSub => 'Berbunyi walaupun dalam mod senyap';

  @override
  String get payoutAlertsTitle => 'Pemberitahuan bayaran & bonus';

  @override
  String get offersTitle => 'Tawaran & kempen';

  @override
  String get secApp => 'APLIKASI';

  @override
  String get darkModeTitle => 'Mod gelap untuk syif malam';

  @override
  String get dataSaverTitle => 'Penjimatan data';

  @override
  String get dataSaverSub => 'Peta lebih ringan pada 3G / isyarat lemah';

  @override
  String get secSecurity => 'KESELAMATAN';

  @override
  String get changePasswordTitle => 'Tukar kata laluan';

  @override
  String get fingerprintTitle => 'Buka kunci dengan cap jari';

  @override
  String get loadingSettings => 'Memuatkan tetapan…';

  @override
  String get errLoadSettings => 'Tidak dapat memuatkan tetapan';

  @override
  String get errSaveSetting => 'Tidak dapat menyimpan tetapan tersebut';

  @override
  String get appLanguageTitle => 'Bahasa aplikasi';

  @override
  String get appLanguageDesc =>
      'Pilih bahasa untuk menu, pemberitahuan dan navigasi suara.';

  @override
  String get voiceNavTitle => 'Navigasi suara dalam bahasa yang sama';

  @override
  String get voiceNavSub => 'Arahan langkah demi langkah';

  @override
  String get saving => 'MENYIMPAN…';

  @override
  String get apply => 'GUNAKAN';

  @override
  String languageSetTo(String name) {
    return 'Bahasa ditetapkan kepada $name';
  }

  @override
  String get errChangeLanguage => 'Tidak dapat menukar bahasa';

  @override
  String get profileTitle => 'Profil';

  @override
  String get kycVerified => 'KYC disahkan';

  @override
  String get kycInReview => 'KYC sedang disemak';

  @override
  String get kycNotStarted => 'KYC belum dimulakan';

  @override
  String get kycNeedsAttention => 'KYC memerlukan perhatian';

  @override
  String partnerId(String code, String place) {
    return 'ID rakan kongsi $code · $place';
  }

  @override
  String get statRating => 'Penilaian';

  @override
  String get statDeliveries => 'Penghantaran';

  @override
  String get statPartnerSince => 'Rakan kongsi sejak';

  @override
  String get secAccount => 'AKAUN';

  @override
  String get personalInfoTitle => 'Maklumat peribadi';

  @override
  String get documentsTitle => 'Dokumen';

  @override
  String docsToUpload(num count) {
    return '$count untuk dimuat naik';
  }

  @override
  String docsExpiring(num count) {
    return '$count akan tamat tempoh';
  }

  @override
  String get bankTitle => 'Bank & UPI';

  @override
  String get vehicleTitle => 'Kenderaan';

  @override
  String get secAppSupport => 'APLIKASI & SOKONGAN';

  @override
  String get helpSupport => 'Bantuan & sokongan';

  @override
  String get sosContacts => 'SOS & kenalan kecemasan';

  @override
  String get aboutApp => 'Perihal VP Nexues';

  @override
  String get logoutRow => 'Log keluar';

  @override
  String get logoutTitle => 'Log keluar?';

  @override
  String get logoutBody =>
      'Anda tidak akan menerima pesanan baharu sehingga anda log masuk semula.';

  @override
  String get logoutBtn => 'LOG KELUAR';

  @override
  String get cancelBtn => 'BATAL';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat tengah hari';

  @override
  String get greetingEvening => 'Selamat petang';

  @override
  String get online => 'Dalam talian';

  @override
  String get offline => 'Luar talian';

  @override
  String get change => 'Tukar';

  @override
  String get newOrderPill => 'Pesanan baharu · ketik untuk menerima';

  @override
  String nextPill(String status) {
    return 'Seterusnya · $status';
  }

  @override
  String orderOnWay(String code) {
    return '#$code sedang dalam perjalanan';
  }

  @override
  String orderAtHub(String code) {
    return '#$code sedang menunggu di hab';
  }

  @override
  String get viewOrder => 'Lihat pesanan';

  @override
  String get continueBtn => 'Teruskan';

  @override
  String crates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peti',
      one: '$count peti',
    );
    return '$_temp0';
  }

  @override
  String get checkingOrders => 'Menyemak pesanan…';

  @override
  String get allCaughtUp => 'Anda sudah mengikuti perkembangan terkini';

  @override
  String get loadingOrders => 'Memuatkan pesanan anda';

  @override
  String get noOrders => 'Tiada pesanan buat masa ini';

  @override
  String get stayOnline =>
      'Kekal dalam talian di dalam zon anda. Pesanan baharu akan muncul di sini sebaik sahaja hab menetapkannya.';

  @override
  String get goOnline =>
      'Pergi dalam talian untuk mula menerima pesanan daripada hab anda.';

  @override
  String get creating => 'SEDANG MENCIPTA…';

  @override
  String get createDemo => 'CIPTA PESANAN DEMO (PERCUBAAN)';

  @override
  String get thenDeliverTo => 'Kemudian hantar ke';

  @override
  String get yourDaySoFar => 'Aktiviti anda hari ini';

  @override
  String deliveriesToday(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penghantaran hari ini',
      one: '$count penghantaran hari ini',
    );
    return '$_temp0';
  }

  @override
  String get earningsCreditNote =>
      'Pendapatan dikreditkan sebaik sahaja anda menyerahkan pesanan';

  @override
  String get viewEarnings => 'Lihat pendapatan →';

  @override
  String todayEarned(String amount) {
    return 'Pendapatan hari ini: $amount';
  }

  @override
  String availableToWithdraw(String amount) {
    return 'Tersedia untuk dikeluarkan: $amount';
  }

  @override
  String moreQueued(num count) {
    return '$count lagi dalam barisan';
  }

  @override
  String get errStatus => 'Tidak dapat menukar status anda';

  @override
  String demoCreated(String code, String demoCode) {
    return 'Pesanan demo $code dicipta · kod penghantaran $demoCode';
  }

  @override
  String get errDemo => 'Tidak dapat mencipta pesanan demo';
}
