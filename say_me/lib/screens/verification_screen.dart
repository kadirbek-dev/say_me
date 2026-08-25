import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'face_scan_screen.dart';

class VerificationScreen extends StatefulWidget {
  final UserModel currentUser;

  const VerificationScreen({super.key, required this.currentUser});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isProcessing = false;

  Future<void> _startFaceVerification() async {
    bool isSuccess = false;

    // Если запускаем в браузере — автоматически зачитываем успешный тест
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ВЕБ-ТЕСТ: Проверка лицом пропущена!'),
          backgroundColor: Colors.green,
        ),
      );
      isSuccess = true;
    } else {
      // На мобильном устройстве открываем настоящий сканер ML Kit
      final bool? result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const FaceScanScreen()),
      );
      isSuccess = result ?? false;
    }

    if (isSuccess) {
      setState(() => _isProcessing = true);

      // Обновляем статус в базе
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
                'Для безопасности пользователей публикация постов и личные сообщения доступны только после проверки лица.',
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