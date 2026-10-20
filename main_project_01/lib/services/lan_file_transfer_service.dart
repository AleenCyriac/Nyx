
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LanFileTransferService {
  static const int port = 4041;
  static const int _maxHeaderBytes = 16 * 1024;
  static const int _maxFileBytes = 100 * 1024 * 1024;

  ServerSocket? _server;
  final Set<Socket> _clients = {};

  final StreamController<Map<String, dynamic>>
  _receivedFilesController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get receivedFiles =>
      _receivedFilesController.stream;

  Future<void> start() async {
    if (_server != null) return;

    _server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
    );

    _server!.listen((socket) {
      _clients.add(socket);
      _receiveFile(socket);
    });

    debugPrint('LAN file listener started on port $port');
  }

  Future<void> _receiveFile(Socket socket) async {
    RandomAccessFile? output;
    String? savePath;

    try {
      // Read the header one byte at a time until newline.
      final headerBytes = <int>[];
      final iterator = StreamIterator<List<int>>(socket);

      try {
        bool headerComplete = false;

        while (await iterator.moveNext()) {
          for (final byte in iterator.current) {
            if (byte == 10) {
              headerComplete = true;
              break;
            }

            headerBytes.add(byte);

            if (headerBytes.length > _maxHeaderBytes) {
              throw const FormatException('File header too large');
            }
          }

          if (headerComplete) break;
        }

        if (!headerComplete) {
          throw const FormatException('Incomplete file header');
        }

        final header = jsonDecode(utf8.decode(headerBytes));

        if (header is! Map<String, dynamic>) {
          throw const FormatException('Invalid file header');
        }

        final fileName =
        (header['file_name'] ?? 'attachment.bin').toString();

        final fileSize = header['file_size'];

        if (fileSize is! int ||
            fileSize < 0 ||
            fileSize > _maxFileBytes) {
          throw const FormatException('Invalid file size');
        }

        final senderId = header['sender_id'];
        final receiverId = header['receiver_id'];

        // The receiver ID is checked by the caller's app logic.
        final directory = await getApplicationDocumentsDirectory();
        final safeName = fileName
            .replaceAll('\\', '_')
            .replaceAll('/', '_')
            .replaceAll('..', '_');

        final fileId =
            '${DateTime.now().microsecondsSinceEpoch}_$safeName';

        savePath = '${directory.path}/$fileId';
        output = await File(savePath).open(mode: FileMode.write);

        var receivedBytes = 0;

        // Consume the remaining socket stream as raw bytes.
        while (receivedBytes < fileSize &&
            await iterator.moveNext()) {
          final chunk = iterator.current;
          final remaining = fileSize - receivedBytes;
          final bytesToWrite = chunk.length > remaining
              ? chunk.sublist(0, remaining)
              : chunk;

          await output.writeFrom(bytesToWrite);
          receivedBytes += bytesToWrite.length;
        }

        if (receivedBytes != fileSize) {
          throw const SocketException('File transfer ended early');
        }

        await output.flush();
        await output.close();
        output = null;

        _receivedFilesController.add({
          'file_name': fileName,
          'file_path': savePath,
          'file_size': fileSize,
          'sender_id': senderId,
          'receiver_id': receiverId,
        });

        debugPrint('Received file: $savePath');
      } finally {
        await iterator.cancel();
      }
    } catch (e) {
      debugPrint('LAN file receive failed: $e');

      if (savePath != null) {
        try {
          await File(savePath).delete();
        } catch (_) {}
      }
    } finally {
      await output?.close();
      _clients.remove(socket);
      await socket.close();
    }
  }

  Future<void> sendFile({
    required String host,
    required String filePath,
    required String fileName,
    required int senderId,
    required int receiverId,
  }) async {
    final file = File(filePath);
    final fileSize = await file.length();

    if (fileSize > _maxFileBytes) {
      throw Exception('Files must be 100 MB or smaller.');
    }

    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );

    try {
      final header = jsonEncode({
        'file_name': fileName,
        'file_size': fileSize,
        'sender_id': senderId,
        'receiver_id': receiverId,
      });

      socket.write('$header\n');
      await socket.flush();

      await for (final chunk in file.openRead()) {
        socket.add(chunk);
      }

      await socket.flush();
      debugPrint('File sent to $host:$port');
    } finally {
      await socket.close();
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;

    for (final socket in _clients.toList()) {
      await socket.close();
    }

    _clients.clear();
    debugPrint('LAN file listener stopped');
  }

  Future<void> dispose() async {
    await stop();
    await _receivedFilesController.close();
  }
}
