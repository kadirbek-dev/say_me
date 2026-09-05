import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart'; // Путь к твоему экрану чата

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Данные профиля (состояние)
  String _userName = 'Алексей';
  XFile? _avatarImage;

  @override
  Widget build(BuildContext context) {
    // Список экранов для переключения
    final List<Widget> screens = [
      _buildFeedTab(),
      const ChatScreen(), // Твой ИИ Чат
      _buildProfileTab(), // Новый экран профиля
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
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

  // --- Вкладка 1: Главная лента ---
  Widget _buildFeedTab() {
    String selectedCategory = 'Все';
    final List<String> categories = [
      'Все',
      'Тревога и стресс',
      'Отношения',
      'Одиночество',
      'Выговориться',
    ];

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
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    selectedColor: const Color(0xFFE8E0F9),
                    onSelected: (_) {},
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPostCard(
                  author: 'Аноним',
                  tag: 'Тревога и стресс',
                  title: 'Чувствую постоянную тревогу перед учебой/работой',
                  desc: 'В последнее время стало сложно заставить себя выходить из дома...',
                  likes: 12,
                  comments: 4,
                ),
                _buildPostCard(
                  author: _userName,
                  tag: 'Отношения',
                  title: 'Не могу найти общий язык с близкими',
                  desc: 'Кажется, будто меня никто не слышит. Как научиться спокойно объяснять позицию?',
                  likes: 8,
                  comments: 6,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _currentIndex = 1), // Переход в ИИ Чат
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Чат с ИИ', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- Вкладка 3: Профиль (Никнейм + Аватарка) ---
  Widget _buildProfileTab() {
    final nameController = TextEditingController(text: _userName);

    Future<void> pickAvatar() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _avatarImage = image);
      }
    }

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
                    backgroundImage: _avatarImage != null ? NetworkImage(_avatarImage!.path) : null,
                    child: _avatarImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickAvatar,
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

  Widget _buildPostCard({
    required String author,
    required String tag,
    required String title,
    required String desc,
    required int likes,
    required int comments,
  }) {
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
                  backgroundImage: _avatarImage != null && author == _userName ? NetworkImage(_avatarImage!.path) : null,
                  child: _avatarImage == null || author != _userName
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(tag, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: Color(0x99000000))),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: Text('Поддержать ($likes)'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text('Ответы ($comments)'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}