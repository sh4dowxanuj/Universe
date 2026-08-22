/*
 *  This file is part of Universe (https://github.com/SH4DOWXANUJ/Universe).
 * 
 * Universe is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Universe is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Universe.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, SH4DOWXANUJ
 */

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universe/CustomWidgets/copy_clipboard.dart';
import 'package:universe/CustomWidgets/gradient_containers.dart';
import 'package:universe/CustomWidgets/snackbar.dart';
import 'package:universe/Helpers/github.dart';
import 'package:universe/Helpers/mdi_icons.dart';
import 'package:universe/Helpers/platform_check.dart';
import 'package:universe/Helpers/update.dart';
import 'package:universe/src/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? appVersion;

  @override
  void initState() {
    main();
    super.initState();
  }

  Future<void> main() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(
      () {},
    );
  }

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
                .about,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          iconTheme: IconThemeData(
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .version,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .versionSub,
                        ),
                        onTap: () {
                          ShowSnackBar().showSnackBar(
                            context,
                            AppLocalizations.of(
                              context,
                            )!
                                .checkingUpdate,
                            noAction: true,
                          );

                          GitHub.getLatestVersion().then(
                            (String latestVersion) async {
                              if (compareVersion(
                                latestVersion,
                                appVersion!,
                              )) {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  AppLocalizations.of(context)!.updateAvailable,
                                  duration: const Duration(seconds: 15),
                                  action: SnackBarAction(
                                    textColor:
                                        Theme.of(context).colorScheme.secondary,
                                    label: AppLocalizations.of(context)!.update,
                                    onPressed: () async {
                                      String arch = '';
                                      if (PlatformCheck.isAndroid) {
                                        List? abis = await Hive.box('settings')
                                            .get('supportedAbis') as List?;

                                        if (abis == null) {
                                          final DeviceInfoPlugin deviceInfo =
                                              DeviceInfoPlugin();
                                          final AndroidDeviceInfo
                                              androidDeviceInfo =
                                              await deviceInfo.androidInfo;
                                          abis =
                                              androidDeviceInfo.supportedAbis;
                                          await Hive.box('settings')
                                              .put('supportedAbis', abis);
                                        }
                                        if (abis.contains('arm64')) {
                                          arch = 'arm64';
                                        } else if (abis.contains('armeabi')) {
                                          arch = 'armeabi';
                                        }
                                      }
                                      Navigator.pop(context);
                                      launchUrl(
                                        Uri.parse(
                                          'https://sangwan5688.github.io/download?platform=${PlatformCheck.operatingSystem}&arch=$arch',
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .latest,
                                );
                              }
                            },
                          );
                        },
                        trailing: Text(
                          'v$appVersion',
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .shareApp,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .shareAppSub,
                        ),
                        onTap: () {
                          Share.share(
                            '${AppLocalizations.of(
                              context,
                            )!.shareAppText}: none',
                          );
                        },
                        dense: true,
                      ),
                      const ListTile(
                        title: Text(
                          'Universe',
                        ),
                        subtitle: Text(
                          'An Open Source Music Player',
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .likedWork,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .buyCoffee,
                        ),
                        dense: true,
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'null',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .donateGpay,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .donateGpaySub,
                        ),
                        dense: true,
                        isThreeLine: true,
                        onTap: () {
                          const String upiUrl =
                              'null';
                          launchUrl(
                            Uri.parse(upiUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        onLongPress: () {
                          copyToClipboard(
                            context: context,
                            text: 'none',
                            displayText: AppLocalizations.of(
                              context,
                            )!
                                .upiCopied,
                          );
                        },
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
                          ),
                          onPressed: () {
                            copyToClipboard(
                              context: context,
                              text: 'null',
                              displayText: AppLocalizations.of(
                                context,
                              )!
                                  .upiCopied,
                            );
                          },
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .copy,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .contactUs,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .contactUsSub,
                        ),
                        dense: true,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: 100,
                                child: GradientContainer(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.gmail,
                                            ),
                                            iconSize: 40,
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!
                                                .gmail,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'null',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .gmail,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.send,
                                            ),
                                            iconSize: 40,
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!
                                                .tg,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'null',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .tg,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.instagram,
                                            ),
                                            iconSize: 40,
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!
                                                .insta,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'null',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .insta,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                              .joinTg,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .joinTgSub,
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height: 100,
                                child: GradientContainer(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.send,
                                            ),
                                            iconSize: 40,
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!
                                                .tgGp,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'null',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .tgGp,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              MdiIcons.send,
                                            ),
                                            iconSize: 40,
                                            tooltip: AppLocalizations.of(
                                              context,
                                            )!
                                                .tgCh,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launchUrl(
                                                Uri.parse(
                                                  'null',
                                                ),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                          ),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .tgCh,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .moreInfo,
                        ),
                        dense: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.madeBy,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
