/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:namaz_vakti_app/l10n/app_localization.dart';

class Qibla extends StatelessWidget {
  const Qibla({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.qiblaPageTitle,
      actions: [
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.compassOptimizationTitle),
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Icon(Icons.compass_calibration_rounded, size: 50),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(AppLocalizations.of(context)!.compassOptimizationMessage),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.info_outline_rounded),
        ),
        const SizedBox(width: 20),
      ],
      background: false,
      body: const QiblaCard(),
    );
  }
}

class QiblaCard extends StatefulWidget {
  const QiblaCard({super.key});

  @override
  State<QiblaCard> createState() => _QiblaCardState();
}

class _QiblaCardState extends State<QiblaCard> {
  static double? _direction = 0;
  static double? _target = 0;
  static double? _targetDir = 0;

  @override
  void initState() {
    super.initState();
    loadTarget();
    FlutterCompass.events!.listen((event) {
      if (mounted) {
        setState(() {
          _direction = event.heading;
          _targetDir = event.heading! - _target!;
        });
      }
    });
  }

  Future<void> loadTarget() async {
    String url =
        'http://www.namazvakti.com/XML.php?cityID=${Provider.of<ChangeSettings>(context, listen: false).cityID}'; // Çevrimiçi XML dosyasının URL'si

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = response.body;
      final document = xml.XmlDocument.parse(data);

      final cityinfo = document.findAllElements('cityinfo').first;

      _target = double.parse(cityinfo.getAttribute('qiblaangle')!);
      if (_target! > 180) {
        _target = (_target! + 180) * -1;
      }
    }
  }

  Widget _buildCompass() {
    if (_direction == null) {
      return const Text('Yön verisi bekleniyor...');
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.only(
                top: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 0 : 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildDirectionText(),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Center(
                child: Transform.rotate(
                  angle: ((_direction ?? 0) * (3.14159265358979323846 / 180) * -1),
                  child: Image.asset('assets/img/compass.png'),
                ),
              ),
              Center(
                child: Transform.rotate(
                  angle: ((_targetDir ?? 0) * (3.14159265358979323846 / 180) * -1),
                  child: Image.asset('assets/img/target.png'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionText() {
    if (_direction! < _target! + 3 && _direction! > _target! - 3) {
      return SizedBox(
        height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 30 : 100,
        child: Image.asset('assets/img/qibla.png'),
      );
    } else {
      return Container(
        height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 30 : 100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: _buildCompass(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Text(
                                        Provider.of<ChangeSettings>(context).cityName!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Divider(
                                      height: Provider.of<ChangeSettings>(context).currentHeight! <
                                              700.0
                                          ? 5.0
                                          : 15.0,
                                    ),
                                  ),
                                  Text(
                                    Provider.of<ChangeSettings>(context).cityState!,
                                  ),
                                ],
                              )),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              color: Theme.of(context).cardColor,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${AppLocalizations.of(context)!.qiblaTargetText} ${_target! < 0 ? (360 + _target!).toStringAsFixed(2) : _target!.toStringAsFixed(2)}°',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '${_direction! < 0 ? (360 + _direction!).toStringAsFixed(2) : _direction!.toStringAsFixed(2)}°',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
