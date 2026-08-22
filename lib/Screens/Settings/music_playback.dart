import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:universe/CustomWidgets/box_switch_tile.dart';
import 'package:universe/CustomWidgets/gradient_containers.dart';
import 'package:universe/CustomWidgets/snackbar.dart';
import 'package:universe/Helpers/spotify_country.dart';
import 'package:universe/Screens/Home/saavn.dart' as home_screen;
import 'package:universe/src/gen_l10n/app_localizations.dart';

class MusicPlaybackPage extends StatefulWidget {
  final Function? callback;
  const MusicPlaybackPage({super.key, this.callback});

  @override
  State<MusicPlaybackPage> createState() => _MusicPlaybackPageState();
}

class _MusicPlaybackPageState extends State<MusicPlaybackPage> {
  String streamingMobileQuality = Hive.box('settings')
      .get('streamingQuality', defaultValue: '96 kbps') as String;
  String streamingWifiQuality = Hive.box('settings')
      .get('streamingWifiQuality', defaultValue: '320 kbps') as String;
  String ytQuality =
      Hive.box('settings').get('ytQuality', defaultValue: 'Low') as String;
  String region =
      Hive.box('settings').get('region', defaultValue: 'India') as String;
  List<String> languages = [
    'Hindi',
    'English',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Kannada',
    'Bhojpuri',
    'Malayalam',
    'Urdu',
    'Haryanvi',
    'Rajasthani',
    'Odia',
    'Assamese',
  ];
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(
              context,
            )!
                .musicPlayback,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(10.0),
          children: [
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .musicLang,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .musicLangSub,
              ),
              trailing: SizedBox(
                width: 150,
                child: Text(
                  preferredLanguage.isEmpty
                      ? 'None'
                      : preferredLanguage.join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              dense: true,
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    final List checked = List.from(preferredLanguage);
                    return StatefulBuilder(
                      builder: (
                        BuildContext context,
                        StateSetter setStt,
                      ) {
                        return BottomGradientContainer(
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    10,
                                    0,
                                    10,
                                  ),
                                  itemCount: languages.length,
                                  itemBuilder: (context, idx) {
                                    return CheckboxListTile(
                                      activeColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      checkColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary ==
                                              Colors.white
                                          ? Colors.black
                                          : null,
                                      value: checked.contains(
                                        languages[idx],
                                      ),
                                      title: Text(
                                        languages[idx],
                                      ),
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          if (value) {
                                            checked.add(languages[idx]);
                                          } else {
                                            checked.remove(
                                              languages[idx],
                                            );
                                          }
                                          setStt(
                                            () {},
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .cancel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () {
                                          preferredLanguage = checked;
                                          Navigator.pop(context);
                                          Hive.box('settings').put(
                                            'preferredLanguage',
                                            checked,
                                          );
                                          home_screen.fetched = false;
                                          home_screen.preferredLanguage =
                                              preferredLanguage;
                                          widget.callback!();
                                        },
                                      );
                                      if (preferredLanguage.isEmpty) {
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .noLangSelected,
                                        );
                                      }
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .ok,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .chartLocation,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .chartLocationSub,
              ),
              trailing: SizedBox(
                width: 150,
                child: Text(
                  region,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              dense: true,
              onTap: () async {
                region = await SpotifyCountry().changeCountry(context: context);
                setState(
                  () {},
                );
              },
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .streamQuality,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .streamQualitySub,
              ),
              onTap: () {},
              trailing: DropdownButton(
                value: streamingMobileQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        streamingMobileQuality = newValue;
                        Hive.box('settings').put('streamingQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['96 kbps', '160 kbps', '320 kbps']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              dense: true,
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .streamWifiQuality,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .streamWifiQualitySub,
              ),
              onTap: () {},
              trailing: DropdownButton(
                value: streamingWifiQuality,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(
                      () {
                        streamingWifiQuality = newValue;
                        Hive.box('settings')
                            .put('streamingWifiQuality', newValue);
                      },
                    );
                  }
                },
                items: <String>['96 kbps', '160 kbps', '320 kbps']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              dense: true,
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .ytStreamQuality,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .ytStreamQualitySub,
              ),
              onTap: () {},
              trailing: SizedBox(
                width: 100,
                child: DropdownButton(
                  value: ['Low', 'Medium', 'High'].contains(ytQuality)
                      ? ytQuality
                      : 'Low',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(
                        () {
                          ytQuality = newValue;
                          Hive.box('settings').put('ytQuality', newValue);
                        },
                      );
                    }
                  },
                  items: <String>['Low', 'Medium', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              dense: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .loadLast,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .loadLastSub,
              ),
              keyName: 'loadStart',
              defaultValue: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .resetOnSkip,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .resetOnSkipSub,
              ),
              keyName: 'resetOnSkip',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .enforceRepeat,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .enforceRepeatSub,
              ),
              keyName: 'enforceRepeat',
              defaultValue: false,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .autoplay,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .autoplaySub,
              ),
              keyName: 'autoplay',
              defaultValue: true,
              isThreeLine: true,
            ),
            BoxSwitchTile(
              title: Text(
                AppLocalizations.of(
                  context,
                )!
                    .cacheSong,
              ),
              subtitle: Text(
                AppLocalizations.of(
                  context,
                )!
                    .cacheSongSub,
              ),
              keyName: 'cacheSong',
              defaultValue: true,
            ),
          ],
        ),
      ),
    );
  }
}
