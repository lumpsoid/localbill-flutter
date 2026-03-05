import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../lib/router.dart';
import '../lib/storage.dart';

void main(List<String> args) async {
  final port = int.tryParse(
        Platform.environment['PORT'] ?? '',
      ) ??
      (args.isNotEmpty ? int.tryParse(args[0]) : null) ??
      8080;

  final dataDir = Platform.environment['DATA_DIR'] ?? 'data';
  final storage = JsonStorage(dataDir: dataDir);

  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(buildRouter(storage).call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('localbill-server listening on http://${server.address.host}:${server.port}');
  print('Data directory: $dataDir/');
}

/// Permissive CORS for LAN use (the Flutter app may run on a different host).
Middleware _corsMiddleware() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}
