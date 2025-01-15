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
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/home_page.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/pages/startup.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.aboutTitle),
        ),
        body: const AboutPage(),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: const CircleBorder(),
                color: Theme.of(context).cardColor,
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
                height: Provider.of<ChangeSettings>(context).currentHeight! < 700 ? 10 : 40,
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.licenseTitle),
                    onTap: () {
                      Navigator.pushNamed(context, '/license');
                    },
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        Navigator.pushNamed(context, '/license');
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                      ),
                      child: const Icon(
                        Icons.text_snippet_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5 : 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.githubTitle),
                    onTap: () async {
                      Uri? url = Uri.parse('https://github.com/Afaruk59/Namaz-Vakti-App.git');
                      await launchUrl(url);
                    },
                    trailing: FilledButton.tonal(
                      onPressed: () async {
                        Uri? url = Uri.parse('https://github.com/Afaruk59/Namaz-Vakti-App.git');
                        await launchUrl(url);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                      ),
                      child: const Icon(
                        Icons.webhook_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              const TimeNote(),
            ],
          ),
        ),
      ),
    );
  }
}
