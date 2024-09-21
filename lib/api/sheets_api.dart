import 'dart:math';

import 'package:gsheets/gsheets.dart';
import 'package:namaz_vakti_app/settings.dart';

class SheetsApi {
  static const _credentials = r'''
{
  "type": "service_account",
  "project_id": "citiesproject-432818",
  "private_key_id": "8e376aa5ebc02b4343e65143b0f4afa655fd5a18",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCUbjCs58E6fgTP\nKAfNS5qO/hRXh9Ijfy+oRNsu9SD3jl2d+Bd+KT16nugj/itX13Dl/+iPzbwdXpRd\nwVj4zjXifDCzfSrLiNvvK3bOxNxM6R6NdJALONP5kSY2kMJ2JUkP/PghOO3sXIGQ\nq0lRREAsdDQI4NaFRrYUbo2327O3YqWpckEht2snFfgQe+L+DOYEeV7GusOaeu3E\nt0xuxxNx+c7SmHnv7boBXiZqfU+1Kalxbv4+jfXYlGiX65hTVk21inFNxtAZUiIq\nuGU2gx9qfak9yfsMJ09e4B2JgjTxGM9HuMusFw4CmvOQ0hAXKKTR4IAen0H6TAW4\nWiUdeHkVAgMBAAECggEAAXBe0PZNOonyoKKDwx9rB+vyeoSZQnHqS4ccTSKo7u61\nZt3LXqC/d6UZVtprYz94pDOV55QWLsm56TdIDq1GChXd/mlYiI81XQ7J5mmYLWx2\n+ietGhZvaNKL7hDOCxD+yFd0r4gKWsDi8lsLm3QrUFAwWweZpFQVwuuD4mD5u4vN\nNpB/3glKXs/5my416Y8CP1u1rZJzq2P7p1i4zdMWfHFnPzMmLAj7+XFPCoCeib7H\nn/S3ydJO30JM2IcZx1njIl0c3VhK+W62wdef8mDCNg+puS56W+JRRs6gVSbgHVMA\nZLrkMG+XAStN4wXgVlX6qfIm/oJhhI6IHrMI9FVJiwKBgQDFAGw0osTaYNYlShny\nC2FLCtVTp1ZzEbN2T8A3dHdkVVKJusG4QqAMeDpqnP+odDMvcvXGNBw2JBhG4uIy\nVcxBuacBRSjxO8wQlbWir3Kk48ZddFJQcd6iphImgfiz3wgj6pyhkVOzELDWznmN\nZWp7XLyZT4S0lnY67lcUQ5mNcwKBgQDA4fHl6iGGYxdzzVN1Hp8nMZgvkLaoBKmn\n0XDVRqzFOqo/OpOO3m8Gy3lEtrI2M/fzdUR4gHz7BwlIER/OuIIAgYPPrxAWcj+L\n3HHGCc7cD5oBHx61dVs8Vi5AuJbY/8aaqs/80hNVZKQ2dFfwUiLjGuT1L6wKDy4C\nrAObttc9VwKBgAdgaqzV43Uh5yLiUXJkxrHep/pH687HPOcTOWlaLRZOs5aArbxO\nklulLNrNIi2WnEwMi/NuBBhq5ZXR7RJhcBKN9xjvFAdka9G7KV/8HdjaxpS9RE/K\n08FXYpqah0uE8HMX1+Gc5XtxBo4kkRygTYptAIrlFV0FvUubnRsfJOLNAoGBAJSB\nonjN8rAAvX7YuQg04n8PzUfaGPh2VpWySTi8qKtWRtxV4mSe2EcYBK+mJsJa8u6M\n/IH3E8NHIJtPK/lC0D1Jes490JonrsulmCfNR2rhzEZOypsV14A2LniAZwx+qlBN\nccQLjv0xdsnCfC65XskS3PP2l3RLSbae8ExE06YTAoGAHmGwS5Cjdm2M/wLDG8wb\nj37JCrsTVVWEpZTQEikO20BRT5UctnrWV6RGtcdkWz3vNXzxI/Jo1t3JlxihkLX5\nEnZiO72xHrzUVpjk/6bPAF4+o+SanMgkdc0L2o4VWmRYCAYGOzwjmuFrkUXB2NSL\nRFk6q267eIHXXSxgM64FiDQ=\n-----END PRIVATE KEY-----\n",
  "client_email": "sheetsservice@citiesproject-432818.iam.gserviceaccount.com",
  "client_id": "106907399362345392091",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sheetsservice%40citiesproject-432818.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}

''';
  static const _spreadsheetId = '1uEEtkBzjCAqjD9NdaWPBnue5fQzvmzumbrH3oQpRfmA';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _sheet;

  static Future init() async {
    final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
    _sheet = await _getWorkSheet(spreadsheet, title: 'cities');
  }

  static Future<Worksheet> _getWorkSheet(Spreadsheet spreadsheet, {required String title}) async {
    return spreadsheet.worksheetByTitle(title)!;
  }

  Future<void> searchLoc(double lat, double long) async {
    print('lat: $lat');
    print('long: $long');

    final latValues = await _sheet!.values.column(5);
    final longValues = await _sheet!.values.column(6);

    int index = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < latValues.length; i++) {
      double distance =
          calculateDistance(lat, long, double.parse(latValues[i]), double.parse(longValues[i]));
      if (distance < minDistance) {
        minDistance = distance;
        index = i;
      }
    }

    final cityIds = await _sheet!.values.column(1);
    String cityId = cityIds[index];

    final cityNames = await _sheet!.values.column(2);
    String cityName = cityNames[index];

    final stateNames = await _sheet!.values.column(3);
    String stateName = stateNames[index];

    ChangeSettings().saveLocaltoSharedPref(cityId, cityName, stateName);
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Dünya'nın yarıçapı (kilometre)

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

// Dereceyi radyana çeviren yardımcı fonksiyon
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
