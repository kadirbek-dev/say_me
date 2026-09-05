import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(
                'ОШИБКА ИНТЕРФЕЙСА:\n\n${details.exception}\n\n${details.stack}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    };

    const firebaseOptions = FirebaseOptions(
      apiKey: "AIzaSyAb3xvaU9119y6_9gaYe0qb7V5Cqjv_0L8",
      authDomain: "sayme-2d93e.firebaseapp.com",
      projectId: "sayme-2d93e",
      storageBucket: "sayme-2d93e.firebasestorage.app",
      messagingSenderId: "302686958026",
      appId: "1:302686958026:web:ed73452e209a7eabc61f33",
      measurementId: "G-BSWYNSL3DQ",
    );

    await Firebase.initializeApp(
      options: firebaseOptions,
    );

    runApp(const SayMeApp());
  }, (error, stackTrace) {
    debugPrint('КРИТИЧЕСКАЯ ОШИБКА ЗАПУСКА: $error');
    debugPrint(stackTrace.toString());
  });
}

// ---------------- ИИ МОДЕРАТОР, ПЕРЕВОДЧИК И ЧАТ-БОТ ----------------
class ContentModerator {
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';

  static Future<bool> isTextSafe(String text) async {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY' || _geminiApiKey.isEmpty) {
      return true;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/interactions?key=$_geminiApiKey',
    );

    final prompt = '''
Ты — строгое средство модерации в приложении психологической поддержки.
Проанализируй следующий текст на предмет:
1. Мата, нецензурной лексики, завуалированных ругательств (на любых языках).
2. Оскорблений, угроз, хейтспича, проявления явной агрессии.

Ответь СТРОГО одним словом:
- "SAFE" — если текст допустим.
- "UNSAFE" — если текст содержит мат или оскорбления.

Текст: "$text"
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/gemini-2.5-flash',
          'input': prompt,
          'generation_config': {
            'temperature': 0.0,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultText = data['outputs']?[0]['text']?.toString().trim() ??
            data['candidates']?[0]['content']?['parts']?[0]['text']?.toString().trim() ?? '';
        return !resultText.contains('UNSAFE');
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  static Future<String> getAIChatResponse(String userMessage) async {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY' || _geminiApiKey.isEmpty) {
      return "ИИ-ассистент временно недоступен. Укажите API ключ в настройках.";
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/interactions?key=$_geminiApiKey',
    );

    final prompt = '''
Ты — добрый, эмпатичный и профессиональный ИИ-ассистент в приложении психологической поддержки "Say me".
Твоя задача — выслушать пользователя, поддержать его и дать дельный, мягкий совет.

Сообщение пользователя: "$userMessage"
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/gemini-2.5-flash',
          'input': prompt,
          'generation_config': {
            'temperature': 0.7,
            'max_output_tokens': 65536,
            'top_p': 0.95,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['outputs']?[0]['text']?.toString().trim() ??
            data['candidates']?[0]['content']?['parts']?[0]['text']?.toString().trim() ??
            "Извините, не удалось сформировать ответ.";
      }
      return "Ошибка связи с сервером ИИ.";
    } catch (e) {
      return "Ошибка сети при обращении к ИИ.";
    }
  }
}

class TranslationService {
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';

  static Future<String> translateText(String text, String targetLanguage) async {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY' || _geminiApiKey.isEmpty) {
      return text;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/interactions?key=$_geminiApiKey',
    );

