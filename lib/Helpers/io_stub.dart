class File {
  File();
  Future<bool> exists() async => false;
  Future<void> delete() async {}
}

class Directory {
  Directory();
  String get path => '';
}
