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
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum MapLayerType {
  street,
  satellite,
}

extension MapLayerTypeExtension on MapLayerType {
  String get displayName {
    switch (this) {
      case MapLayerType.street:
        return 'Sokak';
      case MapLayerType.satellite:
        return 'Uydu';
    }
  }

  IconData get icon {
    switch (this) {
      case MapLayerType.street:
        return Icons.map;
      case MapLayerType.satellite:
        return Icons.satellite_alt;
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapLayerType.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }
}

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

  // Harita görünümü için yeni değişkenler
  LatLng? _currentLocation;
  final LatLng _kaabaLocation = const LatLng(21.4225, 39.8262);
  String? _locationError;
  late PageController _pageController;
  late MapController _mapController;
  int _currentPage = 0;
  bool _isLoadingLocation = false;
  bool _isMapLocked = true; // Harita varsayılan olarak kilitli
  MapLayerType _currentMapLayer = MapLayerType.street; // Varsayılan harita katmanı
  bool _isCompassMode = false; // Pusula modu aktif mi

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mapController = MapController();
    loadTarget();
    FlutterCompass.events!.listen((event) {
      if (mounted) {
        setState(() {
          _direction = event.heading;
          _targetDir = event.heading! - _target!;
        });

        // Pusula modu aktifse haritayı döndür
        if (_isCompassMode && _direction != null) {
          _mapController.rotate(-_direction!);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  Future<void> loadTarget() async {
    String url =
        'https://www.namazvakti.com/XML.php?cityID=${Provider.of<ChangeSettings>(context, listen: false).cityID}'; // Çevrimiçi XML dosyasının URL'si

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = response.body;
      final document = xml.XmlDocument.parse(data);

      final cityinfo = document.findAllElements('cityinfo').first;

      _target = double.parse(cityinfo.getAttribute('qiblaangle')!);
      if (_target! > 180) {
        _target = _target! - 360;
      }
    }
  }

  void _toggleMapLock() {
    setState(() {
      _isMapLocked = !_isMapLocked;
    });
  }

  void _toggleMapLayer() {
    setState(() {
      _currentMapLayer =
          _currentMapLayer == MapLayerType.street ? MapLayerType.satellite : MapLayerType.street;
    });
  }

  void _toggleCompassMode() {
    setState(() {
      _isCompassMode = !_isCompassMode;
    });

    if (_isCompassMode && _direction != null) {
      // Pusula moduna geçerken haritayı döndür
      _mapController.rotate(-_direction!);
    } else {
      // Normal moda geçerken haritayı sıfırla
      _mapController.rotate(0);
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
                  child: Provider.of<ChangeSettings>(context).isDark
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1,
                            0,
                            0,
                            0,
                            255,
                            0,
                            -1,
                            0,
                            0,
                            255,
                            0,
                            0,
                            -1,
                            0,
                            255,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Image.asset('assets/img/compass.png'),
                        )
                      : Image.asset('assets/img/compass.png'),
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

  Widget _buildMap() {
    _currentLocation = LatLng(Provider.of<ChangeSettings>(context, listen: false).currentLatitude!,
        Provider.of<ChangeSettings>(context, listen: false).currentLongitude!);
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Konum alınıyor...'),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _locationError!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (_currentLocation == null) {
      return const Center(
        child: Text('Konum bilgisi alınamadı'),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 17.0, // Daha da yüksek zoom seviyesi
              minZoom: 3.0,
              maxZoom: 18.0,
              // Kilitli durumda harita etkileşimini devre dışı bırak
              interactionOptions: InteractionOptions(
                flags: _isMapLocked ? InteractiveFlag.none : InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _currentMapLayer.urlTemplate,
                userAgentPackageName: 'com.kurtkadiroglu.prayertimes',
              ),
              // Kullanıcının mevcut konumu
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Kabe konumu
                  Marker(
                    point: _kaabaLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.place,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              // Kullanıcı konumundan Kabe'ye çizgi
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentLocation!, _kaabaLocation],
                    color: Colors.red,
                    strokeWidth: 3.0,
                  ),
                ],
              ),
            ],
          ),
          // Katman seçici butonu - sağ üst köşe
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Katman değiştirici butonu
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleMapLayer,
                    icon: Icon(
                      _currentMapLayer.icon,
                      size: 20,
                    ),
                    tooltip: 'Harita katmanını değiştir',
                  ),
                ),
                const SizedBox(height: 8),
                // Pusula butonu
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleCompassMode,
                    icon: Icon(
                      Icons.explore,
                      size: 20,
                      color: _isCompassMode
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: _isCompassMode ? 'Pusula modunu kapat' : 'Pusula modunu aç',
                  ),
                ),
              ],
            ),
          ),
          // Kilit butonu - sağ alt köşe
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _toggleMapLock,
                icon: Icon(
                  _isMapLocked ? Icons.lock : Icons.lock_open,
                  color: _isMapLocked
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                tooltip: _isMapLocked ? 'Haritayı kaydırmak için kilidi aç' : 'Haritayı kilitle',
              ),
            ),
          ),
        ],
      ),
    );
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          Provider.of<ChangeSettings>(context).rounded == true ? 50 : 10),
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: [
                          // Pusula sayfası
                          Center(child: _buildCompass()),
                          // Harita sayfası
                          _buildMap(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sekme göstergesi
                SegmentedButton<int>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.explore),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.map),
                    ),
                  ],
                  selected: {_currentPage},
                  onSelectionChanged: (Set<int> newSelection) {
                    _pageController.animateToPage(
                      newSelection.first,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
