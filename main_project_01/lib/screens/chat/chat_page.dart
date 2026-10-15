import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class ChatPage extends StatefulWidget {
  final int userId;
  final int receiverId;
  final String receiverName;
  const ChatPage({super.key,required this.userId,required this.receiverId,required this.receiverName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage>
{
  late IO.Socket socket;
  List<dynamic> messages = [];
  final TextEditingController messageController = TextEditingController();

  Future<void> sendMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/chat"),
        headers: {
          "Content-Type": "application/json",
        },



        body: jsonEncode({
          "sender_id": widget.userId,
          "receiver_id": widget.receiverId,
          "message": messageController.text.trim(),
        }),
      );

      socket.emit(
        "send_message",
        {
          "sender_id": widget.userId,
          "receiver_id": widget.receiverId,
          "message": messageController.text.trim(),
        },
      );



      if (messageController.text.trim().isEmpty) {
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        //to update sender ui
        setState(() {
          messages.add({
            "sender_id": widget.userId,
            "receiver_id": widget.receiverId,
            "message": message,
          });
        });
        messageController.clear();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchMessage() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:3000/messages/${widget.userId}/${widget.receiverId}",),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data["messages"];
        });
        messageController.clear();
      }else {
        debugPrint("Failed to load messages");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  @override

  void initState() {
    super.initState();
    fetchMessage();
    socket = IO.io(
        "http://localhost:3000",
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .build(),);
    socket.onConnect((_) {
      debugPrint("Socket Connected");
      socket.emit( ///fluter->server
        "register_user",
        widget.userId,
      );
    });
    socket.on( ///server->fluter
      "receive_message",
          (data) {
        debugPrint(
          "Received message: ${data["message"]}",
        );
        setState(() {
          messages.add(data);
        });
      },
    );
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

