import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/face_scan_screen.dart';
import 'services/security_service.dart';
import 'services/safety_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAb3xvaU9119y6_9gaYe0qb7V5Cqjv_0L8",
        authDomain: "sayme-2d93e.firebaseapp.com",
        projectId: "sayme-2d93e",
        storageBucket: "sayme-2d93e.firebasestorage.app",
        messagingSenderId: "302686958026",
        appId: "1:302686958026:web:ed73452e209a7eabc61f33",
        measurementId: "G-BSWYNSL3DQ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const SayMeApp());
}

// ---------------- МОДЕЛЬ ПОЛЬЗОВАТЕЛЯ ----------------
enum UserRole { patient, doctor }
enum AgeCategory { kids, teens, adults }

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
  });

  static AgeCategory calculateAgeCategory(int age) {
    if (age >= 6 && age <= 13) return AgeCategory.kids;
    if (age >= 14 && age <= 17) return AgeCategory.teens;
    return AgeCategory.adults;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final ageVal = map['age'] ?? 18;
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role == UserRole.doctor ? 'doctor' : 'patient',
      'gender': gender,
      'age': age,
      'is_identity_verified': isIdentityVerified,
      'avatar_url': avatarUrl,
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

// ---------------- СВЯЗКА С FIREBASE AUTH И ПРОВЕРКОЙ ВЕРИФИКАЦИИ ----------------
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
              );
            }

            // Если лицо не подтверждено — отправляем на экран сканирования
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

// ---------------- ЭКРАН ВЕРИФИКАЦИИ ЛИЦА ----------------
class VerificationScreen extends StatefulWidget {
  final UserModel currentUser;

  const VerificationScreen({super.key, required this.currentUser});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isProcessing = false;

  Future<void> _startFaceVerification() async {
    final bool? isSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const FaceScanScreen()),
    );

    if (isSuccess == true) {
      setState(() => _isProcessing = true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.id)
          .update({'is_identity_verified': true});

      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face_retouching_natural_rounded,
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
                'Подтверждение личности',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Для безопасности пользователей публикация постов и чаты доступны только после сканирования лица.',
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
                const Text('Обновляем ваш статус...'),
              ] else ...[
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
                    onPressed: _startFaceVerification,
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text(
                      'Пройти проверку лицом',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String text) {
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

    final List<Widget> screens = [
      const HomeScreen(),
      SearchScreen(onOpenChat: (u) => _openDirectChat(context, u)),
      ChatListScreen(
        currentUser: widget.currentUser,
        onOpenChat: (u) => _openDirectChat(context, u),
      ),
      ProfileScreen(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.search_rounded, 1),
            GestureDetector(
              onTap: () => _createNewPost(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3C4C8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF5C4643), size: 22),
              ),
            ),
            _buildNavItem(Icons.chat_bubble_outline_rounded, 2),
            _buildNavItem(Icons.person_outline_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
        size: 24,
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
    bool isAnon = true;

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
                maxLines: 4,
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
              const SizedBox(height: 12),
              Row(
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
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('posts').add({
                        'authorName': isAnon ? 'Аноним' : widget.currentUser.username,
                        'authorId': widget.currentUser.id,
                        'text': text,
                        'isAnonymous': isAnon,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(
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

// ---------------- 1. ЛЕНТА ПОСТОВ ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              const SizedBox(height: 8),
                              Text(data['text'] ?? ''),
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
        children: [
          const SizedBox(height: 12),
          const Text('Диалоги',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          child: Text(u.username.isNotEmpty ? u.username[0] : 'U')),
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

// ---------------- 4. ОКНО ЧАТА С E2E-ШИФРОВАНИЕМ И МОДЕРАЦИЕЙ ----------------
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

  String _getChatId() {
    final ids = [widget.currentUser.id, widget.targetUser.id]..sort();
    return ids.join('_');
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // 1. Проверка безопасности (попытки увести в соцсети)
    if (SafetyService.containsSuspiciousActivity(text)) {
      _showSafetyWarningDialog();
      return;
    }

    // 2. ИИ-модерация на недопустимые слова
    final moderation = SecurityService.moderateText(text);
    if (!moderation.isSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(moderation.warningMessage ?? 'Сообщение содержит недопустимый контент'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _msgController.clear();
    final chatId = _getChatId();

    // 3. E2E-шифрование сообщения перед отправкой
    final encryptedText = SecurityService.encryptMessage(text, chatId);

    // 4. Сохранение в Firestore
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUser.id,
      'recipientId': widget.targetUser.id,
      'text': encryptedText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _showSafetyWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ограничение безопасности'),
        content: const Text(
          'Обнаружена попытка передачи сторонних контактов (Telegram/WhatsApp). '
          'Для защиты пользователей требуется подтверждение возраста по документу.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
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
        title: Text(widget.targetUser.username),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
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
                    final data = docs[i].data() as Map<String, dynamic>;
                    final encryptedText = data['text'] ?? '';

                    // Расшифровка текста сообщения на лету
                    final decryptedText =
                        SecurityService.decryptMessage(encryptedText, chatId);
                    final isMe = data['senderId'] == widget.currentUser.id;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          decryptedText,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
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
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 5. ПРОФИЛЬ ----------------
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('Профиль',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                currentUser.username.isNotEmpty ? currentUser.username[0] : 'U',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currentUser.username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Row(
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