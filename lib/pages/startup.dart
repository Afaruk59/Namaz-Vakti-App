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
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/pages/timesPage/times.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';

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
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.settings),
              ),
              const SizedBox(
                width: 20,
              ),
            ],
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/img/logo.png',
                  height: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 150 : 200,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.appName,
                style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.bold,
                    fontSize: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 25 : 30,
                    color: Theme.of(context).primaryColor),
              ),
              Text(
                '${MainApp.version} - by Afaruk59',
                style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(
                height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 0 : 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TimeNote(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: TenbihCard(),
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
              SizedBox(
                height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 0 : 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Location(),
                      ),
                    ),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: const SearchButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeNote extends StatelessWidget {
  const TimeNote({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: ListTile(
        title: Text(
          AppLocalizations.of(context)!.startupDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

class TenbihCard extends StatelessWidget {
  const TenbihCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
        child: ListTile(
          title: Text(
            AppLocalizations.of(context)!.tenbih,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () async {
            Uri? url;
            if (Provider.of<ChangeSettings>(context, listen: false).langCode == 'tr') {
              url = Uri.parse('https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
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
              if (Provider.of<ChangeSettings>(context, listen: false).langCode == 'tr') {
                url = Uri.parse('https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
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
    );
  }
}
