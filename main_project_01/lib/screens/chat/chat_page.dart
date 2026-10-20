import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

import 'package:main_project_01/services/lan_discovery_service.dart';
import 'package:main_project_01/services/lan_tcp_service.dart';
import 'package:main_project_01/services/pending_message_store.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:main_project_01/services/lan_file_transfer_service.dart';
import 'package:main_project_01/services/attachment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final int userId;
  final int receiverId;
  final String receiverName;

  final LanDiscoveryService lanDiscoveryService;
  final LanTcpService lanTcpService;

  const ChatPage({super.key,required this.userId,required this.receiverId,required this.receiverName,required this.lanDiscoveryService,required this.lanTcpService,});

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>
{
  //for opening attachments(pdf's)


  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      debugPrint('Invalid attachment URL: $url');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      debugPrint('Attachment URL: $url');
      debugPrint('Attachment opened: $opened');

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open attachment. Check the debug console.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Open attachment error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open failed: $e')),
      );
    }
  }


  //file -to shoe images and files
  Widget _buildMessageContent(dynamic rawMessage) {
    Map<String, dynamic>? decoded;

    if (rawMessage is String) {
      try {
        final value = jsonDecode(rawMessage);
        if (value is Map) {
          decoded = Map<String, dynamic>.from(value);
        }
      } catch (_) {
        // Ordinary text message.
      }
    } else if (rawMessage is Map) {
      decoded = Map<String, dynamic>.from(rawMessage);
    }

    if (decoded == null || decoded['type'] != 'attachment') {
      return Text((rawMessage ?? '').toString());
    }

    final rawAttachment = decoded['attachment'];

    if (rawAttachment is! Map) {
      return const Text('Attachment details unavailable');
    }

    final attachment = Map<String, dynamic>.from(rawAttachment);
    final name = (attachment['file_name'] ?? 'File').toString();
    final mimeType = (attachment['mime_type'] ?? '').toString();
    var url = (attachment['file_url'] ?? '').toString();

    if (url.startsWith('/')) {
      url = 'http://192.168.1.33:3000$url';
    }

    final isImage = mimeType.startsWith('image/') ||
        name.toLowerCase().endsWith('.png') ||
        name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.gif') ||
        name.toLowerCase().endsWith('.webp');

    final isPdf = name.toLowerCase().endsWith('.pdf');

    if (isImage && url.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name),
          const SizedBox(height: 8),
          Image.network(
            url,
            width: 220,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Could not load image');
            },
          ),
        ],
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
      ),
      title: Text(name),
      subtitle: Text(
        '${(attachment['file_size'] ?? 0)} bytes',
      ),
      trailing: const Icon(Icons.open_in_new),
      onTap: url.isEmpty ? null : () => _openAttachment(url),
    );
  }



  //file-end
  //lan
  StreamSubscription<Map<String, dynamic>>? _lanSubscription;

  final PendingMessageStore _pendingStore = PendingMessageStore();

  Timer? _syncTimer;
  bool _isSyncing = false;

  //file transfer service
  final AttachmentService _attachmentService = AttachmentService();
  final LanFileTransferService _fileTransferService =
  LanFileTransferService();

  StreamSubscription<Map<String, dynamic>>? _fileSubscription;

