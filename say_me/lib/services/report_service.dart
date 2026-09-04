import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Отправка жалобы на пользователя (например, за обман возраста)
  /// и автоматический перевод нарушителя в статус проверки 'under_review'
  Future<void> reportUser({
    required String reportedUserId,
    required String reporterId,
    required String reason,
    String details = '',
  }) async {
    try {
      // 1. Создаем запись жалобы в коллекции 'reports'
      await _firestore.collection('reports').add({
        'reported_user_id': reportedUserId,
        'reporter_id': reporterId,
        'reason': reason, // Например, 'age_misrepresentation'
        'details': details,
        'status': 'pending', // Статус самой жалобы: pending, approved, rejected
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Временно блокируем нарушителя до проверки администратором
      await _firestore.collection('users').doc(reportedUserId).update({
        'status': 'under_review',
      });
    } catch (e) {
      print('Ошибка при отправке жалобы: $e');
      rethrow;
    }
  }

  /// Метод для администратора: разблокировать юзера или подтвердить бан
  Future<void> resolveReport({
    required String reportId,
    required String userId,
    required bool approveBan, // true = забанить навсегда, false = разблокировать
  }) async {
    try {
      if (approveBan) {
        // Бан навсегда
        await _firestore.collection('users').doc(userId).update({
          'status': 'banned',
        });
      } else {
        // Подтвердили возраст / разблокировали
        await _firestore.collection('users').doc(userId).update({
          'status': 'active',
          'is_age_verified': true,
        });
      }

      // Обновляем статус жалобы
      await _firestore.collection('reports').doc(reportId).update({
        'status': approveBan ? 'approved' : 'rejected',
        'resolved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка при обработке жалобы: $e');
      rethrow;
    }
  }
}