import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

import 'package:main_project_01/services/lan_discovery_service.dart';
import 'package:main_project_01/services/lan_tcp_service.dart';
import 'package:main_project_01/services/pending_message_store.dart';

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
  //lan
  StreamSubscription<Map<String, dynamic>>? _lanSubscription;

  final PendingMessageStore _pendingStore = PendingMessageStore();

  Timer? _syncTimer;
  bool _isSyncing = false;


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
  }
  //lan
  @override
  void initState() {
    super.initState();

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
                return ListTile(
                  title: Text(messages[index]["message"]),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
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

