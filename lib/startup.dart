import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:namaz_vakti_app/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

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
                    child: Location(),
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
