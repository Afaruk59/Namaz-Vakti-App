/// Kuran ses dosyalarına erişim sağlayan sınıf
class QuranAudioRepository {
  /// Ayet ses dosyası URL'sini döndürür
  String getAyahAudioUrl(int surahNo, int ayahNo) {
    return 'https://webdosya.diyanet.gov.tr/kuran/kuranikerim/Sound/ar_osmanSahin/${surahNo}_${ayahNo}.mp3';
  }

  /// Ses dosyası URL'sini döndürür (getAyahAudioUrl ile aynı, uyumluluk için)
  String getAudioUrl(int surahNo, int ayahNo) {
    return getAyahAudioUrl(surahNo, ayahNo);
  }

  /// XML dosyası URL'sini döndürür
  String getXmlUrl(int surahNo, int ayahNo) {
    return 'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/s$surahNo/a$ayahNo.xml';
  }

  /// Besmele ses dosyası URL'sini döndürür
  String getBismillahAudioUrl(int surahNo) {
    return 'https://webdosya.diyanet.gov.tr/kuran/kuranikerim/Sound/ar_osmanSahin/${surahNo}_0.mp3';
  }

  /// Kelime takip XML dosyası URL'sini döndürür
  String getWordTrackXmlUrl(int pageNo) {
    return 'https://kuran.diyanet.gov.tr/mushaf/data/xml/wordTrack/ar_osmanSahin/sc/$pageNo.xml';
  }

  /// Sure ismini döndürür
  String getSurahName(int surahNo) {
    final surahNames = [
      "Fatiha",
      "Bakara",
      "Âl-i İmrân",
      "Nisâ",
      "Mâide",
      "En'âm",
      "A'râf",
      "Enfâl",
      "Tevbe",
      "Yûnus",
      "Hûd",
      "Yûsuf",
      "Ra'd",
      "İbrâhîm",
      "Hicr",
      "Nahl",
      "İsrâ",
      "Kehf",
      "Meryem",
      "Tâhâ",
      "Enbiyâ",
      "Hac",
      "Mü'minûn",
      "Nûr",
      "Furkân",
      "Şuarâ",
      "Neml",
      "Kasas",
      "Ankebût",
      "Rûm",
      "Lokmân",
      "Secde",
      "Ahzâb",
      "Sebe'",
      "Fâtır",
      "Yâsîn",
      "Sâffât",
      "Sâd",
      "Zümer",
      "Mü'min",
      "Fussilet",
      "Şûrâ",
      "Zuhruf",
      "Duhân",
      "Câsiye",
      "Ahkâf",
      "Muhammed",
      "Fetih",
      "Hucurât",
      "Kâf",
      "Zâriyât",
      "Tûr",
      "Necm",
      "Kamer",
      "Rahmân",
      "Vâkıa",
      "Hadîd",
      "Mücâdele",
      "Haşr",
      "Mümtehine",
      "Saff",
      "Cum'a",
      "Münâfikûn",
      "Teğâbün",
      "Talâk",
      "Tahrîm",
      "Mülk",
      "Kalem",
      "Hâkka",
      "Meâric",
      "Nûh",
      "Cin",
      "Müzzemmil",
      "Müddessir",
      "Kıyâmet",
      "İnsân",
      "Mürselât",
      "Nebe'",
      "Nâziât",
      "Abese",
      "Tekvîr",
      "İnfitâr",
      "Mutaffifîn",
      "İnşikâk",
      "Bürûc",
      "Târık",
      "A'lâ",
      "Gâşiye",
      "Fecr",
      "Beled",
      "Şems",
      "Leyl",
      "Duhâ",
      "İnşirâh",
      "Tîn",
      "Alak",
      "Kadir",
      "Beyyine",
      "Zilzâl",
      "Âdiyât",
      "Kâria",
      "Tekâsür",
      "Asr",
      "Hümeze",
      "Fîl",
      "Kureyş",
      "Mâûn",
      "Kevser",
      "Kâfirûn",
      "Nasr",
      "Tebbet",
      "İhlâs",
      "Felak",
      "Nâs"
    ];

    if (surahNo < 1 || surahNo > surahNames.length) {
      return "Bilinmeyen Sure";
    }

    return surahNames[surahNo - 1];
  }

