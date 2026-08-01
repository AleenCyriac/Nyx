import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>
{
  List<dynamic> messages = [];
  final TextEditingController messageController = TextEditingController();

  Future<void> sendMessage() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "message": messageController.text.trim(),
        }),
      );
      if (messageController.text.trim().isEmpty) {
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        messageController.clear();
        await fetchMessage();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchMessage() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:3000/messages"),
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
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hybrid Chat"),
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
      /*  onPressed: () {
          // We'll use this later to start a new chat
        },
        child: const Icon(Icons.chat),
      ),*/
    );
  }
}

