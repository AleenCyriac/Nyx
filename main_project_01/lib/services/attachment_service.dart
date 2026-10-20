
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AttachmentService {
  static const String baseUrl = 'http://192.168.1.33:3000';

  Future<Map<String, dynamic>> uploadFile({
    required PlatformFile file,
    required int senderId,
    required int receiverId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attachments'),
    );

    request.fields['sender_id'] = senderId.toString();
    request.fields['receiver_id'] = receiverId.toString();

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes as Uint8List,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw Exception('Cannot read the selected file.');
    }

    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 3),
    );

    final response = await http.Response.fromStream(streamedResponse);
    final result = jsonDecode(response.body);

    if (response.statusCode != 200 || result['success'] != true) {
      throw Exception(
        result['message'] ?? 'File upload failed.',
      );
    }


    final attachment =
    Map<String, dynamic>.from(result['attachment']);

    attachment['file_url'] = Uri.parse(
      '$baseUrl${attachment['file_url']}',
    ).toString();

    return attachment;
  }
}
