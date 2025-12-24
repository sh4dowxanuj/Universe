import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Web stub for download functionality: disables downloads gracefully.
class Download with ChangeNotifier {
  static final Map<String, Download> _instances = {};
  final String id;

  factory Download(String id) {
    if (_instances.containsKey(id)) return _instances[id]!;
    final instance = Download._internal(id);
    _instances[id] = instance;
    return instance;
  }

  Download._internal(this.id);

  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  double? progress = 0.0;
  String lastDownloadId = '';
  bool download = false;

  Future<void> prepareDownload(
    BuildContext context,
    Map data, {
    bool createFolder = false,
    String? folderName,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.sorry ??
              'Downloads not supported on web',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
