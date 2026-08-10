import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_page.dart';
import '../contacts/add_contact_page.dart';

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
Future<void> fetchContacts() async {
  try {
    final response = await http.get(
      Uri.parse(
        "http://localhost:3000/contacts/${widget.userId}",
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
  }
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
              builder: (context) => AddContactPage(userId: widget.userId),
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

