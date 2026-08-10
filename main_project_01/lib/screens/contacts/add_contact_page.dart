import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat/chat_page.dart';

class AddContactPage extends StatefulWidget {
  final int userId;
  const AddContactPage({super.key, required this.userId});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}
class _AddContactPageState extends State<AddContactPage>
{
  Map<String, dynamic>? foundUser;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController(); /// to message directly
  final TextEditingController saveContactController = TextEditingController(); /// to save contact information

  Future<void> searchContact() async {  ///to search for a contact with phone number
    try {
      final response = await http.get(
        Uri.parse("http://localhost:3000/user/phone/${phoneController.text.trim()}",),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          foundUser = data["user"];
        });
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Number not in database"),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  Future<void> saveContact() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/contact"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "owner_user_id": widget.userId,
          "contact_user_id": foundUser!["id"],
          "display_name": foundUser!["name"],
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  @override
  void initState() {
    super.initState();
    searchContact();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Contact"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                hintText: "Enter phone number",
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: searchContact,
              child: const Text("Search"),
            ),
            if (foundUser != null)
              Card(
                child: ListTile(
                  title: Text(foundUser!["name"]),
                  subtitle: Text(foundUser!["phone_no"]),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      userId: widget.userId,
                      receiverId: foundUser!["id"],
                      receiverName: foundUser!["name"],
                    ),
                  ),
                );
              },
              child: const Text("Message"),
            ),
            ElevatedButton( ///to save contact to be seen on homepage
              onPressed: saveContact,
              child: const Text("Save Contact"),
            )
          ],
        ),
      ),
    );
  }
}
