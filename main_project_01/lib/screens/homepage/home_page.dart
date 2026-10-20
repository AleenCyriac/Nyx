import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_page.dart';
import '../contacts/add_contact_page.dart';
import 'package:main_project_01/services/lan_discovery_service.dart';
import 'package:main_project_01/services/lan_tcp_service.dart';
import 'dart:async';
import 'package:main_project_01/services/pending_message_store.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key,required this.userId,});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>
{
List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];

  //lan
final LanDiscoveryService _lanDiscoveryService =
LanDiscoveryService();


final LanTcpService _lanTcpService = LanTcpService();

final PendingMessageStore _messageStore = PendingMessageStore();
StreamSubscription<Map<String, dynamic>>? _incomingSubscription;
//lan
Future<void> fetchContacts() async {
  try {
    final response = await http.get(
      Uri.parse(
        "http://192.168.1.33:3000/contacts/${widget.userId}",
      ),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      debugPrint(data.toString());

      setState(() {
        contacts.clear();

        for (var contact in data["contacts"]) {
          contacts.add({
            "userId": contact["contact_user_id"],
            "name": contact["display_name"],
            "phone": contact["phone_no"],
          });
        }

        filteredContacts = List.from(contacts);
      });
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
  final TextEditingController searchController = TextEditingController();

  void searchContacts(String value) {
    setState(() {
      filteredContacts = contacts.where((contact) {
        return contact["name"]
            .toLowerCase()
            .contains(value.toLowerCase()) ||
            contact["phone"].contains(value);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchContacts();

    _incomingSubscription =
        _lanTcpService.incomingMessages.listen((data) async {
          final senderId = int.tryParse(data['sender_id'].toString());
          final receiverId = int.tryParse(data['receiver_id'].toString());

          if (senderId == null ||
              receiverId != widget.userId ||
              data['type'] != 'chat') {
            return;
          }

          await _messageStore.saveConversationMessage(
            widget.userId,
            senderId,
            data,
          );

          debugPrint('Incoming LAN message saved locally.');
        });

    _startLanServices();
  }

  Future<void> _startLanServices() async {
    try {
      await _lanTcpService.start(
        onMessage: (message) {
          debugPrint('TCP MESSAGE RECEIVED: $message');
        },
      );

      await _lanDiscoveryService.start(userId: widget.userId);
    } catch (e) {
      debugPrint('Could not start LAN services: $e');
      // Cloud messaging should remain available.
    }
  }

  //lan

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    searchController.dispose();
    _lanDiscoveryService.stop();
    _lanTcpService.stop();
    super.dispose();
  }

  //lan
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search users or numbers",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: searchContacts,
            ),
          ),



          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {

                final contact =
                filteredContacts[index];

                return ListTile(
                  title: Text(contact["name"]),
                  subtitle: Text(contact["phone"]),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          userId: widget.userId,
                          receiverId: contact["userId"],
                          receiverName: contact["name"],
                          lanDiscoveryService: _lanDiscoveryService,
                          lanTcpService: _lanTcpService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContactPage(userId: widget.userId,
                lanDiscoveryService: _lanDiscoveryService,
                lanTcpService: _lanTcpService,),
            ),
          );
          if (result == true) {
            await fetchContacts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );

  }
}

