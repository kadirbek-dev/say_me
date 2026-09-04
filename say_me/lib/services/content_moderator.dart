import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentModerator {
  // Вызов Gemini API для анализа текста
  static Future<bool> isTextSafe(String text) async {
    const apiKey = 'YOUR_GEMINI_API_KEY'; // Подставь свой API ключ
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
Ты — строгое встроенное средство модерации чата в приложении поддержки.
Проанализируй следующий текст на наличие:
1. Мата, нецензурной лексики, вульгарных выражений (на любом языке, включая транслит и маскировку).
2. Оскорблений, угроз, хейтспича, явной агрессии.

Ответь СТРОГО одним словом:
- "SAFE" — если текст допустим.
- "UNSAFE" — если есть мат, оскорбления или деструктив.

Текст для проверки: "$text"
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.0, // Нулевая температура для максимальной точности
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultText = data['candidates']?[0]['content']?['parts']?[0]['text']?.toString().trim() ?? '';
        
        return !resultText.contains('UNSAFE');
      }
      
      // В случае ошибки сети пропускаем текст или логгируем
      return true; 
    } catch (e) {
      return true;
    }
  }
}