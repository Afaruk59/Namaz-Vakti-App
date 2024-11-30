/*
Copyright [2024] [Afaruk59]

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
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/change_settings.dart';

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(AppLocalizations.of(context)!.startupTitle),
          ),
          body: const StartupCard(),
        ),
      ),
    );
  }
}

class StartupCard extends StatelessWidget {
  const StartupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
            child: Card(
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.startupDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.tenbih,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          Uri? url;
                          if (Provider.of<ChangeSettings>(context, listen: false).langCode ==
                              'tr') {
                            url = Uri.parse(
                                'https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
                          } else {
                            url = Uri.parse(
                                'https://www.turktakvim.com/index.php?link=html/en/Important_Cautions.html');
                          }
                          await launchUrl(url);
                        },
                        trailing: FilledButton.tonal(
                          style: ElevatedButton.styleFrom(elevation: 10),
                          onPressed: () async {
                            Uri? url;
                            if (Provider.of<ChangeSettings>(context, listen: false).langCode ==
                                'tr') {
                              url = Uri.parse(
                                  'https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
                            } else {
                              url = Uri.parse(
                                  'https://www.turktakvim.com/index.php?link=html/en/Important_Cautions.html');
                            }
                            await launchUrl(url);
                          },
                          child: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                        title: const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(AppLocalizations.of(context)!.lang),
                        trailing: const LangSelector(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Location(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
