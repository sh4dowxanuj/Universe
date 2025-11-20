// Stubs for missing packages
import 'package:flutter/material.dart';

class PersistentTabController {
  void jumpToTab(int index) {}
  void dispose() {}
}

class PersistentTabView extends StatelessWidget {
  final BuildContext context;
  final PersistentTabController controller;
  final int itemCount;
  final double navBarHeight;
  final Function(int) onItemTapped;
  final dynamic routeAndNavigatorSettings;
  final Widget? customWidget;
  final Function(RouteSettings)? onGenerateRoute;
  final List<Widget>? screens;
  PersistentTabView.custom(
    this.context, {
    required this.controller,
    required this.itemCount,
    required this.navBarHeight,
    required this.onItemTapped,
    required this.routeAndNavigatorSettings,
    this.customWidget,
    this.onGenerateRoute,
    this.screens,
  });
  @override
  Widget build(BuildContext context) {
    return customWidget ?? (screens != null && screens!.isNotEmpty ? screens!.first : Container(child: Text('PersistentTabView stub')));
  }
}

class CustomWidgetRouteAndNavigatorSettings {
  final dynamic routes;
  final Function(RouteSettings)? onGenerateRoute;
  CustomWidgetRouteAndNavigatorSettings({this.routes, this.onGenerateRoute});
}

class Audiotagger {
  Future<dynamic> readArtwork({required String path}) async => null;
  Future<dynamic> writeTags({required String path, required Tag tag}) async {}
  Future<Tag?> readTags({required String path}) async => null;
}

class Tag {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? year;
  final String? albumArtist;
  final String? artwork;
  final String? lyrics;
  final String? comment;
  Tag({this.title, this.artist, this.album, this.genre, this.year, this.albumArtist, this.artwork, this.lyrics, this.comment});
}
