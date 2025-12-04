import 'package:blackhole/CustomWidgets/drawer.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/Screens/Settings/about.dart';
import 'package:blackhole/Screens/Settings/app_ui.dart';
import 'package:blackhole/Screens/Settings/backup_and_restore.dart';
import 'package:blackhole/Screens/Settings/download.dart';
import 'package:blackhole/Screens/Settings/music_playback.dart';
import 'package:blackhole/Screens/Settings/others.dart';
import 'package:blackhole/Screens/Settings/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class NewSettingsPage extends StatefulWidget {
  final Function? callback;
  const NewSettingsPage({this.callback});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage>
    with AutomaticKeepAliveClientMixin<NewSettingsPage> {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
  final List sectionsToShow = Hive.box('settings').get(
    'sectionsToShow',
    defaultValue: ['Home', 'Top Charts', 'YouTube', 'Library'],
  ) as List;

  @override
  void dispose() {
    controller.dispose();
    searchQuery.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => sectionsToShow.contains('Settings');

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: sectionsToShow.contains('Settings')
                  ? homeDrawer(
                      context: context,
                      padding: const EdgeInsets.only(left: 15.0),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  AppLocalizations.of(context)!.settings,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _searchBar(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _settingsGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: SizedBox(
        height: 54.0,
        child: Center(
          child: ValueListenableBuilder(
            valueListenable: searchQuery,
            builder: (BuildContext context, String query, Widget? child) {
              return TextField(
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                decoration: InputDecoration(
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  suffixIcon: query.trim() != ''
                      ? IconButton(
                          onPressed: () {
                            controller.clear();
                            searchQuery.value = '';
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white54 : Colors.grey[500],
                          ),
                        )
                      : null,
                  hintText: AppLocalizations.of(context)!.search,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  searchQuery.value = controller.text.trim();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _settingsGrid(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> settingsList = [
      {
        'title': AppLocalizations.of(context)!.theme,
        'icon': MdiIcons.themeLightDark,
        'color': Colors.purple,
        'onTap': ThemePage(callback: widget.callback),
        'description': 'Colors, gradients & appearance',
        'items': [
          AppLocalizations.of(context)!.darkMode,
          AppLocalizations.of(context)!.accent,
          AppLocalizations.of(context)!.useSystemTheme,
          AppLocalizations.of(context)!.bgGrad,
          AppLocalizations.of(context)!.cardGrad,
          AppLocalizations.of(context)!.bottomGrad,
          AppLocalizations.of(context)!.canvasColor,
          AppLocalizations.of(context)!.cardColor,
          AppLocalizations.of(context)!.useAmoled,
          AppLocalizations.of(context)!.currentTheme,
          AppLocalizations.of(context)!.saveTheme,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.ui,
        'icon': Icons.design_services_rounded,
        'color': Colors.blue,
        'onTap': AppUIPage(callback: widget.callback),
        'description': 'Layout & interface options',
        'items': [
          AppLocalizations.of(context)!.playerScreenBackground,
          AppLocalizations.of(context)!.miniButtons,
          AppLocalizations.of(context)!.useDenseMini,
          AppLocalizations.of(context)!.blacklistedHomeSections,
          AppLocalizations.of(context)!.changeOrder,
          AppLocalizations.of(context)!.compactNotificationButtons,
          AppLocalizations.of(context)!.showPlaylists,
          AppLocalizations.of(context)!.showLast,
          AppLocalizations.of(context)!.navTabs,
          AppLocalizations.of(context)!.enableGesture,
          AppLocalizations.of(context)!.volumeGestureEnabled,
          AppLocalizations.of(context)!.useLessDataImage,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.musicPlayback,
        'icon': Icons.music_note_rounded,
        'color': Colors.green,
        'onTap': MusicPlaybackPage(callback: widget.callback),
        'description': 'Quality & playback settings',
        'items': [
          AppLocalizations.of(context)!.musicLang,
          AppLocalizations.of(context)!.streamQuality,
          AppLocalizations.of(context)!.chartLocation,
          AppLocalizations.of(context)!.streamWifiQuality,
          AppLocalizations.of(context)!.ytStreamQuality,
          AppLocalizations.of(context)!.loadLast,
          AppLocalizations.of(context)!.resetOnSkip,
          AppLocalizations.of(context)!.enforceRepeat,
          AppLocalizations.of(context)!.autoplay,
          AppLocalizations.of(context)!.cacheSong,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.down,
        'icon': Icons.download_rounded,
        'color': Colors.orange,
        'onTap': const DownloadPage(),
        'description': 'Download location & quality',
        'items': [
          AppLocalizations.of(context)!.downQuality,
          AppLocalizations.of(context)!.downLocation,
          AppLocalizations.of(context)!.downFilename,
          AppLocalizations.of(context)!.ytDownQuality,
          AppLocalizations.of(context)!.createAlbumFold,
          AppLocalizations.of(context)!.createYtFold,
          AppLocalizations.of(context)!.downLyrics,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.others,
        'icon': Icons.tune_rounded,
        'color': Colors.teal,
        'onTap': const OthersPage(),
        'description': 'Language & additional options',
        'items': [
          AppLocalizations.of(context)!.lang,
          AppLocalizations.of(context)!.includeExcludeFolder,
          AppLocalizations.of(context)!.minAudioLen,
          AppLocalizations.of(context)!.liveSearch,
          AppLocalizations.of(context)!.useDown,
          AppLocalizations.of(context)!.getLyricsOnline,
          AppLocalizations.of(context)!.supportEq,
          AppLocalizations.of(context)!.stopOnClose,
          AppLocalizations.of(context)!.checkUpdate,
          AppLocalizations.of(context)!.useProxy,
          AppLocalizations.of(context)!.proxySet,
          AppLocalizations.of(context)!.clearCache,
          AppLocalizations.of(context)!.shareLogs,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.backNRest,
        'icon': Icons.cloud_sync_rounded,
        'color': Colors.indigo,
        'onTap': const BackupAndRestorePage(),
        'description': 'Backup & restore your data',
        'items': [
          AppLocalizations.of(context)!.createBack,
          AppLocalizations.of(context)!.restore,
          AppLocalizations.of(context)!.autoBack,
          AppLocalizations.of(context)!.autoBackLocation,
        ],
      },
      {
        'title': AppLocalizations.of(context)!.about,
        'icon': Icons.info_outline_rounded,
        'color': Colors.red,
        'onTap': const AboutPage(),
        'description': 'App info & support',
        'items': [
          AppLocalizations.of(context)!.version,
          AppLocalizations.of(context)!.shareApp,
          AppLocalizations.of(context)!.contactUs,
          AppLocalizations.of(context)!.likedWork,
          AppLocalizations.of(context)!.donateGpay,
          AppLocalizations.of(context)!.joinTg,
          AppLocalizations.of(context)!.moreInfo,
        ],
      },
    ];

    final List<Map> searchOptions = [];
    for (final Map e in settingsList) {
      for (final item in e['items'] as List) {
        searchOptions.add({'title': item, 'route': e['onTap']});
      }
    }

    return ValueListenableBuilder(
      valueListenable: searchQuery,
      builder: (BuildContext context, String query, Widget? child) {
        if (query != '') {
          final List<Map> results = _getSearchResults(searchOptions, query);
          return SliverToBoxAdapter(
            child: _searchSuggestions(context, results),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = settingsList[index];
              return _buildSettingsCard(
                context: context,
                title: item['title'].toString(),
                description: item['description'].toString(),
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
                onTap: () {
                  searchQuery.value = '';
                  controller.text = '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item['onTap'] as Widget,
                    ),
                  );
                },
              );
            },
            childCount: settingsList.length,
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? null
                  : Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map> _getSearchResults(
    List<Map> searchOptions,
    String query,
  ) {
    final List<Map> options = query != ''
        ? searchOptions
            .where(
              (element) =>
                  element['title'].toString().toLowerCase().contains(query),
            )
            .toList()
        : List.empty();
    return options;
  }

  Widget _searchSuggestions(
    BuildContext context,
    List<Map> options,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            ),
            title: Text(
              options[index]['title'].toString(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            onTap: () {
              searchQuery.value = '';
              controller.text = '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => options[index]['route'] as Widget,
                  settings: RouteSettings(
                    arguments: options[index]['title'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
