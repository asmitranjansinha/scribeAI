import 'dart:convert';
import 'dart:developer';

import 'package:ai_note_taker/constants/strings.dart';
import 'package:http/http.dart' as http;

class SummarizeService {
  // Gemini API call to summarise meeting notes
  Future<String> summarizeMeetingNotes(String notes) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        ),
        headers: {
          'X-goog-api-key': GEMINI_API_KEY,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are a top-notch meeting summarizer. Summarize the below notes with bullet points and crux. Give just the Summary Text, Nothing else like 'Okay, here's a summary of your notes, focusing on the key information:'",
                },
                {"text": notes},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log(data['candidates'][0]['content']['parts'][0]['text'].toString());
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to summarize meeting notes');
      }
    } catch (e) {
      print('Error summarizing meeting notes: $e');
      return 'Error summarizing meeting notes';
    }
  }
}
