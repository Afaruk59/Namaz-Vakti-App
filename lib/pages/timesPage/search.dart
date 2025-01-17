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

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  static List<dynamic> column1Data = [];
  static List<dynamic> column2Data = [];
  static List<dynamic> column3Data = [];
  static bool _first = true;
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredItems = [];

  void loadCities() async {
    final String csvData = await rootBundle.loadString("assets/cities/cities.csv");

    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
      eol: '\n', // Satır sonu ayırıcı
      fieldDelimiter: ',',
    ).convert(csvData);

    for (var row in rowsAsListOfValues) {
      if (row.isNotEmpty) {
        column1Data.add(row[0]);
        column2Data.add(row[1]);
        column3Data.add(row[2]);
      }
    }
    setState(() {
      _first = false;
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredItems = column2Data
          .asMap()
          .entries
          .where((entry) => entry.value.toLowerCase().contains(query.toLowerCase()))
          .map((entry) => entry.key)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    if (_first) {
      loadCities();
    }
    searchController.addListener(() {
      if (searchController.text.isNotEmpty) {
        filterSearchResults(searchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.searchTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Card(
            child: _first
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: EdgeInsets.all(
                        Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 10.0),
                    child: ListView.builder(
                      itemCount: filteredItems.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Card(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.search,
                                hintText: AppLocalizations.of(context)!.enterLoc,
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                ),
                              ),
                            ),
                          );
                        }
                        return Card(
                          color: Theme.of(context).cardColor,
                          child: ListTile(
                            leading: const Icon(Icons.location_city_rounded),
                            title: Text(column2Data[filteredItems[index - 1]]),
                            subtitle: Text(column3Data[filteredItems[index - 1]]),
                            trailing: FilledButton.tonal(
                                style: ElevatedButton.styleFrom(elevation: 10),
                                onPressed: () {
                                  Provider.of<ChangeSettings>(context, listen: false)
                                      .changeOtoLoc(false);
                                  String cityId = column1Data[filteredItems[index - 1]].toString();
                                  String cityName =
                                      column2Data[filteredItems[index - 1]].toString();
                                  String stateName =
                                      column3Data[filteredItems[index - 1]].toString();

                                  ChangeSettings()
                                      .saveLocaltoSharedPref(cityId, cityName, stateName);
                                  Navigator.pop(context);
                                  Provider.of<ChangeSettings>(context, listen: false).isfirst ==
                                          true
                                      ? Navigator.pop(context)
                                      : Navigator.popAndPushNamed(context, '/');
                                  Provider.of<ChangeSettings>(context, listen: false)
                                      .saveFirsttoSharedPref(false);
                                },
                                child: const Icon(Icons.arrow_circle_right_rounded)),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