//file picker attachment



  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${file.name}...')),
      );

      final attachment = await _attachmentService.uploadFile(
        file: file,
        senderId: widget.userId,
        receiverId: widget.receiverId,
      );

      final messageId =
          '${widget.userId}_${DateTime.now().microsecondsSinceEpoch}';

      final messageData = <String, dynamic>{
        'sender_id': widget.userId,
        'receiver_id': widget.receiverId,
        'message': jsonEncode({
          'type': 'attachment',
          'attachment': attachment,
        }),
        'message_id': messageId,
        'client_message_id': messageId,
        'created_at': DateTime.now().toIso8601String(),
        'type': 'attachment',
      };

      await _pendingStore.saveConversationMessage(
        widget.userId,
        widget.receiverId,
        messageData,
      );

      await _pendingStore.savePendingMessage(
        widget.userId,
        messageData,
      );

      if (!mounted) return;

      setState(() {
        messages = _mergeMessages(messages, [messageData]);
      });

      if (socket.connected) {
        socket.emit('send_message', messageData);
      }

      await _syncPendingMessages();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} attached to the chat.')),
      );
    } catch (e) {
      debugPrint('Attachment sending failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send attachment. Check the connection.'),
        ),
      );
    }
  }


  Future<void> _syncPendingMessages() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final pendingMessages =
      await _pendingStore.getPendingMessages(widget.userId);

      for (final data in pendingMessages) {
        try {
          final messageId =
          data['client_message_id'].toString();

          final response = await http.post(
            Uri.parse('http://192.168.1.33:3000/chat'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'sender_id': data['sender_id'],
              'receiver_id': data['receiver_id'],
              'message': data['message'],
              'client_message_id': messageId,
            }),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);

            if (result['success'] == true) {
              await _pendingStore.removePendingMessage(
                widget.userId,
                messageId,
              );

              debugPrint(
                'Pending message synchronized: $messageId',
              );
            }
          }
        } catch (e) {
          // Keep the message in the queue for another attempt.
          debugPrint('Pending message sync failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not read pending messages: $e');
    } finally {
      _isSyncing = false;
    }
  }


  //lan
  late IO.Socket socket;
  List<dynamic> messages = [];
  final TextEditingController messageController = TextEditingController();

  String _messageKey(Map<String, dynamic> message) {
    final id = message['client_message_id'] ??
        message['message_id'] ??
        message['id'];

    if (id != null) return id.toString();

    return '${message['sender_id']}_'
        '${message['receiver_id']}_'
        '${message['message']}_'
        '${message['created_at']}';
  }

  List<Map<String, dynamic>> _mergeMessages(
      Iterable<dynamic> first,
      Iterable<dynamic> second,
      ) {
    final unique = <String, Map<String, dynamic>>{};

    for (final item in [...first, ...second]) {
      if (item is! Map) continue;

      final message = Map<String, dynamic>.from(item);
      unique[_messageKey(message)] = message;
    }

    final result = unique.values.toList();

    result.sort((a, b) {
      final dateA = DateTime.tryParse(
        (a['created_at'] ?? '').toString(),
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final dateB = DateTime.tryParse(
        (b['created_at'] ?? '').toString(),
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return dateA.compareTo(dateB);
    });

    return result;
  }

  Future<void> _loadLocalHistory() async {
    try {
      final localMessages =
      await _pendingStore.getConversationMessages(
        widget.userId,
        widget.receiverId,
      );

      if (!mounted) return;

      setState(() {
        messages = _mergeMessages(messages, localMessages);
      });
    } catch (e) {
      debugPrint('Could not load local conversation: $e');
    }
  }

  Future<void> _handleIncomingMessage(
      Map<String, dynamic> data,
      ) async {
    final senderId = int.tryParse(data['sender_id'].toString());
    final receiverId = int.tryParse(data['receiver_id'].toString());

    if (senderId != widget.receiverId ||
        receiverId != widget.userId) {
      return;
    }

    // Save incoming messages in this conversation's local history.
    await _pendingStore.saveConversationMessage(
      widget.userId,
      widget.receiverId,
      data,
    );

    if (!mounted) return;

    setState(() {
      messages = _mergeMessages(messages, [data]);
    });

    debugPrint('Incoming message saved and displayed.');
  }

  Future<void> sendMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    final messageId =
        '${widget.userId}_${DateTime.now().microsecondsSinceEpoch}';

    final data = <String, dynamic>{
      'sender_id': widget.userId,
      'receiver_id': widget.receiverId,
      'message': message,
      'message_id': messageId,
      'client_message_id': messageId,
      'created_at': DateTime.now().toIso8601String(),
      'type': 'chat',
    };

    messageController.clear();

    // Save locally before attempting delivery.
    await _pendingStore.saveConversationMessage(
      widget.userId,
      widget.receiverId,
      data,
    );

    await _pendingStore.savePendingMessage(
      widget.userId,
      data,
    );

    if (!mounted) return;

    setState(() {
      messages = _mergeMessages(messages, [data]);
    });

    // Try LAN first.
    final peer =
    widget.lanDiscoveryService.peers[widget.receiverId];

    bool sentOverLan = false;

    if (peer != null) {
      try {
        await widget.lanTcpService.sendMessage(
          host: peer.host,
          port: peer.port,
          message: data,
        );

        sentOverLan = true;
        debugPrint('LAN message sent to user ${widget.receiverId}');
      } catch (e) {
        debugPrint('LAN send failed: $e');
      }
    }

    // Fall back to Socket.IO if LAN sending fails.
    if (!sentOverLan && socket.connected) {
      socket.emit('send_message', data);
      debugPrint('Message sent through Socket.IO');
    } else if (!sentOverLan) {
      debugPrint('No available live delivery route.');
    }

    // Attempt to save queued messages to PostgreSQL.
    await _syncPendingMessages();
  }
  Future<void> fetchMessage() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.1.33:3000/messages/'
              '${widget.userId}/${widget.receiverId}',
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Failed to load cloud messages.');
        return;
      }

      final data = jsonDecode(response.body);

      final cloudMessages =
      List<dynamic>.from(data['messages'] ?? []);

      // Merge cloud history with messages already loaded locally.
      if (!mounted) return;

      final merged = _mergeMessages(messages, cloudMessages);

      setState(() {
        messages = merged;
      });

      // Cache only the latest 20 messages from the merged history.
      final latestMessages = merged.length > 20
          ? merged.sublist(merged.length - 20)
          : merged;

      for (final item in latestMessages) {
        final senderId = int.tryParse(
          item['sender_id'].toString(),
        );

        final receiverId = int.tryParse(
          item['receiver_id'].toString(),
        );

        if (senderId == null || receiverId == null) continue;

        await _pendingStore.saveConversationMessage(
          widget.userId,
          widget.receiverId,
          item,
        );
      }

      debugPrint('Cloud and local conversation history merged.');
    } catch (e) {
      // Local history remains available if the backend is offline.
      debugPrint('Could not fetch cloud messages: $e');
    }
  }
  //lan
  @override
  void dispose() {
    _lanSubscription?.cancel();
    messageController.dispose();
    socket.dispose();
    super.dispose();
    _syncTimer?.cancel();
    _fileSubscription?.cancel();
    _fileTransferService.dispose();
  }
  //lan
  @override
  void initState() {
    super.initState();

    //file-sharing
    _fileSubscription =
        _fileTransferService.receivedFiles.listen((fileData) {
          if (!mounted) return;

          final senderId = int.tryParse(
            (fileData['sender_id'] ?? '').toString(),
          );

          final receiverId = int.tryParse(
            (fileData['receiver_id'] ?? '').toString(),
          );

          // Only show files intended for this logged-in user
          // and from the person in the open conversation.
          if (senderId != widget.receiverId ||
              receiverId != widget.userId) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File received: ${fileData['file_name']}',
              ),
            ),
          );

          debugPrint('Received file details: $fileData');
        });

    _fileTransferService.start().catchError((error) {
      debugPrint('Could not start LAN file listener: $error');
    });

    // Load local messages first, then fetch cloud history.
    _loadLocalHistory();
    fetchMessage();

    // Retry saving queued messages every 15 seconds.
    _syncPendingMessages();

    _syncTimer = Timer.periodic(
      const Duration(seconds: 15),
          (_) {
        _syncPendingMessages();
      },
    );

    // Receive LAN messages while this conversation is open.
    _lanSubscription =
        widget.lanTcpService.incomingMessages.listen((data) {
          _handleIncomingMessage(data);
        });

    // Connect to the cloud messaging server.
    socket = IO.io(
      'http://192.168.1.33:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('Socket Connected');
      socket.emit('register_user', widget.userId);
    });

    // Receive cloud-delivered messages.
    socket.on('receive_message', (data) {
      if (data is! Map) return;

      _handleIncomingMessage(
        Map<String, dynamic>.from(data),
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                debugPrint('CHAT MESSAGE DATA: ${messages[index]}');
                return ListTile(
                  title: _buildMessageContent(messages[index]["message"]),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach a file or image',
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: sendMessage,
                  child: const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

