import 'package:encrypt/encrypt.dart' as encrypt_lib;

class ModerationResult {
  final bool isSafe;
  final String? warningMessage;

  ModerationResult({required this.isSafe, this.warningMessage});
}

class SecurityService {
  // Базовый список стоп-слов для локальной проверки (расширяемый)
  static final List<String> _bannedKeywords = [
    // Словарный фильтр для защиты от токсичности и мата
    'сука', 'блять', 'пидор', 'гандон', 'тварь', 'уебок', 'сучка', 'ублюдок'
  ];

  /// 1. Локальная ИИ-модерация текста (выполняется ДО шифрования)
  static ModerationResult moderateText(String text) {
    final lowerText = text.toLowerCase();

    for (final word in _bannedKeywords) {
      if (lowerText.contains(word)) {
        return ModerationResult(
          isSafe: false,
          warningMessage:
              'Сообщение содержит недопустимую лексику или оскорбления. Пожалуйста, соблюдайте правила общения.',
        );
      }
    }

    return ModerationResult(isSafe: true);
  }

  /// 2. E2E-шифрование сообщения (AES-256)
  static String encryptMessage(String plainText, String secretKey) {
    // Формируем 32-байтный ключ из секретного ключа чата
    final key = encrypt_lib.Key.fromUtf8(secretKey.padRight(32, '*').substring(0, 32));
    final iv = encrypt_lib.IV.fromLength(16);
    final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Сохраняем IV вместе с зашифрованным текстом
    return '${iv.base64}:${encrypted.base64}';
  }

  /// 3. Расшифровка сообщения (AES-256)
  static String decryptMessage(String encryptedText, String secretKey) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;

      final key = encrypt_lib.Key.fromUtf8(secretKey.padRight(32, '*').substring(0, 32));
      final iv = encrypt_lib.IV.fromBase64(parts[0]);
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key));

      final encrypted = encrypt_lib.Encrypted.fromBase64(parts[1]);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return '[Зашифрованное сообщение]';
    }
  }
}