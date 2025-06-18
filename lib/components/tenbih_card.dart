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
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:url_launcher/url_launcher.dart';

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
