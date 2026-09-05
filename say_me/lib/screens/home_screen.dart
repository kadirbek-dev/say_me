import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Данные профиля
  String _userName = 'Алексей';
  Uint8List? _avatarBytes;

  // Список постов
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Аноним',
      'tag': 'Тревога и стресс',
      'title': 'Чувствую постоянную тревогу перед учебой/работой',
      'desc': 'В последнее время стало сложно заставить себя выходить из дома...',
      'likes': 12,
      'comments': 4,
      'imageBytes': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildFeedTab(),
      const ChatScreen(),
      _buildProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF81C784),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'ИИ Чат',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  // --- 1. Вкладка Ленты с постами и созданием поста ---
  Widget _buildFeedTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Say me — Поддержка',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Создать пост', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- Создание поста с фото из галереи ---
  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    Uint8List? postImageBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Новый пост', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Заголовок', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setModalState(() => postImageBytes = bytes);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Выбрать фото'),
                      ),
                      const SizedBox(width: 12),
                      if (postImageBytes != null)
                        const Text('Фото выбрано!', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          _posts.insert(0, {
                            'author': _userName,
                            'tag': 'Выговориться',
                            'title': titleController.text,
                            'desc': descController.text,
                            'likes': 0,
                            'comments': 0,
                            'imageBytes': postImageBytes,
                          });
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Опубликовать', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. Вкладка Профиля (Аватарка + Ник) ---
  Widget _buildProfileTab() {
    final nameController = TextEditingController(text: _userName);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Профиль', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFFE0E0E0),
                    backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                    child: _avatarBytes == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setState(() => _avatarBytes = bytes);
                        }
                      },
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF81C784),
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Никнейм',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() => _userName = nameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Профиль успешно обновлён!')),
                  );
                },
                child: const Text('Сохранить изменения', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final bool isMyPost = post['author'] == _userName;
    final Uint8List? postImg = post['imageBytes'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage: isMyPost && _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                  child: (!isMyPost || _avatarBytes == null)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post['tag'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(post['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(post['desc'], style: const TextStyle(color: Color(0x99000000))),
            if (postImg != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(postImg, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: Text('Поддержать (${post['likes']})'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Ответы (${post['comments']})'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}