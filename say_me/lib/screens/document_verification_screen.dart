import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentVerificationScreen extends StatefulWidget {
  final int userAge;

  const DocumentVerificationScreen({super.key, required this.userAge});

  @override
  State<DocumentVerificationScreen> createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusText = 'Поместите документ (удостоверение/паспорт) в рамку';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Ошибка подключения камеры');
      }
    }
  }

  Future<void> _scanDocument() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'ИИ распознаёт текст на документе...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text;

      final RegExp dateRegExp = RegExp(r'\b(19|20)\d{2}\b');
      final Iterable<RegExpMatch> matches = dateRegExp.allMatches(fullText);

      bool ageVerified = false;
      final int currentYear = DateTime.now().year;

      for (final match in matches) {
        final int? birthYear = int.tryParse(match.group(0) ?? '');
        if (birthYear != null && birthYear > 1920 && birthYear < currentYear) {
          final int calculatedAge = currentYear - birthYear;
          if ((calculatedAge - widget.userAge).abs() <= 1 && calculatedAge >= 18) {
            ageVerified = true;
            break;
          }
        }
      }

      if (ageVerified) {
        setState(() => _statusText = 'Документ подтверждён! Возраст 18+');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _isProcessing = false;
          _statusText =
              'Не удалось подтвердить возраст 18+. Проверьте освещение и четкость снимка.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Ошибка сканирования документа';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка документа (18+)'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _statusText,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _isCameraInitialized
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.colorScheme.primary, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: AspectRatio(
                            aspectRatio: 1.58,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _scanDocument,
                  icon: const Icon(Icons.document_scanner_rounded,
                      color: Colors.white),
                  label: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Сканировать документ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}