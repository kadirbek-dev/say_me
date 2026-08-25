import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Все';

  final List<String> categories = [
    'Все',
    'Тревога и стресс',
    'Отношения',
    'Одиночество',
    'Выговориться',
  ];

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Категории
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
                    onSelected: (_) => setState(() => selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          // Карточки обращений
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
                  author: 'Алексей',
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
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        backgroundColor: const Color(0xFF81C784),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Выговориться', style: TextStyle(color: Colors.white)),
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
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, color: Colors.white),
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
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
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