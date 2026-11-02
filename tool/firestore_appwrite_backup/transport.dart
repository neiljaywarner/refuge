import 'dart:convert';
import 'dart:io';

class const BackupRequest({
  required final String method,
  required final Uri url,
  required final Map<String, String> headers,
  final String? body,
});

class const BackupResponse({required final int statusCode, required final String body});

abstract interface class BackupTransport {
  Future<BackupResponse> send(BackupRequest request);
}

/// Real HTTP client. Tests pass a stand-in and never open a socket.
class IoBackupTransport implements BackupTransport {
  IoBackupTransport({HttpClient? client}) : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 30);
  }

  final HttpClient _client;

  @override
  Future<BackupResponse> send(BackupRequest request) async {
    final http = switch (request.method) {
      'GET' => await _client.getUrl(request.url),
      'POST' => await _client.postUrl(request.url),
      'PUT' => await _client.putUrl(request.url),
      'PATCH' => await _client.patchUrl(request.url),
      _ => throw ArgumentError('Unsupported method ${request.method}'),
    };
    request.headers.forEach(http.headers.set);
    final body = request.body;
    if (body != null) http.write(body);
    final response = await http.close();
    final text = await response.transform(utf8.decoder).join();
    return BackupResponse(statusCode: response.statusCode, body: text);
  }
}
