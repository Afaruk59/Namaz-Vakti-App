import 'package:gsheets/gsheets.dart';

class CitiesSheetsApi {
  static const _credentials = r'''
{
  "type": "service_account",
  "project_id": "citiesproject-432818",
  "private_key_id": "ec2b0faac2a4af2341e0740dca1f5ec1aedb72e2",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDFTKDqBHgNKGMr\nR2A2aO3VD+4N/TC5/ApFK6aUfe5rePpr2EIsdl4w/v9b0EnKl6DBGYOSZ7y5UkKU\ngfHd1qS0wxNiXHmEEfb8pRE1J2cbu3r9bTSOzx0QkM79OWDci5gIsG4xiMSmg3kX\n9p7UwiEnG6P5I+zeW/2BYDqmmsPSfa3TQSqfxZ5QPbDq8+qQIGoMhWY0BnYsvQ3V\n8vpZJsvOe58Ngqm9CUcrQz2PxvzJoQPCYxhOFhP7znvtW+fKDYo9ZhmOJ32Y6Y6G\nSCGy7K/FrAA/K21ick67PI0GP+jWSZGKPQ/cTjOUGf0Z6qsBQ1A4jngEe7LK4eyQ\n1DkCEJnlAgMBAAECggEATFqX6Yi6Nwlau4x/UP8xj2N/Up2aBlfiV5uJd2z24FOs\nwiCql09lq1t70nncnNEqTqCDmRyZXjTV/Gf/hMUE78mQzl+QTUqwhVySOLpbflGD\nSuFA1kWT723DFR9n+2Hwf+hbdMMDq5c0vU/dbuQD9YEOZ6P+Dp2WEUP+3qwFPYdk\nnU4piPhd0MP/QesS74RbHDNVm2SfOusmcRDLEX/t4fJl3a0g3DIhwxPl6h9TH9B5\n29+4rKcBoSSiEx//7Brcaiqu0TOQ2irirs2mR2jjzfokVt2wtO1LYDfvKN9tR4+N\ncJ6L1dz/18gFx7lbfO9ryJd8Ve8zrSP7xScEpq2T3wKBgQDsEIMQwGQbgHIrNQgR\nBVuSTGbiBuSuuG1MoJWPv1CF0khqEQiDuaByhknOS4H+wiDGC4O/sn5uU3ovP+7f\nEQUbSF0g3ta7DHegEwWV8ppTRoSdbDKTZXwBsjHsHQwrP50uQJejRFDnTkxDJrLg\nObK7DmmKIJkHNOPERLyad+zQCwKBgQDV9g0CfURDA3TG/ftDpUBu3zVLaEiOwgim\nxqz31VBWRHe5eYHUUnuw5+DhxhdtVzBxrEIXfCDwHzMQYrEcM9RPRd/BEzft1n/s\nOQGVF6KUEEQA3DUcHY3x2rGEoB5DyzPQcZJc4Ppt5EpRDfCA7Syy5n5zVDUEo38Z\ne8L52tTDzwKBgAYHnfFtmKEDNOdZoW0d3+rqvK4FUw4Lc+9DIs7bKilg56yd5sPG\nmAyU1YnJb/ab6s5kOOdKneQfib1vOqDEBIdf39EZIA8DEIMsOTZNThfWc0i6HMib\nDQHWFWRckZUBOPiXecgX1KEz5MrKUENd9ezFP3jhwEbo2PCIePDRI2FlAoGAM6bD\nez9cVEUoUsWLe8gP5vQRfJO/OF9VEVXS+b1QOJMsx+SyV9xVqd5AZqCYlTfAJSDt\nj5fSp8UQYbtBgEpuzXhTzNtj3BG1LgSRAjoDcHUAxahjVdc4phMiWZ8Bz2Hlr0NL\njwpsykybODgCQE2BReroydShO+5wR2meJw0R4fcCgYAw/zbvIliX/O1JHuz+3pha\nqBdhxvUNe3u+wHPuiCb4s7qEsDVHfIAy3l/x0rHvorEH+/b1WiQ8YClPmJ7PQJei\nKBI0dVcuLC2BfM0MAiAAF0VotQ3hPxyFazBOtSD/rD7CDfw8Tw6gLewJPxMGqEJs\nrXiKYWop9gBYptI+lJnwNA==\n-----END PRIVATE KEY-----\n",
  "client_email": "sheetsservice@citiesproject-432818.iam.gserviceaccount.com",
  "client_id": "106907399362345392091",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sheetsservice%40citiesproject-432818.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';
  static final _sheetId = '1i9uEI5F8CDpvBcLkm7mM43tWSiRWWRbKUcFB2H1A6Oo';
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _userSheet;

  static Future init() async {
    final spreadsheet = await _gsheets.spreadsheet(_sheetId);
    _userSheet = await _getWorkSheet(spreadsheet, title: 'cities');
  }

  static Future<Worksheet> _getWorkSheet(Spreadsheet spreadsheet, {required title}) async {
    try {
      return await spreadsheet.worksheetByTitle(title)!;
    } on Exception {
      return spreadsheet.worksheetByTitle(title)!;
    }
  }

  static Future<void> searchLat(double lat) async {
    // Belirli bir sütundaki verileri alın
    final columnValues = await _userSheet!.values.column(5); // 1. sütun

    // Hedef değeri belirleyin
    double targetValue = lat;

    // En yakın değeri bulmak için değişkenler
    double closestValue = double.infinity;
    double smallestDifference = double.infinity;

    for (String value in columnValues) {
      double? numValue = double.tryParse(value);
      if (numValue != null) {
        double difference = (numValue - targetValue).abs();
        if (difference < smallestDifference) {
          smallestDifference = difference;
          closestValue = numValue;
        }
      }
    }

    int index = columnValues.indexOf(closestValue.toString());

    // Sonuç
    print('En yakın değer: $closestValue , index: ${index + 1}');
  }

  static Future<void> searchLong(double long) async {
    // Belirli bir sütundaki verileri alın
    final columnValues = await _userSheet!.values.column(6); // 1. sütun

    // Hedef değeri belirleyin
    double targetValue = long;

    // En yakın değeri bulmak için değişkenler
    double closestValue = double.infinity;
    double smallestDifference = double.infinity;

    for (String value in columnValues) {
      double? numValue = double.tryParse(value);
      if (numValue != null) {
        double difference = (numValue - targetValue).abs();
        if (difference < smallestDifference) {
          smallestDifference = difference;
          closestValue = numValue;
        }
      }
    }

    int index = columnValues.indexOf(closestValue.toString());

    // Sonuç
    print('En yakın değer: $closestValue , index: ${index + 1}');
  }
}
