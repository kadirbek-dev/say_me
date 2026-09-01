import 'package:flutter/material.dart';
import 'document_verification_screen.dart';

// ---------------- СЕРВИСЫ БЕЗОПАСНОСТИ ----------------
class SafetyService {
  static bool containsSuspiciousActivity(String text) {
    final lower = text.toLowerCase();
    final phoneRegExp = RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final socialRegExp = RegExp(r'(t\.me|wa\.me|inst|vk|telegram|whatsapp|тг|ватсап)');

    return phoneRegExp.hasMatch(text) || socialRegExp.hasMatch(lower);
  }
}

class ModerationResult {
  final bool isSafe;
  final String warningMessage;

  ModerationResult({required this.isSafe, required this.warningMessage});
}

class SecurityService {
  static ModerationResult moderateText(String text) {
    final lower = text.toLowerCase();
    final badWords = ['спам', 'ругательство']; 

    for (var word in badWords) {
      if (lower.contains(word)) {
        return ModerationResult(
          isSafe: false,
          warningMessage: 'Обнаружено недопустимое выражение.',
        );
      }
    }
    return ModerationResult(isSafe: true, warningMessage: '');
  }

  static String encryptMessage(String text, String key) => text;
  static String decryptMessage(String encryptedText, String key) => encryptedText;
}

// ---------------- ЭКРАН ЧАТА ----------------
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = true;
  int _warningCount = 0;
  final String _chatId = 'say_me_e2e_secret_key';

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Здравствуйте! Чем я могу вам помочь?',
      'isUser': false,
    },
    {
      'text': 'Мне тревожно...',
      'isUser': true,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (SafetyService.containsSuspiciousActivity(text)) {
      _showSafetyWarningDialog();
      return;
    }

    final moderation = SecurityService.moderateText(text);

    if (!moderation.isSafe) {
      setState(() {
        _warningCount++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${moderation.warningMessage} (Предупреждение $_warningCount/3)',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (_warningCount >= 3) {
        _showBanDialog();
      }
      return;
    }

    final encryptedText = SecurityService.encryptMessage(text, _chatId);
    final decryptedText = SecurityService.decryptMessage(encryptedText, _chatId);

    setState(() {
      _messages.add({
        'text': decryptedText,
        'isUser': true,
        'isAnonymous': _isAnonymous,
      });
      _controller.clear();
    });
  }

  void _showSafetyWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ограничение безопасности'),
        content: const Text(
          'Обнаружена попытка передачи сторонних контактов (Telegram/WhatsApp) или подозрительные действия. '
          'Для защиты пользователей требуется подтверждение возраста (18+) по документу.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentVerificationScreen(userAge: 18),
                ),
              );
            },
            child: const Text('Пройти проверку'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Аккаунт заблокирован'),
        content: const Text(
          'Вы получили 3 предупреждения за использование недопустимой лексики. Отправка сообщений временно ограничена.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Айгерим К.',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 12, color: Color(0xFF4CAF50)),
                SizedBox(width: 4),
                Text(
                  'Детский психолог • E2E Защищено',
                  style: TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFF3C4C8) : const Color(0xFFCBE3D5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg['text'],
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Как отправить?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isAnonymous = true),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: _isAnonymous,
                                    activeColor: theme.colorScheme.primary,
                                    onChanged: (val) => setState(() => _isAnonymous = val!),
                                  ),
                                  const Text('Анонимно', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => setState(() => _isAnonymous = false),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: _isAnonymous,
                                    activeColor: theme.colorScheme.primary,
                                    onChanged: (val) => setState(() => _isAnonymous = val!),
                                  ),
                                  const Text('Открыто', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Написать сообщение...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}