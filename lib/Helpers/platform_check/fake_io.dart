import 'dart:async';

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<File> copy(String path) async => this;
  Future<void> delete({bool recursive = false}) async {}
  void deleteSync({bool recursive = false}) {}
  Future<File> create({bool recursive = false}) async => this;
  Future<void> writeAsString(String contents, {FileMode mode = FileMode.write, bool flush = false}) async {}
  Future<void> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) async {}
  void writeAsBytesSync(List<int> bytes) {}
  Future<String> readAsString() async => '';
  Future<List<int>> readAsBytes() async => [];
  int lengthSync() => 0;
}

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) => const Stream.empty();
  Future<void> delete({bool recursive = false}) async {}
}

class SocketException implements Exception {
  final String message;
  SocketException(this.message);
}

class InternetAddress {
  final String address;
  final List<int> rawAddress;
  InternetAddress(this.address, this.rawAddress);
  static Future<List<InternetAddress>> lookup(String host) async => [];
}

abstract class FileSystemEntity {
  String get path;
}

enum FileMode { read, write, append, writeOnly, writeOnlyAppend }

class HttpClient {
  Future<HttpClientRequest> getUrl(Uri url) async => FakeHttpClientRequest();
}

abstract class HttpClientRequest {
  Future<HttpClientResponse> close();
}

class FakeHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => FakeHttpClientResponse();
}

abstract class HttpClientResponse extends Stream<List<int>> {
  int get contentLength;
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream<List<int>>.empty().listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  @override
  int get contentLength => 0;
}

class FileSystemException implements Exception {
  final String message;
  final String path;
  FileSystemException([this.message = "", this.path = ""]);
}
