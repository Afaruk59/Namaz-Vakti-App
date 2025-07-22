import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localization_ar.dart';
import 'app_localization_de.dart';
import 'app_localization_en.dart';
import 'app_localization_es.dart';
import 'app_localization_fr.dart';
import 'app_localization_it.dart';
import 'app_localization_ru.dart';
import 'app_localization_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localization.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ru'),
    Locale('tr')
  ];

  /// Language
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get lang;

  /// Application Name
  ///
  /// In tr, this message translates to:
  /// **'Namaz Vakti App'**
  String get appName;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Vakitler'**
  String get timesPageTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Kıble Pusulası'**
  String get qiblaPageTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Zikir'**
  String get zikirPageTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla'**
  String get morePageTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsPageTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Mübarek Günler ve Geceler'**
  String get datesTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Mübarek Günler'**
  String get datesTitleShort;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Kaza Takibi'**
  String get kazaTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Kaynak Kitaplar'**
  String get booksTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Github Sayfası'**
  String get githubTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Lisans'**
  String get licenseTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Konum Arama'**
  String get searchTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirin'**
  String get rate;

  /// Navbar text
  ///
  /// In tr, this message translates to:
  /// **'Vakitler'**
  String get nav1;

  /// Navbar text
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get nav2;

  /// Navbar text
  ///
  /// In tr, this message translates to:
  /// **'Zikir'**
  String get nav3;

  /// Navbar text
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla'**
  String get nav4;

  /// Navbar text
  ///
  /// In tr, this message translates to:
  /// **'Kitaplar'**
  String get nav5;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get locationButtonText;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get leave;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get remove;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İmsak'**
  String get imsak;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Sabah'**
  String get sabah;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get gunes;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get ogle;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get ikindi;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get aksam;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Yatsı'**
  String get yatsi;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İşrak'**
  String get israk;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Kerahat'**
  String get kerahat;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Asr-ı Sani'**
  String get asrisani;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İsfirar-ı Şems'**
  String get isfirar;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İstibak-ı Nücum'**
  String get istibak;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İşa-i Sani'**
  String get isaisani;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get kible;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Vitir'**
  String get vitir;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Oruç'**
  String get oruc;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İmsaka Kalan'**
  String get timeLeftImsak;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Sabaha Kalan'**
  String get timeLeftSabah;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Güneşe Kalan'**
  String get timeLeftGunes;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Öğleye Kalan'**
  String get timeLeftOgle;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İkindiye Kalan'**
  String get timeLeftIkindi;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Akşama Kalan'**
  String get timeLeftAksam;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Yatsıya Kalan'**
  String get timeLeftYatsi;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Günün Sözü:'**
  String get calendarTitle1;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Arka Yaprak:'**
  String get calendarTitle2;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Hedef:'**
  String get qiblaTargetText;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Zikir Sayısı'**
  String get zikirCount;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Biten:'**
  String get popupInfo1;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Çekilen:'**
  String get popupInfo2;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Zikiri Sıfırla'**
  String get resetMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Gerçekten sıfırlamak istiyor musunuz?'**
  String get resetMessageBody;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Zikir Sayısı:'**
  String get zikirMessageTitle;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get defaultProf;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Yeni Profil'**
  String get profileMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Profili Sil'**
  String get removeMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Gerçekten profili silmek istiyor musunuz?'**
  String get removeMessageBody;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get ln;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Uygulama yeniden başlatıldığında değişecektir.'**
  String get languageMessageBody;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Konum Takibi'**
  String get otoLocal;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Koyu Tema'**
  String get darkMode;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Geçişli Arkaplan'**
  String get gradient;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Tema Rengi'**
  String get themeColor;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Renk Seçimi'**
  String get colorPaletteTitle;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldiniz.'**
  String get startupTitle;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Vakitler Namazvakti.com\'dan alınmıştır.'**
  String get startupDescription;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Namaz Vakitleri Hakkında Mühim Tenbih'**
  String get tenbih;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Konum Aranıyor'**
  String get loading;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Konum Erişimi Gerekli'**
  String get locationMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için lütfen konumu etkinleştirin.'**
  String get locationMessageBody;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Konumu Aç'**
  String get openLoc;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni Gerekli'**
  String get permissionMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulamanın düzgün çalışabilmesi için konum izni gereklidir.'**
  String get permissionMessageBody;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı olarak reddedildi. Devam edebilmek için lütfen ayarlardan izin verin.'**
  String get permissionDeniedBody;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get openSettings;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'İnternet Bağlantısı Gerekli'**
  String get wifiMessageTitle;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için lütfen Wi-Fi\'yi yada Mobil Veri\'yi etkinleştirin.'**
  String get wifiMessageBody;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'(Servisler internet olmadan düzgün çalışmayacaktır.)'**
  String get wifiMessageBody2;

  /// Message text
  ///
  /// In tr, this message translates to:
  /// **'Kaza Sayısı:'**
  String get kazaMessageTitle;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Konumu Girin...'**
  String get enterLoc;

  /// Button text
  ///
  /// In tr, this message translates to:
  /// **'Konumu Bul'**
  String get locationButtonTextonStart;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Düzen'**
  String get layout;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Yuvarlak'**
  String get rounded;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Keskin'**
  String get sharp;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Tam İlmihâl Se`âdet-i Ebediyye'**
  String get ilmihal;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Mektûbat Tercemesi'**
  String get mektubat;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İslâm Ahlâkı'**
  String get islam;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Kıyâmet ve Âhıret'**
  String get kiyamet;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Namâz Kitâbı'**
  String get namaz;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Cevâb Veremedi'**
  String get cevab;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Eshâb-ı Kirâm'**
  String get eshabikiram;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Fâideli Bilgiler'**
  String get faideli;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Hak Sözün Vesîkaları'**
  String get haksoz;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Herkese Lâzım Olan Îmân'**
  String get iman;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İngiliz Câsûsunun İ`tirâfları'**
  String get ingiliz;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Kıymetsiz Yazılar'**
  String get kiymetsiz;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Menâkıb-ı Çihâr Yâr-i Güzîn'**
  String get menakib;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Şevâhid-ün Nübüvve'**
  String get sevahid;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'(Tam İlmihâl-Se’âdet-i Ebediyye) kitâbı, üç kısımdan meydâna gelmişdir: I. kısımda; İslâm dînine nasıl inanılacağı, ehl-i sünnet i’tikâdı, İslâm dinine iftirâ edenlere cevâblar, Kur\'ân-ı kerîm ve tefsîrler, kur\'ân-ı kerîmdeki ilmlerin sınıflandırılması, Nemâzın ehemmiyyeti, farzları, abdest, gusl, nemâz ile ilgili bütün husûslar, kaza nemâzları, Cum’a ve bayram nemâzları, Zekât, Ramezân Orucu, Sadaka-i Fıtr, Yemîn ve Yemîn Keffâreti, Adak, Kurban Kesmek, Hac, Mübârek Geceler, Hicrî ve Mîlâdî Senelerin birbirine çevrilmeleri, Selâmlaşmak, Muhammed aleyhisselâmın hayâtı, Mübârek ahlâkı, anne, baba ve dedelerinin mü’min oluşu, Sübhâne Rabbîke âyeti hakkında bilgiler... yer almakdadır. II. kısımda; Îmân, Akl, Kaza-Kader, Tefsîr ve Hadîs kitâbları, Hadîs âlimleri, Allahü teâlânın ismleri, Mezheb, Fıkh, İmâm-ı A’zam hazretleri, Vehhâbîlere Ehl-i Sünnetin cevâbı, Evliyâ rûhlarından faydalanma, Bozuk dinler, hurûfîlik, Sosyalizm ve Sosyâl adâlet, İslâmiyyetde nikâh, Talâk, Süt kardeşlik, Nafaka, Komşu hakkı, Halâl ve Harâmlar, İsrâf ve Fâiz, Fen Bilgileri, Tevekkül, Müzik ve Tegannî, Cin hakkında bilgi, Bir Müslimân babanın kızına nasîhatları, Mu’cîze, kerâmet, firâset, istidrâc ... gibi konular yer almakdadır. III. kısımda, İslâmiyyetde kesb ve ticâret, Bey’ ve Şirâ’, Alış-verişde muhayyerlik, Bâtıl, Fâsid ve Mekrûh Satışlar, Ticârette adâlet ve ihtikâr, dinini kayırmak, ihsân, Banka ve Fâiz, Şirketler, Cezâlar, Ölüm ve Ölüme Hâzırlık, Meyyite Hizmetler, Ferâiz, Meyyit için İskât ... gibi konular yer almakdadır. Ayrıca konular arasında, İmâm-ı Rabbânî hazretlerinin ve oğlu Muhammed Ma’sûm hazretlerinin (MEKTÛBÂT) kitâblarından çeşitli mektûblar vardır. Son bölümde (1020) zâtın hâl tercemesi yer almakdadır. Fihrist bölümünde zâtlar, kitâblar, mevzû\'lar fihristleri vardır. Bine yakın eserden uzun bir zemânda hâzırlanan bu nâdîde eserde; insanı se’âdete kavuşduracak bütün husûslar yer almakdadır.'**
  String get ilmihalInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'971 [m.1563] de doğan ve 1034 [m.1624] de vefât eden, ikinci bin yılın müceddîdi, İmâm-ı Rabbânî Ahmed Fârûkî Serhendi hazretleri, Kur’ân-ı kerîm ve Hadîs-i Şerîflerden sonra, en kıymetli üçüncü kitâb olan (MEKTÛBÂT) kitâbını yazmışdır. İnsanoğlunun rûhî hastalıklarının tedâvî yollarını göstermiş, islâm dînine nasıl inanılacağı, ibâdetlerin ehemmiyyeti, Evliyâlık, Resûlullahın güzel ahlâkı, islâmiyyet, tarîkat ve hakîkatin ayrı ayrı şeyler olmadıklarını îzâh etmişdir. Üç cild ve aslı fârisî olan mektûbât kitâbında (536) mektûb vardır.'**
  String get mektubatInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İslâm dîninin güzel ahlâkına ulaşmak için kurtulmak gereken 40 kötü ahlak ve bunlardan kurtulma çarelerinin anlatıldığı bu kitâbda aynı zamanda (Mızraklı İlmihâl) diye bilinen Muhammed bin Kutbüddîn İznîki hazretlerinin kitâbı esas alınarak yazılan Îmân ve ibâdet bilgilerini içeren Cennet Yolu İlmihâli bulunmaktadır.'**
  String get islamInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Kıyâmet ve Âhıret kitâbında insanın ölümü, rûhun bedenden ayrılması, kabr hayâtı, kabr süâlleri, kıyâmet günü insanların hesâba çekilmesi, Cennet ve Cehenneme nasıl gidileceği büyük islâm âlimi, İmâm-ı Gazâlî hazretlerinin kitâblarından terceme edilerek geniş olarak açıklanmakda ve vehhâbîliğe cevap vererek evliyâlığın ne olduğu, kıyâmet günü herkesin sevdiğinin yanında olacağı konuları açıklanmakdadır.'**
  String get kiyametInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Küçük bir ilmihal niteliğinde olan bu kitâbda her müslümanın bilmesi zaruri olan Ehl-i sünnet i\'tikâdı, namaz, abdest, gusl, teyemmüm, oruç, hac ve zekât bilgileri anlatılmaktadır. Namâz kitâbının sonunda, namâzın içinde ve dışında okunacak duâlar arabî olarak yer almaktadır. Namâz ve Namâzla ilgili bilgileri detaylıca içeren dokuz kısımdan oluşmaktadır.'**
  String get namazInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Îsâ aleyhisselâma gönderilen ve hak kitâb olan İncîlin tahrîf edilmesi ile ortaya çıkan dört kitâb [Matta İncîli, Markos İncîli, Luka İncîli, Yuhannâ İncîli] hakkında bilgi vermekde, aralarındaki ihtilâfları açıklamakdadır. Kur’ân-ı kerîm ile İncîl karşılaştırılmakda, İncîlin tahrîf edildiği, hükümlerinin yürürlükden kalkdığı, Kur’ân-ı kerîmin bütün semâvî kitâbların hükümlerini yürürlükden kaldırdığı îzâh edilmekdedir. Îsevîlikdeki teslîs (üç tanrı) inancının yanlış olduğu, Allahü teâlânın bir olduğu, ilim ve kudret sıfâtları ilmî olarak açıklanmakdadır. Îsâ aleyhisselâmın insan ve Peygamber olduğu, ona tapılmıyacağı îzâh edilmekdedir. Yehûdîlik, Tevrât ve Talmud hakkında da bilgi verilmekdedir.'**
  String get cevabInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Eshâb-ı Kirâm kitâbının başında, Peygamberimiz Muhammed aleyhisselâmın Eshâbının üstünlüğünü, Eshâb-ı kirâm arasındaki hâdiseler, Eshâb-ı kirâma dil uzatanların haksız ve câhil oldukları anlatılmakda, ayrıca; (İctihâd) ın ne olduğu açıklanmakdadır.'**
  String get eshabikiramInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İslâm dîni ve Ehl-i Sünnet i’tikâdı hakkında öz bilgiler verilen kitâbda, islâmî ilimlerin ve fıkh âlimlerinin sınıflandırılması, İmâm-ı A’zam Ebû Hanîfe hazretlerinin hayâtı anlatılmaktadır. Üç kısımdan meydâna gelen Fâideli Bilgiler kitâbında dinde reform yapmak isteyenlere, İslâm dinini bozan zararlı cereyân ve fikirlere ve cebriyye, mu’tezîle, vehhâbîlik gibi sapık fırkalara cevâb verilmektedir.'**
  String get faideliInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Hak sözün vesîkaları kitabı Şî’îlik, Ehl-i Beyt, Eshâb-ı kirâm ve Ehl-i Sünnet hakkında bilgiler vermekde, Ehl-i beyt ile Eshâb-ı kirâmın birbirlerini çok sevdiklerini açıklamakda ve şî’îlerin kitablarını ve iftirâlarını gâyet ilmî olarak cevâblamakdadır. Komünistlik ve din düşmanlığı hakkında bilgiler de veren kitâbda İmâm-ı Gazâlî hazretlerinin (Eyyühel-Veled) tercemesi ve İmâm-ı Rabbânî hazretlerinin hâl tercemesi de bulunmaktadır.'**
  String get haksozInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İslâm dîninin bilinmesi gereken îmân esaslarını ve îmânın altı şartını kaynak kitaplardan aktararak detaylı bir şekilde açıklayan bu kitâb, aynı zamanda diğer dînler hakkında bilgiler de verip İslâmiyyet ile karşılaşdırmakdadır.'**
  String get imanInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'1700’lü yıllarda İstanbul’a gelen ve orada çeşidli islâmi ilimleri ve lîsanları öğrenen İngiliz casusu Hempher’in, İslâm dünyâsını ve müslimânları parçalamak için yaptığı casusluk faaliyetlerini ve vehhâbîliği nasıl kurduğunu anlattığı hatıratının tercümesini içeren bu kitâb 3 bölümden oluşmaktadır.'**
  String get ingilizInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'İmâm-ı Rabbânî Müceddîd-i Elf-i sânî Ahmed Fârûkî Serhendi hazretlerinin üç cild (MEKTÛBÂT) kitâbından ve oğulları Muhammed Ma’sûm-i Fârûkî hazretlerinin de üç cild (MEKTÛBÂT) kitâbından, çıkarılan kıymetli cümleler, Elif-ba sırasına göre tanzîm edilmiş, Seyyid Abdülhakîm Arvâsî hazretlerine okunmuşdur. Dikkat ile dinledikden sonra, bunun adı (Kıymetsiz Yazılar) olsun demişdir. Okuyanın hayreti üzere, anlamadın mı, (Bunun kıymetine karşılık olabilecek birşey bulunabilir mi?) buyurmuşdur. Son sayfasında şu cümleler yer almakdadır: (Fırsat ganîmetdir. Ömrün temâmını fâidesiz işlerle telef ve sarf etmemek lâzımdır. Belki temâm ömrü, Hak celle ve a’lânın rızâsına muvâfık ve mutâbık şeylere sarf etmek lâzımdır....)'**
  String get kiymetsizInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Dört halîfenin ve Eshâb-ı Kirâmın bütününün büyüklüklerini, kıymetlerini menkıbeler ile çok uzun ve çok güzel anlatan bu kitâb, türkçe olup, ilk defa 1325 senesinde basılmıştır. Kitabevimiz yeniden 1998\'de basdırmıştır. Bu kitâbı Seyyid Eyyûb hazretleri yazmıştır. On iki bâb dan oluşmakdadır.'**
  String get menakibInfo;

  /// Text
  ///
  /// In tr, this message translates to:
  /// **'Şevâhid-ün Nübüvve (Peygamberlik Müjdeleri) kitâbı, derin âlim ve büyük velî Mevlânâ Abdürrahmân Câmî hazretlerinin, “ŞEVÂHİD-ÜN NÜBÜVVE Lİ-TAKVİYET-İ EHLİL-FÜTÜVVE” adlı kitâbının tercümesidir. Muhammed aleyhisselamın peygamberliğine delîl olan alâmetler ve mu’cizelerinin beyânı hakkındadır. Kitâbda, bir mukaddime, yedi bölüm, bir hâtime vardır:'**
  String get sevahidInfo;

  /// Page title
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsPageTitle;

  /// Switch title
  ///
  /// In tr, this message translates to:
  /// **'Bildirimleri Etkinleştir'**
  String get enableNotifications;

  /// Switch subtitle
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakti bildirimlerini etkinleştir/devre dışı bırak'**
  String get notificationsSubtitle;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'İmsak Alarmı'**
  String get imsakAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Sabah Alarmı'**
  String get morningAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Güneş Alarmı'**
  String get sunriseAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Öğle Alarmı'**
  String get noonAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'İkindi Alarmı'**
  String get afternoonAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Akşam Alarmı'**
  String get sunsetAlarm;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Yatsı Alarmı'**
  String get nightAlarm;

  /// Minute abbreviation
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get minuteAbbreviation;

  /// Calendar list title
  ///
  /// In tr, this message translates to:
  /// **'Takvimler'**
  String get calendarListTitle;

  /// Battery optimization disable text
  ///
  /// In tr, this message translates to:
  /// **'Pil Optimizasyonunu Devre Dışı Bırak'**
  String get disableBatteryOptimization;

  /// Battery optimization subtitle text
  ///
  /// In tr, this message translates to:
  /// **'Bildirim servislerinin düzgün çalışması için pil optimizasyonunu devre dışı bırakın.'**
  String get batteryOptimizationSubtitle;

  /// Calendar selection dialog title
  ///
  /// In tr, this message translates to:
  /// **'Takvim Seçin'**
  String get selectCalendarTitle;

  /// Calendar permission denied message
  ///
  /// In tr, this message translates to:
  /// **'Takvim izni verilmedi'**
  String get calendarPermissionDenied;

  /// No calendars found message
  ///
  /// In tr, this message translates to:
  /// **'Takvim bulunamadı'**
  String get calendarNotFound;

  /// Calendar add success message
  ///
  /// In tr, this message translates to:
  /// **'{eventName} takvime eklendi'**
  String calendarAddSuccess(String eventName);

  /// Calendar add error message
  ///
  /// In tr, this message translates to:
  /// **'Takvime eklenemedi: {errorMessage}'**
  String calendarAddError(String errorMessage);

  /// General error message
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu: {errorMessage}'**
  String generalError(String errorMessage);

  /// Kilit ekranında vakitlerin gösterilmesi ayarı
  ///
  /// In tr, this message translates to:
  /// **'Kilit Ekranında Vakitler'**
  String get lockScreen;

  /// Kilit ekranında vakitlerin gösterilmesi ayarının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Kilit ekranında namaz vakitlerinin gösterilmesini sağlar'**
  String get lockScreenDesc;

  /// Bildirim sesi ayarlama başlığı
  ///
  /// In tr, this message translates to:
  /// **'Vakit Bildirim Sesi'**
  String get notificationSoundTitle;

  /// Varsayılan bildirim sesi seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan Bildirim Sesi'**
  String get defaultNotificationSound;

  /// Varsayılan alarm sesi seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan Alarm Sesi'**
  String get defaultAlarmSound;

  /// Ezan sesi seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Ezan Sesi'**
  String get ezanSound;

  /// İmsak ve güneş vakitlerinde ezan sesi yerine varsayılan bildirim sesi çalınacağına dair bilgi
  ///
  /// In tr, this message translates to:
  /// **'İmsak ve Güneş vakitlerinde varsayılan bildirim sesi çalınır.'**
  String get imsakSunriseNotificationInfo;

  /// On switch title
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get on;

  /// Alarm switch title
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get off;

  /// Gap slider title
  ///
  /// In tr, this message translates to:
  /// **'Zaman Farkı'**
  String get gapSliderTitle;

  /// Enable all alarms button title
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Aç'**
  String get enableAllAlarms;

  /// Disable all alarms button title
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Kapat'**
  String get disableAllAlarms;

  /// All alarms enabled message
  ///
  /// In tr, this message translates to:
  /// **'Tüm alarmlar açıldı.'**
  String get allAlarmsEnabled;

  /// All alarms disabled message
  ///
  /// In tr, this message translates to:
  /// **'Tüm alarmlar devre dışı bırakıldı.'**
  String get allAlarmsDisabled;

  /// Title for compass optimization dialog
  ///
  /// In tr, this message translates to:
  /// **'Pusula Optimizasyonu'**
  String get compassOptimizationTitle;

  /// Message for compass optimization dialog
  ///
  /// In tr, this message translates to:
  /// **'Daha doğru sonuç almak için pusulanızı kalibre edin.'**
  String get compassOptimizationMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'it', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'ru': return AppLocalizationsRu();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
