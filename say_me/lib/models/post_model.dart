enum PostCategory {
  anxious,    // Тревога и стресс
  relationship, // Отношения
  loneliness,  // Одиночество
  general,     // Общее / Просто выговориться
}

class PostModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final bool isAnonymous;
  final DateTime createdAt;
  final PostCategory category;
  final int commentsCount;
  final int supportCount; // В место "лайков" — "Поддержка"

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.isAnonymous,
    required this.createdAt,
    required this.category,
    this.commentsCount = 0,
    this.supportCount = 0,
  });

  static String getCategoryName(PostCategory category) {
    switch (category) {
      case PostCategory.anxious:
        return 'Тревога и стресс';
      case PostCategory.relationship:
        return 'Отношения';
      case PostCategory.loneliness:
        return 'Одиночество';
      case PostCategory.general:
        return 'Выговориться';
    }
  }
}