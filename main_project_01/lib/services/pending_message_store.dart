import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingMessageStore {
  static const int maxConversationMessages = 20;

  // Existing pending-message queue.
  String _storageKey(int userId) => 'pending_messages_$userId';

  // Separate storage key for each conversation on each device.
  String _conversationKey(int userId, int otherUserId) =>
      'conversation_${userId}_$otherUserId';

  // Get a consistent ID for duplicate checking.
  String? _messageId(Map<String, dynamic> message) {
    final id = message['client_message_id'] ??
        message['message_id'] ??
        message['id'];

    return id?.toString();
  }

  // Save a message in this conversation's local history.
  Future<void> saveConversationMessage(
      int userId,
      int otherUserId,
      Map<String, dynamic> message,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _conversationKey(userId, otherUserId);

    final stored = prefs.getStringList(key) ?? [];

    final history = stored.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item) as Map);
    }).toList();

    final newMessage = Map<String, dynamic>.from(message);

    // Give messages a timestamp if they don't already have one.
    newMessage['created_at'] ??= DateTime.now().toIso8601String();

    final newId = _messageId(newMessage);

    // Don't store the same message twice.
    final alreadyExists = newId != null &&
        history.any((item) => _messageId(item) == newId);

    if (alreadyExists) return;

    history.add(newMessage);

    // Keep messages in chronological order.
    history.sort((a, b) {
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

    // Retain only the latest 20 messages.
    while (history.length > maxConversationMessages) {
      history.removeAt(0);
    }

    await prefs.setStringList(
      key,
      history.map((item) => jsonEncode(item)).toList(),
    );
  }

  // Load locally saved messages for a conversation.
  Future<List<Map<String, dynamic>>> getConversationMessages(
      int userId,
      int otherUserId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getStringList(
      _conversationKey(userId, otherUserId),
    ) ??
        [];

    return stored.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item) as Map);
    }).toList();
  }

  // Existing received-message storage, kept for compatibility.
  Future<void> saveReceivedMessage(
      int userId,
      Map<String, dynamic> message,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'received_messages_$userId';
    final stored = prefs.getStringList(key) ?? [];

    final messageId = _messageId(message);

    final alreadyExists = messageId != null && stored.any((item) {
      final decoded =
      Map<String, dynamic>.from(jsonDecode(item) as Map);
      return _messageId(decoded) == messageId;
    });

    if (alreadyExists) return;

    stored.add(jsonEncode(message));
    await prefs.setStringList(key, stored);
  }

  Future<List<Map<String, dynamic>>> getReceivedMessages(
      int userId,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList('received_messages_$userId') ?? [];

    return stored.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item) as Map);
    }).toList();
  }

  // Existing outgoing pending-message queue.
  Future<List<Map<String, dynamic>>> getPendingMessages(
      int userId,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey(userId)) ?? [];

    return stored.map((item) {
      return Map<String, dynamic>.from(jsonDecode(item) as Map);
    }).toList();
  }

  Future<void> savePendingMessage(
      int userId,
      Map<String, dynamic> message,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingMessages(userId);

    final messageId = message['client_message_id'];

    if (messageId != null &&
        pending.any(
              (item) => item['client_message_id'] == messageId,
        )) {
      return;
    }

    pending.add(Map<String, dynamic>.from(message));

    await prefs.setStringList(
      _storageKey(userId),
      pending.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<void> removePendingMessage(
      int userId,
      String messageId,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await getPendingMessages(userId);

    pending.removeWhere(
          (item) => item['client_message_id'] == messageId,
    );

    await prefs.setStringList(
      _storageKey(userId),
      pending.map((item) => jsonEncode(item)).toList(),
    );
  }
}