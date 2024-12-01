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

import 'package:flutter_gen/gen_l10n/app_localization.dart';

class License extends StatelessWidget {
  const License({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBack(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.licenseTitle),
        ),
        body: const LicensePage(),
      ),
    );
  }
}

class LicensePage extends StatelessWidget {
  const LicensePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Card(
            color: Theme.of(context).cardColor,
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '''
A globally functioning prayer times application developed with Flutter.
                  
Copyright [2024] [Afaruk59]
                  
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
                  
http://www.apache.org/licenses/LICENSE-2.0
                  
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
          ''',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16),
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
