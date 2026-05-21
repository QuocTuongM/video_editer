import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kết quả nội dung AI trả về từ Gemini.
class GeminiContentResult {
  const GeminiContentResult({
    required this.titles,
    required this.description,
    required this.hashtags,
  });

  final List<String> titles;
  final String description;
  final List<String> hashtags;

  String get mainTitle {
    if (titles.isEmpty) {
      return '';
    }

    return titles.first;
  }
}

/// Service gọi Gemini API trực tiếp từ Flutter.
///
/// Lưu ý:
/// - Cách này phù hợp demo/free.
/// - API key nằm phía client nên không phù hợp production.
class GeminiAiService {
  GeminiAiService({
    this.model = 'gemini-2.5-flash',
  });

  final String model;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<GeminiContentResult> generateVideoContent({
    required String transcript,
    String? videoTitle,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Thiếu GEMINI_API_KEY. Hãy chạy app bằng --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }

    final cleanTranscript = transcript.trim();

    if (cleanTranscript.isEmpty) {
      throw Exception('Transcript/mô tả video đang rỗng.');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final prompt = _buildPrompt(
      transcript: cleanTranscript,
      videoTitle: videoTitle,
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
          'response_mime_type': 'application/json',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemini API lỗi ${response.statusCode}: ${response.body}',
      );
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractText(root);

    if (text.trim().isEmpty) {
      throw Exception('Gemini không trả về nội dung hợp lệ.');
    }

    final parsed = _parseJsonText(text);

    final titles = _readStringList(parsed['titles']);
    final description = (parsed['description'] ?? '').toString();
    final hashtags = _readStringList(parsed['hashtags']);

    return GeminiContentResult(
      titles: titles,
      description: description,
      hashtags: hashtags,
    );
  }

  String _buildPrompt({
    required String transcript,
    String? videoTitle,
  }) {
    return '''
Bạn là trợ lý AI cho app chỉnh sửa video.

Dựa trên transcript hoặc mô tả video bên dưới, hãy tạo nội dung đăng tải bằng tiếng Việt.

Yêu cầu:
- Tạo 3 tiêu đề ngắn, dễ hiểu, hấp dẫn.
- Tạo 1 mô tả video dài 2 đến 4 câu.
- Tạo 8 hashtag phù hợp, mỗi hashtag bắt đầu bằng dấu #.
- Chỉ trả về JSON hợp lệ.
- Không giải thích thêm bên ngoài JSON.

Format JSON bắt buộc:
{
  "titles": ["", "", ""],
  "description": "",
  "hashtags": ["", "", "", "", "", "", "", ""]
}

Tên video hiện tại:
${videoTitle ?? 'Không có'}

Transcript hoặc mô tả video:
$transcript
''';
  }

  String _extractText(Map<String, dynamic> root) {
    final candidates = root['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      return '';
    }

    final firstCandidate = candidates.first;

    if (firstCandidate is! Map<String, dynamic>) {
      return '';
    }

    final content = firstCandidate['content'];

    if (content is! Map<String, dynamic>) {
      return '';
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      return '';
    }

    final firstPart = parts.first;

    if (firstPart is! Map<String, dynamic>) {
      return '';
    }

    return (firstPart['text'] ?? '').toString();
  }

  Map<String, dynamic> _parseJsonText(String value) {
    final cleaned = value
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Gemini trả về JSON không đúng dạng object.');
    }

    return decoded;
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}