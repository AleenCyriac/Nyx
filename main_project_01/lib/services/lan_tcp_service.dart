
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class LanTcpService {
  static const int port = 4040;

  ServerSocket? _server;
  final Set<Socket> _clients = {};

  final StreamController<Map<String, dynamic>>
  _messageController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingMessages =>
      _messageController.stream;

  Future<void> start({
    required void Function(Map<String, dynamic> message)
    onMessage,
  }) async {
    if (_server != null) return;

    _server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
    );

    _server!.listen((socket) {
      _clients.add(socket);

      debugPrint(
        'TCP peer connected: ${socket.remoteAddress.address}',
      );

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
          try {
            final decoded = jsonDecode(line);

            if (decoded is Map<String, dynamic>) {
              onMessage(decoded);
              _messageController.add(decoded);
            }
          } catch (e) {
            debugPrint('Invalid TCP message: $e');
          }
        },
        onError: (error) {
          debugPrint('TCP receive error: $error');
        },
        onDone: () {
          _clients.remove(socket);
          debugPrint('TCP peer disconnected');
        },
        cancelOnError: true,
      );
    });

    debugPrint('TCP listener started on port $port');
  }

  Future<void> sendMessage({
    required String host,
    int port = LanTcpService.port,
    required Map<String, dynamic> message,
  }) async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      socket.write('${jsonEncode(message)}\n');
      await socket.flush();

      debugPrint('TCP message written to $host:$port');
    } finally {
      if (socket != null) {
        await socket.close();
      }
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;

    for (final socket in _clients.toList()) {
      await socket.close();
    }

    _clients.clear();

    debugPrint('TCP listener stopped');
  }

  Future<void> dispose() async {
    await stop();
    await _messageController.close();
  }
}