    final prompt = '''
Ты — профессиональный синхронный переводчик приложения психологической поддержки.
Переведи следующий текст на язык: "$targetLanguage".
Сохраняй эмпатичный tone-of-voice и смысловую точность оригинала.
Выдавай ИСКЛЮЧИТЕЛЬНО итоговый перевод без пояснений и кавычек.

Текст: "$text"
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'models/gemini-2.5-flash',
          'input': prompt,
          'generation_config': {
            'temperature': 0.2,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['outputs']?[0]['text']?.toString().trim() ??
            data['candidates']?[0]['content']?['parts']?[0]['text']?.toString().trim() ?? text;
        return translated;
      }
      return text;
    } catch (e) {
      return text;
    }
  }
}

// ---------------- МОДЕЛЬ ПОЛЬЗОВАТЕЛЯ ----------------
enum UserRole { patient, doctor }
enum AgeCategory { kids, teens, adults }
enum UserStatus { active, underReview, banned }

class UserModel {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String gender;
  final int age;
  final AgeCategory ageCategory;
  final bool isIdentityVerified;
  final String avatarUrl;
  final UserStatus status;
  final int warningsCount;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.gender,
    required this.age,
    required this.ageCategory,
    this.isIdentityVerified = false,
    this.avatarUrl = '',
    this.status = UserStatus.active,
    this.warningsCount = 0,
  });

  static AgeCategory calculateAgeCategory(int age) {
    if (age >= 6 && age <= 13) return AgeCategory.kids;
    if (age >= 14 && age <= 17) return AgeCategory.teens;
    return AgeCategory.adults;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final ageVal = map['age'] ?? 18;
    
    UserStatus parseStatus(String? statusStr) {
      if (statusStr == 'under_review') return UserStatus.underReview;
      if (statusStr == 'banned') return UserStatus.banned;
      return UserStatus.active;
    }

    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      username: map['username'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'doctor' ? UserRole.doctor : UserRole.patient,
      gender: map['gender'] ?? 'male',
      age: ageVal,
      ageCategory: calculateAgeCategory(ageVal),
      isIdentityVerified: map['is_identity_verified'] ?? false,
      avatarUrl: map['avatar_url'] ?? '',
      status: parseStatus(map['status']),
      warningsCount: map['warnings_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    String statusToString(UserStatus st) {
      switch (st) {
        case UserStatus.underReview:
          return 'under_review';
        case UserStatus.banned:
          return 'banned';
        case UserStatus.active:
        default:
          return 'active';
      }
    }

    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role == UserRole.doctor ? 'doctor' : 'patient',
      'gender': gender,
      'age': age,
      'is_identity_verified': isIdentityVerified,
      'avatar_url': avatarUrl,
      'status': statusToString(status),
      'warnings_count': warningsCount,
    };
  }
}

// ---------------- ОСНОВНОЕ ПРИЛОЖЕНИЕ ----------------
class SayMeApp extends StatefulWidget {
  const SayMeApp({super.key});

  @override
  State<SayMeApp> createState() => _SayMeAppState();
}

class _SayMeAppState extends State<SayMeApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Say me',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8F6),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5C4643),
          surface: Colors.white,
          onSurface: Color(0xFF2D2D2D),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2C2C2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF3C4C8),
          surface: Color(0xFF2C2C2C),
          onSurface: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: AuthWrapper(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// ---------------- СВЯЗКА С FIREBASE AUTH И ПРОВЕРКОЙ СТАТУСА ----------------
class AuthWrapper extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const AuthWrapper({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null || !firebaseUser.emailVerified) {
          return const AuthScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            UserModel userModel;
            if (userSnap.hasData && userSnap.data!.exists) {
              userModel = UserModel.fromMap(
                userSnap.data!.data() as Map<String, dynamic>,
                firebaseUser.uid,
              );
            } else {
              userModel = UserModel(
                id: firebaseUser.uid,
                username: firebaseUser.displayName ?? 'Пользователь',
                email: firebaseUser.email ?? '',
                role: UserRole.patient,
                gender: 'male',
                age: 18,
                ageCategory: AgeCategory.adults,
                isIdentityVerified: false,
                status: UserStatus.active,
              );
            }

            if (userModel.status == UserStatus.underReview) {
              return UnderReviewScreen(userId: userModel.id);
            }

            if (userModel.status == UserStatus.banned) {
              return const BannedScreen();
            }

            if (!userModel.isIdentityVerified) {
              return VerificationScreen(currentUser: userModel);
            }

            return MainNavigationScreen(
              currentUser: userModel,
              onLogout: () => FirebaseAuth.instance.signOut(),
              onToggleTheme: onToggleTheme,
              isDarkMode: isDarkMode,
            );
          },
        );
      },
    );
  }
}

// ---------------- ЭКРАН ЗАМОРОЗКИ / ПРОВЕРКИ ----------------
class UnderReviewScreen extends StatefulWidget {
  final String userId;

  const UnderReviewScreen({super.key, required this.userId});

  @override
  State<UnderReviewScreen> createState() => _UnderReviewScreenState();
}

class _UnderReviewScreenState extends State<UnderReviewScreen> {
  bool _isProcessing = false;

  Future<void> _requestRecheck() async {
    setState(() => _isProcessing = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'doc_submitted': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запрос отправлен модераторам. Ожидайте решения.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Аккаунт временно заморожен',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ваш аккаунт отправлен на проверку модераторам из-за нарушений правил общения или поступивших жалоб.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isProcessing)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _requestRecheck,
                    icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
                    label: const Text(
                      'Запросить повторную проверку',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Выйти из аккаунта'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ЭКРАН БАНА ----------------
class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Аккаунт заблокирован',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Доступ к платформе ограничен за систематическое нарушение правил пользовательского соглашения.',
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Выйти из аккаунта'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ЭКРАН ВЕРИФИКАЦИИ ----------------
class VerificationScreen extends StatefulWidget {
  final UserModel currentUser;

  const VerificationScreen({super.key, required this.currentUser});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isProcessing = false;

  Future<void> _startVerification() async {
    setState(() => _isProcessing = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.id)
        .update({'is_identity_verified': true});

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Привет, ${widget.currentUser.username}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Подтверждение профиля',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Для безопасности пользователей доступ к чатам и публикациям открывается после быстрой проверки.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Активируем профиль...'),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _startVerification,
                    child: Text(
                      'Подтвердить',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Выйти из аккаунта'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ЭКРАН ВХОДА И РЕГИСТРАЦИИ ----------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = false;
  bool isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _ageController = TextEditingController(text: '18');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 18;

    if (email.isEmpty || pass.isEmpty || (isSignUp && name.isEmpty)) {
      _showError('Заполните все поля');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Введите корректный E-mail (например, user@gmail.com)');
      return;
    }

    if (pass.length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        UserCredential res = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);

        await res.user!.sendEmailVerification();

        final newUser = UserModel(
          id: res.user!.uid,
          username: name,
          email: email,
          role: UserRole.patient,
          gender: 'male',
          age: age,
          ageCategory: UserModel.calculateAgeCategory(age),
          isIdentityVerified: false,
          status: UserStatus.active,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(res.user!.uid)
            .set(newUser.toMap());

        await FirebaseAuth.instance.signOut();

        _showInfo('Письмо отправлено на $email. Подтвердите почту перед входом!');
      } else {
        UserCredential res = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);

        if (!res.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _showError('Почта не подтверждена! Перейдите по ссылке в письме.');
        }
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _showError('Пользователь с таким E-mail уже зарегистрирован');
          break;
        case 'invalid-email':
          _showError('Некорректный формат E-mail адреса');
          break;
        case 'weak-password':
          _showError('Слишком простой пароль');
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          _showError('Неверный E-mail или пароль');
          break;
        default:
          _showError(e.message ?? 'Ошибка авторизации');
      }
    } catch (e) {
      _showError('Произошла ошибка при подключении к сети');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Say me',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSignUp ? 'Создание учетной записи' : 'Добро пожаловать обратно',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                if (isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Ваше имя или псевдоним',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Возраст',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isSignUp ? 'Зарегистрироваться' : 'Войти',
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(
                    isSignUp
                        ? 'Уже есть аккаунт? Войти'
                        : 'Ещё нет аккаунта? Зарегистрироваться',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- НАВИГАЦИЯ ПРИЛОЖЕНИЯ ----------------
class MainNavigationScreen extends StatefulWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainNavigationScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final List<Widget> screens = [
      HomeScreen(currentUser: widget.currentUser),
      SearchScreen(onOpenChat: (u) => _openDirectChat(context, u)),
      ChatListScreen(
        currentUser: widget.currentUser,
        onOpenChat: (u) => _openDirectChat(context, u),
      ),
      AIChatBotScreen(currentUser: widget.currentUser),
      ProfileScreen(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            bottom: bottomInset > 0 ? 4 : 10,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white10
                    : const Color(0xFFE8E9E5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(Icons.home_rounded, 0),
              _buildNavItem(Icons.search_rounded, 1),
              GestureDetector(
                onTap: () => _createNewPost(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3C4C8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF5C4643), size: 24),
                ),
              ),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 2),
              _buildNavItem(Icons.smart_toy_outlined, 3),
              _buildNavItem(Icons.person_outline_rounded, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          size: 26,
        ),
      ),
    );
  }

  void _openDirectChat(BuildContext context, UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DirectChatScreen(
          currentUser: widget.currentUser,
          targetUser: targetUser,
        ),
      ),
    );
  }

  void _createNewPost(BuildContext context) {
    final theme = Theme.of(context);
    final textController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isAnon = true;
    bool isPublishing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Создать публикацию',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Поделитесь тем, что у вас на душе...',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  hintText: 'Ссылка на изображение (опционально)...',
                  prefixIcon: const Icon(Icons.image_outlined),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isAnon,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => setModalState(() => isAnon = val ?? true),
                  ),
                  const Text('Опубликовать анонимно'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isPublishing
                      ? null
                      : () async {
                          final text = textController.text.trim();
                          final imageUrl = imageUrlController.text.trim();
                          if (text.isEmpty && imageUrl.isEmpty) return;

                          setModalState(() => isPublishing = true);

                          final isSafe = await ContentModerator.isTextSafe(text);

                          if (!isSafe) {
                            setModalState(() => isPublishing = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Текст содержит недопустимые выражения или оскорбления!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          await FirebaseFirestore.instance.collection('posts').add({
                            'authorName': isAnon ? 'Аноним' : widget.currentUser.username,
                            'authorId': widget.currentUser.id,
                            'text': text,
                            'imageUrl': imageUrl,
                            'isAnonymous': isAnon,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                  child: isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Опубликовать',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- 1. ЛЕНТА ПОСТОВ И КНОПКА СЛУЖБЫ 115 ----------------
class HomeScreen extends StatelessWidget {
  final UserModel currentUser;

  const HomeScreen({super.key, required this.currentUser});

  Future<void> _makeCall115() async {
    final Uri url = Uri.parse('tel:115');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Say me',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none,
                      color: theme.colorScheme.primary),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Баннер вызова службы 115
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Экстренная психологическая помощь',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Горячая линия 115 доступна круглосуточно',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _makeCall115,
                    child: const Text('115', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('Лента пуста. Создайте первую запись!'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final imageUrl = data['imageUrl'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['authorName'] ?? 'Аноним',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if ((data['text'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(data['text'] ?? ''),
                              ],
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const SizedBox(),
                                  ),
                                ),
                              ],
                            ],
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
      ),
    );
  }
}

// ---------------- 2. ПОИСК ДОКТОРОВ ----------------
class SearchScreen extends StatefulWidget {
  final Function(UserModel) onOpenChat;

  const SearchScreen({super.key, required this.onOpenChat});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Поиск врачей',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 20),
                  hintText: 'Поиск по имени...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'doctor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final doctors = docs.map((doc) {
                    return UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).where((p) {
                    return p.username
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (doctors.isEmpty) {
                    return const Center(
                        child: Text('Проверенных врачей пока нет'));
                  }

                  return ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (ctx, i) {
                      final doc = doctors[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              doc.username.isNotEmpty ? doc.username[0] : 'Д',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(doc.username,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Врач • ${doc.age} лет'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () => widget.onOpenChat(doc),
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
      ),
    );
  }
}

// ---------------- 3. СПИСОК ДИАЛОГОВ ----------------
class ChatListScreen extends StatelessWidget {
  final UserModel currentUser;
  final Function(UserModel) onOpenChat;

  const ChatListScreen({
    super.key,
    required this.currentUser,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Center(
            child: Text('Диалоги',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final otherUsers = docs
                    .where((d) => d.id != currentUser.id)
                    .map((d) => UserModel.fromMap(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList();

                if (otherUsers.isEmpty) {
                  return const Center(
                      child: Text('Нет доступных пользователей для чата'));
                }

                return ListView.builder(
                  itemCount: otherUsers.length,
                  itemBuilder: (ctx, i) {
                    final u = otherUsers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
                        child: u.avatarUrl.isEmpty ? Text(u.username.isNotEmpty ? u.username[0] : 'U') : null,
                      ),
                      title: Text(u.username),
                      subtitle: Text(
                          u.role == UserRole.doctor ? 'Врач' : 'Пациент'),
                      onTap: () => onOpenChat(u),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 4. ИИ ЧАТ-БОТ ЭКРАН ----------------
class AIChatBotScreen extends StatefulWidget {
  final UserModel currentUser;

  const AIChatBotScreen({super.key, required this.currentUser});

  @override
  State<AIChatBotScreen> createState() => _AIChatBotScreenState();
}

class _AIChatBotScreenState extends State<AIChatBotScreen> {
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Здравствуйте! Я ваш ИИ-помощник. Поделитесь со мной тем, что вас беспокоит, и я постараюсь помочь.'
    }
  ];
  final TextEditingController _msgController = TextEditingController();
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _msgController.clear();

    final aiResponse = await ContentModerator.getAIChatResponse(text);

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': aiResponse});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text('ИИ Помощник',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final isUser = _messages[i]['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _messages[i]['text']!,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Задайте вопрос ИИ...',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 5. ЭЛЕМЕНТ СООБЩЕНИЯ С АНИМАЦИЕЙ ----------------
class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isMe;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.isMe,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0, 0.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _visible ? 1.0 : 0.0,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------- 6. ОКНО ЧАТА С ИИ-МОДЕРАЦИЕЙ И ПЕРЕВОДОМ ----------------
class DirectChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel targetUser;

  const DirectChatScreen({
    super.key,
    required this.currentUser,
    required this.targetUser,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  bool _isSending = false;
  String? _targetLanguage;
  final Map<String, String> _translatedCache = {};

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  String _getChatId() {
    final ids = [widget.currentUser.id, widget.targetUser.id]..sort();
    return ids.join('_');
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final isSafe = await ContentModerator.isTextSafe(text);

    if (!isSafe) {
      final newWarnings = widget.currentUser.warningsCount + 1;

      if (newWarnings >= 3) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.id)
            .update({
          'warnings_count': newWarnings,
          'status': 'under_review',
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.id)
            .update({'warnings_count': newWarnings});
      }

      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newWarnings >= 3
                  ? 'Аккаунт отправлен на проверку за частые нарушения.'
                  : 'Сообщение заблокировано ИИ-модератором! Нарушений: $newWarnings/3',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _msgController.clear();
    final chatId = _getChatId();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUser.id,
      'recipientId': widget.targetUser.id,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) setState(() => _isSending = false);
  }

  void _showTranslationMenu(String docId, String originalText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите язык автоперевода:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Все текущие и новые сообщения в этом чате будут автоматически переводиться на выбранный язык.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇰🇿', style: TextStyle(fontSize: 24)),
              title: const Text('Переводить на Казахский'),
              onTap: () {
                Navigator.pop(ctx);
                _enableAutoTranslation('Казахский');
              },
            ),
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Переводить на Русский'),
              onTap: () {
                Navigator.pop(ctx);
                _enableAutoTranslation('Русский');
              },
            ),
            if (_targetLanguage != null)
              ListTile(
                leading: const Icon(Icons.clear_rounded, color: Colors.redAccent),
                title: const Text('Отключить автоперевод', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _targetLanguage = null;
                    _translatedCache.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _enableAutoTranslation(String lang) {
    setState(() {
      _targetLanguage = lang;
      _translatedCache.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Включён автоперевод переписки на $lang язык!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Пожаловаться на ${widget.targetUser.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Укажите причину:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Причина жалобы...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reporterId': widget.currentUser.id,
                  'reportedUserId': widget.targetUser.id,
                  'reason': reason,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.targetUser.id)
                    .update({'status': 'under_review'});

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Жалоба отправлена.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatId = _getChatId();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.targetUser.username),
            if (_targetLanguage != null)
              Text(
                'Автоперевод: $_targetLanguage',
                style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
              ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
            tooltip: 'Пожаловаться',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final originalText = data['text'] ?? '';
                      final isMe = data['senderId'] == widget.currentUser.id;

                      if (_targetLanguage != null && !_translatedCache.containsKey(doc.id)) {
                        TranslationService.translateText(originalText, _targetLanguage!).then((res) {
                          if (mounted) {
                            setState(() {
                              _translatedCache[doc.id] = res;
                            });
                          }
                        });
                      }

                      final displayText = (_targetLanguage != null && _translatedCache.containsKey(doc.id))
                          ? _translatedCache[doc.id]!
                          : originalText;

                      return AnimatedMessageBubble(
                        key: ValueKey(doc.id),
                        isMe: isMe,
                        child: GestureDetector(
                          onLongPress: () => _showTranslationMenu(doc.id, originalText),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primary
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                if (_targetLanguage != null && _translatedCache.containsKey(doc.id))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '• переведено',
                                      style: TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  _isSending
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.send, color: theme.colorScheme.primary),
                          onPressed: _send,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 7. ПРОФИЛЬ С ВОЗМОЖНОСТЬЮ РЕДАКТИРОВАНИЯ ----------------
class ProfileScreen extends StatelessWidget {
  final UserModel currentUser;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: currentUser.username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Имя или псевдоним'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(currentUser.id).update({'username': newName});
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _editAvatar(BuildContext context) {
    final controller = TextEditingController(text: currentUser.avatarUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить ссылку на аватар'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'URL картинки'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final newAvatar = controller.text.trim();
              await FirebaseFirestore.instance.collection('users').doc(currentUser.id).update({'avatar_url': newAvatar});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showGeminiThanksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('Gemini AI'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Особая благодарность архитектуре Gemini AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 10),
            Text(
              'Все алгоритмы интеллектуальной модерации текста, фильтрация нецензурной лексики, защита психологического здоровья пользователей и мгновенный автоперевод сообщений между языками выстроены на базе технологий Google Gemini.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text('Профиль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _editAvatar(context),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: currentUser.avatarUrl.isNotEmpty ? NetworkImage(currentUser.avatarUrl) : null,
                  child: currentUser.avatarUrl.isEmpty
                      ? Text(
                          currentUser.username.isNotEmpty ? currentUser.username[0] : 'U',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentUser.username,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editName(context),
                  ),
                ],
              ),
              Text(
                currentUser.email,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingRow(context, 'Роль аккаунта',
                  currentUser.role == UserRole.doctor ? 'Врач' : 'Пациент'),
              _buildSettingRow(context, 'Возраст', '${currentUser.age} лет'),
              _buildSettingRow(
                  context,
                  'Верификация',
                  currentUser.isIdentityVerified
                      ? 'Подтверждён'
                      : 'Не подтверждён'),
              InkWell(
                onTap: onToggleTheme,
                borderRadius: BorderRadius.circular(12),
                child: _buildSettingRow(
                  context,
                  'Тема',
                  isDarkMode ? 'Тёмная' : 'Светлая',
                  trailingIcon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              InkWell(
                onTap: () => _showGeminiThanksDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Особая благодарность Gemini',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.amber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onLogout,
                child: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String title,
    String val, {
    IconData? trailingIcon,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trailingIcon != null) ...[
                Icon(trailingIcon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                val,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}