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
                            final Uri url = Uri.parse(
                                'https://www.turktakvim.com/index.php?link=html/muhim_tenbih.html');
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
                        title: const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(AppLocalizations.of(context)!.lang),
                        trailing: PopupMenuButton<int>(
                          elevation: 10,
                          enabled: true,
                          onSelected: (int result) {
                            Provider.of<ChangeSettings>(context, listen: false)
                                .saveLanguage(result);
                          },
                          color: Theme.of(context).cardTheme.color!,
                          itemBuilder: (context) {
                            return <PopupMenuEntry<int>>[
                              const PopupMenuItem<int>(
                                value: 0,
                                child: Center(
                                  child: Text(
                                    'Türkçe',
                                  ),
                                ),
                              ),
                              const PopupMenuItem<int>(
                                value: 1,
                                child: Center(
                                  child: Text(
                                    'English',
                                  ),
                                ),
                              ),
                              const PopupMenuItem<int>(
                                value: 2,
                                child: Center(
                                  child: Text(
                                    'عربي',
                                  ),
                                ),
                              ),
                            ];
                          },
                        ),
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
