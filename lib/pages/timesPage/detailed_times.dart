import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/time_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class DetailedTimesBtn extends StatelessWidget {
  const DetailedTimesBtn({super.key});
  static TextStyle style = TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 17.0 : 18.0);

  static DateTime? _imsak;
  static DateTime? _sabah;
  static DateTime? _gunes;
  static DateTime? _ogle;
  static DateTime? _ikindi;
  static DateTime? _aksam;
  static DateTime? _yatsi;
  static DateTime? _israk;
  static DateTime? _kerahat;
  static DateTime? _asrisani;
  static DateTime? _isfirar;
  static DateTime? _istibak;
  static DateTime? _isaisani;
  static DateTime? _kible;
  static String? _time;

  @override
  Widget build(BuildContext context) {
    _imsak = Provider.of<TimeData>(context).imsak;
    _sabah = Provider.of<TimeData>(context).sabah;
    _gunes = Provider.of<TimeData>(context).gunes;
    _ogle = Provider.of<TimeData>(context).ogle;
    _ikindi = Provider.of<TimeData>(context).ikindi;
    _aksam = Provider.of<TimeData>(context).aksam;
    _yatsi = Provider.of<TimeData>(context).yatsi;
    _israk = Provider.of<TimeData>(context).israk;
    _kerahat = Provider.of<TimeData>(context).kerahat;
    _asrisani = Provider.of<TimeData>(context).asrisani;
    _isfirar = Provider.of<TimeData>(context).isfirar;
    _istibak = Provider.of<TimeData>(context).istibak;
    _isaisani = Provider.of<TimeData>(context).isaisani;
    _kible = Provider.of<TimeData>(context).kible;
    _time = Provider.of<TimeData>(context).miladi;
    return Positioned(
      bottom: 20,
      left: 13,
      child: IconButton(
        iconSize: 25,
        icon: const Icon(Icons.menu),
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: Theme.of(context).cardTheme.color,
            context: context,
            showDragHandle: true,
            scrollControlDisabledMaxHeightRatio: 0.8,
            elevation: 10,
            isScrollControlled: MainApp.currentHeight! < 700.0 ? true : false,
            builder: (BuildContext context) {
              return Card(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      _time!,
                      textAlign: TextAlign.center,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: Colors.grey, // Kenar rengini belirleyin
                                    width: 1.0, // Kenar kalınlığını belirleyin
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Kenarların yuvarlaklığını belirleyin
                                ),
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.imsak,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.sabah,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.gunes,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.israk,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.kerahat,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.ogle,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.ikindi,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.asrisani,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.isfirar,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.aksam,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.istibak,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.yatsi,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.isaisani,
                                      style: style,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.kible,
                                      style: style,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: Colors.grey, // Kenar rengini belirleyin
                                    width: 1.0, // Kenar kalınlığını belirleyin
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Kenarların yuvarlaklığını belirleyin
                                ),
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(_imsak!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_sabah!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_gunes!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_israk!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_kerahat!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_ogle!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_ikindi!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_asrisani!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_isfirar!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_aksam!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_istibak!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_yatsi!),
                                      style: style,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(_isaisani!),
                                      style: style,
                                    ),
                                    Text(
                                      _kible != null ? DateFormat('HH:mm').format(_kible!) : '-',
                                      style: style,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}