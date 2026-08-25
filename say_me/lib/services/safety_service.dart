class SafetyService {
  // Регулярки для поиска соцсетей и мессенджеров
  static final RegExp _socialMediaRegExp = RegExp(
    r'(t\.me|wa\.me|vk\.com|instagram\.com|tg|тг|телеграм|telegram|ватсап|whatsapp|инста|insta|номер|\+?\d{10,12}|@[a-zA-Z0-9_]+)',
    caseSensitive: false,
  );

  // Регулярки для подозрительных фраз и угроз
  static final RegExp _suspiciousPhrasesRegExp = RegExp(
    r'(напиши в|перейдем в|уйдем в|где живешь|сколько тебе лет|скинь фото|угроза|убью|найду тебя)',
    caseSensitive: false,
  );

  /// Проверка текста на подозрительные действия
  static bool containsSuspiciousActivity(String text) {
    final hasSocialMedia = _socialMediaRegExp.hasMatch(text);
    final hasSuspiciousPhrase = _suspiciousPhrasesRegExp.hasMatch(text);

    return hasSocialMedia || hasSuspiciousPhrase;
  }
}