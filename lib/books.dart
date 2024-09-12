import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Books extends StatelessWidget {
  const Books({super.key});
  static bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    _isDark = Provider.of<ChangeSettings>(context).isDark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Provider.of<ChangeSettings>(context).isDark == false
                ? Provider.of<ChangeSettings>(context).color.shade300
                : Provider.of<ChangeSettings>(context).color.shade900,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.01, 0.4],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kaynak Kitaplar'),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              SizedBox(
                height: 10,
              ),
              BookCard(
                bookName: 'Tam İlmihâl Se`âdet-i Ebediyye',
                col: _isDark == false
                    ? Color.fromARGB(255, 177, 65, 57)
                    : Color.fromARGB(255, 136, 50, 44),
                description: Descriptions.ilmihal,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=001',
              ),
              BookCard(
                bookName: 'Mektûbat Tercemesi',
                col: _isDark == false
                    ? Color.fromARGB(255, 47, 104, 150)
                    : Color.fromARGB(255, 34, 75, 108),
                description: Descriptions.mektubat,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=002',
              ),
              BookCard(
                bookName: 'İslâm Ahlâkı',
                col: _isDark == false
                    ? Color.fromARGB(255, 203, 193, 103)
                    : Color.fromARGB(255, 152, 145, 78),
                description: Descriptions.islam,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=003',
              ),
              BookCard(
                bookName: 'Kıyâmet ve Âhıret',
                col: _isDark == false
                    ? Color.fromARGB(255, 213, 106, 99)
                    : Color.fromARGB(255, 165, 83, 77),
                description: Descriptions.kiyamet,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=004',
              ),
              BookCard(
                bookName: 'Namâz Kitâbı',
                col: _isDark == false
                    ? Color.fromARGB(255, 121, 179, 123)
                    : Color.fromARGB(255, 89, 132, 91),
                description: Descriptions.namaz,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=005',
              ),
              BookCard(
                bookName: 'Cevâb Veremedi',
                col: _isDark == false
                    ? Color.fromARGB(255, 197, 125, 149)
                    : Color.fromARGB(255, 159, 101, 120),
                description: Descriptions.cevab,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=006',
              ),
              BookCard(
                bookName: 'Eshâb-ı Kirâm',
                col: _isDark == false
                    ? Color.fromARGB(255, 31, 147, 189)
                    : Color.fromARGB(255, 23, 109, 140),
                description: Descriptions.eshabikiram,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=007',
              ),
              BookCard(
                bookName: 'Fâideli Bilgiler',
                col: _isDark == false
                    ? Colors.orange[300]!
                    : const Color.fromARGB(255, 209, 151, 64),
                description: Descriptions.faideli,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=008',
              ),
              BookCard(
                bookName: 'Hak Sözün Vesîkaları',
                col: _isDark == false
                    ? const Color.fromARGB(255, 117, 146, 160)
                    : const Color.fromARGB(255, 96, 119, 130),
                description: Descriptions.haksoz,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=009',
              ),
              BookCard(
                bookName: 'Herkese Lâzım Olan Îmân',
                col: _isDark == false
                    ? const Color.fromARGB(255, 180, 133, 189)
                    : const Color.fromARGB(255, 137, 101, 144),
                description: Descriptions.iman,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=010',
              ),
              BookCard(
                bookName: 'İngiliz Câsûsunun İ`tirâfları',
                col: _isDark == false
                    ? const Color.fromARGB(255, 205, 196, 111)
                    : const Color.fromARGB(255, 136, 130, 75),
                description: Descriptions.casus,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=011',
              ),
              BookCard(
                bookName: 'Kıymetsiz Yazılar',
                col: _isDark == false
                    ? const Color.fromARGB(255, 199, 141, 160)
                    : const Color.fromARGB(255, 150, 107, 122),
                description: Descriptions.kiymetsiz,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=012',
              ),
              BookCard(
                bookName: 'Menâkıb-ı Çihâr Yâr-i Güzîn',
                col: _isDark == false
                    ? const Color.fromARGB(255, 195, 168, 128)
                    : const Color.fromARGB(255, 142, 123, 95),
                description: Descriptions.menakib,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=013',
              ),
              BookCard(
                bookName: 'Şevâhid-ün Nübüvve',
                col: _isDark == false
                    ? const Color.fromARGB(255, 187, 137, 63)
                    : const Color.fromARGB(255, 142, 105, 49),
                description: Descriptions.sevahid,
                link: 'https://www.hakikatkitabevi.net/bookread.php?bookCode=014',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(elevation: 10),
                  onPressed: () async {
                    final Uri url = Uri.parse('https://www.hakikatkitabevi.net/');
                    await launchUrl(url);
                  },
                  child: Text(
                    'www.hakikatkitabevi.net',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard(
      {super.key,
      required this.bookName,
      required this.col,
      required this.description,
      required this.link});
  final String bookName;
  final Color col;
  final String description;
  final String link;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Card(
        color: col,
        child: Padding(
          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 3.0 : 8.0),
          child: ListTile(
            leading: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 10, shape: CircleBorder()),
              onPressed: () {
                showModalBottomSheet(
                  enableDrag: true,
                  context: context,
                  showDragHandle: true,
                  backgroundColor: col,
                  elevation: 10,
                  isScrollControlled: MainApp.currentHeight! < 700.0 ? true : false,
                  builder: (BuildContext context) {
                    return Card(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey, // Kenar rengini belirleyin
                          width: 2.0, // Kenar kalınlığını belirleyin
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      color: Theme.of(context).cardColor,
                      child: Scrollbar(
                        child: Padding(
                          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
                          child: ListView(
                            children: [
                              Text(
                                description,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Icon(Icons.info),
            ),
            title: Text(
              bookName,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 10,
              ),
              onPressed: () async {
                final Uri url = Uri.parse(link);
                await launchUrl(url);
              },
              child: Icon(Icons.book_rounded),
            ),
          ),
        ),
      ),
    );
  }
}

class Descriptions {
  static final String ilmihal = '''
(Tam İlmihâl-Se’âdet-i Ebediyye) kitâbı, üç kısımdan meydâna gelmişdir:

I. kısımda; İslâm dînine nasıl inanılacağı, ehl-i sünnet i’tikâdı, İslâm dinine iftirâ edenlere cevâblar, Kur'ân-ı kerîm ve tefsîrler, kur'ân-ı kerîmdeki ilmlerin sınıflandırılması, Nemâzın ehemmiyyeti, farzları, abdest, gusl, nemâz ile ilgili bütün husûslar, kaza nemâzları, Cum’a ve bayram nemâzları, Zekât, Ramezân Orucu, Sadaka-i Fıtr, Yemîn ve Yemîn Keffâreti, Adak, Kurban Kesmek, Hac, Mübârek Geceler, Hicrî ve Mîlâdî Senelerin birbirine çevrilmeleri, Selâmlaşmak, Muhammed aleyhisselâmın hayâtı, Mübârek ahlâkı, anne, baba ve dedelerinin mü’min oluşu, Sübhâne Rabbîke âyeti hakkında bilgiler... yer almakdadır.

II. kısımda; Îmân, Akl, Kaza-Kader, Tefsîr ve Hadîs kitâbları, Hadîs âlimleri, Allahü teâlânın ismleri, Mezheb, Fıkh, İmâm-ı A’zam hazretleri, Vehhâbîlere Ehl-i Sünnetin cevâbı, Evliyâ rûhlarından faydalanma, Bozuk dinler, hurûfîlik, Sosyalizm ve Sosyâl adâlet, İslâmiyyetde nikâh, Talâk, Süt kardeşlik, Nafaka, Komşu hakkı, Halâl ve Harâmlar, İsrâf ve Fâiz, Fen Bilgileri, Tevekkül, Müzik ve Tegannî, Cin hakkında bilgi, Bir Müslimân babanın kızına nasîhatları, Mu’cîze, kerâmet, firâset, istidrâc ... gibi konular yer almakdadır.

III. kısımda, İslâmiyyetde kesb ve ticâret, Bey’ ve Şirâ’, Alış-verişde muhayyerlik, Bâtıl, Fâsid ve Mekrûh Satışlar, Ticârette adâlet ve ihtikâr, dinini kayırmak, ihsân, Banka ve Fâiz, Şirketler, Cezâlar, Ölüm ve Ölüme Hâzırlık, Meyyite Hizmetler, Ferâiz, Meyyit için İskât ... gibi konular yer almakdadır.

Ayrıca konular arasında, İmâm-ı Rabbânî hazretlerinin ve oğlu Muhammed Ma’sûm hazretlerinin (MEKTÛBÂT) kitâblarından çeşitli mektûblar vardır.

Son bölümde (1020) zâtın hâl tercemesi yer almakdadır. Fihrist bölümünde zâtlar, kitâblar, mevzû'lar fihristleri vardır.

Bine yakın eserden uzun bir zemânda hâzırlanan bu nâdîde eserde; insanı se’âdete kavuşduracak bütün husûslar yer almakdadır.
''';

  static final String mektubat = '''
971 [m.1563] de doğan ve 1034 [m.1624] de vefât eden, ikinci bin yılın müceddîdi, İmâm-ı Rabbânî Ahmed Fârûkî Serhendi hazretleri, Kur’ân-ı kerîm ve Hadîs-i Şerîflerden sonra, en kıymetli üçüncü kitâb olan (MEKTÛBÂT) kitâbını yazmışdır. İnsanoğlunun rûhî hastalıklarının tedâvî yollarını göstermiş, islâm dînine nasıl inanılacağı, ibâdetlerin ehemmiyyeti, Evliyâlık, Resûlullahın güzel ahlâkı, islâmiyyet, tarîkat ve hakîkatin ayrı ayrı şeyler olmadıklarını îzâh etmişdir. Üç cild ve aslı fârisî olan mektûbât kitâbında (536) mektûb vardır.
''';

  static final String faideli = '''
İslâm dîni ve Ehl-i Sünnet i’tikâdı hakkında öz bilgiler verilen kitâbda, islâmî ilimlerin ve fıkh âlimlerinin sınıflandırılması, İmâm-ı A’zam Ebû Hanîfe hazretlerinin hayâtı anlatılmaktadır. Üç kısımdan meydâna gelen Fâideli Bilgiler kitâbında dinde reform yapmak isteyenlere, İslâm dinini bozan zararlı cereyân ve fikirlere ve cebriyye, mu’tezîle, vehhâbîlik gibi sapık fırkalara cevâb verilmektedir. 
''';

  static final String haksoz = '''
Hak sözün vesîkaları kitabı Şî’îlik, Ehl-i Beyt, Eshâb-ı kirâm ve Ehl-i Sünnet hakkında bilgiler vermekde, Ehl-i beyt ile Eshâb-ı kirâmın birbirlerini çok sevdiklerini açıklamakda ve şî’îlerin kitablarını ve iftirâlarını gâyet ilmî olarak cevâblamakdadır. Komünistlik ve din düşmanlığı hakkında bilgiler de veren kitâbda İmâm-ı Gazâlî hazretlerinin (Eyyühel-Veled) tercemesi ve İmâm-ı Rabbânî hazretlerinin hâl tercemesi de bulunmaktadır. ''';

  static final String iman = '''
İslâm dîninin bilinmesi gereken îmân esaslarını ve îmânın altı şartını kaynak kitaplardan aktararak detaylı bir şekilde açıklayan bu kitâb, aynı zamanda diğer dînler hakkında bilgiler de verip İslâmiyyet ile karşılaşdırmakdadır.''';

  static final String islam = '''
İslâm dîninin güzel ahlâkına ulaşmak için kurtulmak gereken 40 kötü ahlak ve bunlardan kurtulma çarelerinin anlatıldığı bu kitâbda aynı zamanda (Mızraklı İlmihâl) diye bilinen Muhammed bin Kutbüddîn İznîki hazretlerinin kitâbı esas alınarak yazılan Îmân ve ibâdet bilgilerini içeren Cennet Yolu İlmihâli bulunmaktadır. ''';

  static final String eshabikiram = '''
Eshâb-ı Kirâm kitâbının başında, Peygamberimiz Muhammed aleyhisselâmın Eshâbının üstünlüğünü, Eshâb-ı kirâm arasındaki hâdiseler, Eshâb-ı kirâma dil uzatanların haksız ve câhil oldukları anlatılmakda, ayrıca; (İctihâd) ın ne olduğu açıklanmakdadır.''';

  static final String kiyamet = '''
Kıyâmet ve Âhıret kitâbında insanın ölümü, rûhun bedenden ayrılması, kabr hayâtı, kabr süâlleri, kıyâmet günü insanların hesâba çekilmesi, Cennet ve Cehenneme nasıl gidileceği büyük islâm âlimi, İmâm-ı Gazâlî hazretlerinin kitâblarından terceme edilerek geniş olarak açıklanmakda ve vehhâbîliğe cevap vererek evliyâlığın ne olduğu, kıyâmet günü herkesin sevdiğinin yanında olacağı konuları açıklanmakdadır. ''';

  static final String cevab = '''
Îsâ aleyhisselâma gönderilen ve hak kitâb olan İncîlin tahrîf edilmesi ile ortaya çıkan dört kitâb [Matta İncîli, Markos İncîli, Luka İncîli, Yuhannâ İncîli] hakkında bilgi vermekde, aralarındaki ihtilâfları açıklamakdadır. Kur’ân-ı kerîm ile İncîl karşılaştırılmakda, İncîlin tahrîf edildiği, hükümlerinin yürürlükden kalkdığı, Kur’ân-ı kerîmin bütün semâvî kitâbların hükümlerini yürürlükden kaldırdığı îzâh edilmekdedir. Îsevîlikdeki teslîs (üç tanrı) inancının yanlış olduğu, Allahü teâlânın bir olduğu, ilim ve kudret sıfâtları ilmî olarak açıklanmakdadır. Îsâ aleyhisselâmın insan ve Peygamber olduğu, ona tapılmıyacağı îzâh edilmekdedir. Yehûdîlik, Tevrât ve Talmud hakkında da bilgi verilmekdedir.''';

  static final String casus = '''
1700’lü yıllarda İstanbul’a gelen ve orada çeşidli islâmi ilimleri ve lîsanları öğrenen İngiliz casusu Hempher’in, İslâm dünyâsını ve müslimânları parçalamak için yaptığı casusluk faaliyetlerini ve vehhâbîliği nasıl kurduğunu anlattığı hatıratının tercümesini içeren bu kitâb 3 bölümden oluşmaktadır.''';

  static final String kiymetsiz = '''
İmâm-ı Rabbânî Müceddîd-i Elf-i sânî Ahmed Fârûkî Serhendi hazretlerinin üç cild (MEKTÛBÂT) kitâbından ve oğulları Muhammed Ma’sûm-i Fârûkî hazretlerinin de üç cild (MEKTÛBÂT) kitâbından, çıkarılan kıymetli cümleler, Elif-ba sırasına göre tanzîm edilmiş, Seyyid Abdülhakîm Arvâsî hazretlerine okunmuşdur. Dikkat ile dinledikden sonra, bunun adı (Kıymetsiz Yazılar) olsun demişdir. Okuyanın hayreti üzere, anlamadın mı, (Bunun kıymetine karşılık olabilecek birşey bulunabilir mi?) buyurmuşdur. Son sayfasında şu cümleler yer almakdadır:

(Fırsat ganîmetdir. Ömrün temâmını fâidesiz işlerle telef ve sarf etmemek lâzımdır. Belki temâm ömrü, Hak celle ve a’lânın rızâsına muvâfık ve mutâbık şeylere sarf etmek lâzımdır....)''';

  static final String namaz = '''
Küçük bir ilmihal niteliğinde olan bu kitâbda her müslümanın bilmesi zaruri olan Ehl-i sünnet i'tikâdı, namaz, abdest, gusl, teyemmüm, oruç, hac ve zekât bilgileri anlatılmaktadır. Namâz kitâbının sonunda, namâzın içinde ve dışında okunacak duâlar arabî olarak yer almaktadır. Namâz ve Namâzla ilgili bilgileri detaylıca içeren dokuz kısımdan oluşmaktadır.''';

  static final String sevahid = '''
Şevâhid-ün Nübüvve (Peygamberlik Müjdeleri) kitâbı, derin âlim ve büyük velî Mevlânâ Abdürrahmân Câmî hazretlerinin, “ŞEVÂHİD-ÜN NÜBÜVVE Lİ-TAKVİYET-İ EHLİL-FÜTÜVVE” adlı kitâbının tercümesidir. Muhammed aleyhisselamın peygamberliğine delîl olan alâmetler ve mu’cizelerinin beyânı hakkındadır. Kitâbda, bir mukaddime, yedi bölüm, bir hâtime vardır: ''';

  static final String menakib = '''
Dört halîfenin ve Eshâb-ı Kirâmın bütününün büyüklüklerini, kıymetlerini menkıbeler ile çok uzun ve çok güzel anlatan bu kitâb, türkçe olup, ilk defa 1325 senesinde basılmıştır. Kitabevimiz yeniden 1998'de basdırmıştır. Bu kitâbı Seyyid Eyyûb hazretleri yazmıştır. On iki bâb dan oluşmakdadır. ''';
}
