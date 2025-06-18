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
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Image.asset(
              'assets/img/logo.png',
              height: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 150 : 200,
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
          ],
        ),
      ),
    );
  }
}