  /// Surelerin ayet sayılarını döndürür
  int getMaxAyahCount(int surahNo) {
    final surahAyahCounts = [
      7, // 1. Fatiha
      286, // 2. Bakara
      200, // 3. Ali İmran
      176, // 4. Nisa
      120, // 5. Maide
      165, // 6. Enam
      206, // 7. Araf
      75, // 8. Enfal
      129, // 9. Tevbe
      109, // 10. Yunus
      123, // 11. Hud
      111, // 12. Yusuf
      43, // 13. Rad
      52, // 14. İbrahim
      99, // 15. Hicr
      128, // 16. Nahl
      111, // 17. İsra
      110, // 18. Kehf
      98, // 19. Meryem
      135, // 20. Taha
      112, // 21. Enbiya
      78, // 22. Hac
      118, // 23. Müminun
      64, // 24. Nur
      77, // 25. Furkan
      227, // 26. Şuara
      93, // 27. Neml
      88, // 28. Kasas
      69, // 29. Ankebut
      60, // 30. Rum
      34, // 31. Lokman
      30, // 32. Secde
      73, // 33. Ahzab
      54, // 34. Sebe
      45, // 35. Fatır
      83, // 36. Yasin
      182, // 37. Saffat
      88, // 38. Sad
      75, // 39. Zümer
      85, // 40. Mümin
      54, // 41. Fussilet
      53, // 42. Şura
      89, // 43. Zuhruf
      59, // 44. Duhan
      37, // 45. Casiye
      35, // 46. Ahkaf
      38, // 47. Muhammed
      29, // 48. Fetih
      18, // 49. Hucurat
      45, // 50. Kaf
      60, // 51. Zariyat
      49, // 52. Tur
      62, // 53. Necm
      55, // 54. Kamer
      78, // 55. Rahman
      96, // 56. Vakıa
      29, // 57. Hadid
      22, // 58. Mücadele
      24, // 59. Haşr
      13, // 60. Mümtehine
      14, // 61. Saf
      11, // 62. Cuma
      11, // 63. Münafikun
      18, // 64. Tegabün
      12, // 65. Talak
      12, // 66. Tahrim
      30, // 67. Mülk
      52, // 68. Kalem
      52, // 69. Hakka
      44, // 70. Mearic
      28, // 71. Nuh
      28, // 72. Cin
      20, // 73. Müzzemmil
      56, // 74. Müddessir
      40, // 75. Kıyame
      31, // 76. İnsan
      50, // 77. Mürselat
      40, // 78. Nebe
      46, // 79. Naziat
      42, // 80. Abese
      29, // 81. Tekvir
      19, // 82. İnfitar
      36, // 83. Mutaffifin
      25, // 84. İnşikak
      22, // 85. Büruc
      17, // 86. Tarık
      19, // 87. Ala
      26, // 88. Gaşiye
      30, // 89. Fecr
      20, // 90. Beled
      15, // 91. Şems
      21, // 92. Leyl
      11, // 93. Duha
      8, // 94. İnşirah
      8, // 95. Tin
      19, // 96. Alak
      5, // 97. Kadir
      8, // 98. Beyyine
      8, // 99. Zilzal
      11, // 100. Adiyat
      11, // 101. Karia
      8, // 102. Tekasür
      3, // 103. Asr
      9, // 104. Hümeze
      5, // 105. Fil
      4, // 106. Kureyş
      7, // 107. Maun
      3, // 108. Kevser
      6, // 109. Kafirun
      3, // 110. Nasr
      5, // 111. Tebbet
      4, // 112. İhlas
      5, // 113. Felak
      6 // 114. Nas
    ];

    if (surahNo < 1 || surahNo > surahAyahCounts.length) {
      print('Geçersiz sure numarası: $surahNo');
      return 0;
    }

    return surahAyahCounts[surahNo - 1];
  }

  /// Kuran cüz indeksini döndürür
  List<Map<String, dynamic>> getQuranJuzIndex() {
    return [
      {"juz": "1. Cüz", "page": 0},
      {"juz": "2. Cüz", "page": 21},
      {"juz": "3. Cüz", "page": 41},
      {"juz": "4. Cüz", "page": 61},
      {"juz": "5. Cüz", "page": 81},
      {"juz": "6. Cüz", "page": 101},
      {"juz": "7. Cüz", "page": 121},
      {"juz": "8. Cüz", "page": 141},
      {"juz": "9. Cüz", "page": 161},
      {"juz": "10. Cüz", "page": 181},
      {"juz": "11. Cüz", "page": 201},
      {"juz": "12. Cüz", "page": 221},
      {"juz": "13. Cüz", "page": 241},
      {"juz": "14. Cüz", "page": 261},
      {"juz": "15. Cüz", "page": 281},
      {"juz": "16. Cüz", "page": 301},
      {"juz": "17. Cüz", "page": 321},
      {"juz": "18. Cüz", "page": 341},
      {"juz": "19. Cüz", "page": 361},
      {"juz": "20. Cüz", "page": 381},
      {"juz": "21. Cüz", "page": 401},
      {"juz": "22. Cüz", "page": 421},
      {"juz": "23. Cüz", "page": 441},
      {"juz": "24. Cüz", "page": 461},
      {"juz": "25. Cüz", "page": 481},
      {"juz": "26. Cüz", "page": 501},
      {"juz": "27. Cüz", "page": 521},
      {"juz": "28. Cüz", "page": 541},
      {"juz": "29. Cüz", "page": 561},
      {"juz": "30. Cüz", "page": 581}
    ];
  }
}
