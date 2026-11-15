import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ai/ai_service.dart';

class MultimodalAiScreen extends StatefulWidget {
  const MultimodalAiScreen({super.key, this.aiService});

  final AiService? aiService;

  @override
  State<MultimodalAiScreen> createState() => _MultimodalAiScreenState();
}

class _MultimodalAiScreenState extends State<MultimodalAiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AiService _aiService;
  late final bool _ownsAiService;

  bool _isLoading = false;
  String? _ocrResult;
  String? _visionResult;
  String? _audioResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ownsAiService = widget.aiService == null;
    _aiService = widget.aiService ?? AiService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_ownsAiService) _aiService.dispose();
    super.dispose();
  }

  /// Simulasi pengambilan sampel byte gambar KTM/Dokumen
  Uint8List _generateSampleKtmImage() {
    // 1x1 dummy pixel bytes valid untuk testing/ekstraksi
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // Header PNG
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
  }

  /// Simulasi pengambilan sampel byte audio
  Uint8List _generateSampleAudio() {
    return Uint8List.fromList([
      0xFF, 0xFB, 0x90, 0x64, 0x00, 0x00, 0x00, 0x00, // Dummy MP3 frame
    ]);
  }

  Future<void> _processOcr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sampleImage = _generateSampleKtmImage();
      final result = await _aiService.recognizeText(sampleImage);
      setState(() {
        _ocrResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImageUnderstanding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sampleImage = _generateSampleKtmImage();
      final result = await _aiService.describeImage(
        sampleImage,
        prompt: 'Identifikasi objek pada foto ini secara singkat.',
      );
      setState(() {
        _visionResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processSpeechToText() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sampleAudio = _generateSampleAudio();
      final result = await _aiService.speechToText(sampleAudio);
      setState(() {
        _audioResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Multimodal Studio'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner), text: 'OCR'),
            Tab(icon: Icon(Icons.remove_red_eye), text: 'Vision'),
            Tab(icon: Icon(Icons.mic), text: 'Speech'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses dengan Gemini AI...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _MultimodalTab(
                  title: 'Ekstraksi Teks (OCR)',
                  description: 'Mengekstrak teks dari foto KTM, dokumen, atau struk belanja menggunakan Gemini Vision.',
                  buttonLabel: 'Pindai Teks Gambar (OCR)',
                  buttonIcon: Icons.camera_alt,
                  result: _ocrResult,
                  errorMessage: _errorMessage,
                  onPressed: _processOcr,
                ),
                _MultimodalTab(
                  title: 'Image Understanding',
                  description: 'Menganalisis objek, mendeskripsikan pemandangan, atau menjelaskan isi gambar.',
                  buttonLabel: 'Analisis & Deskripsikan Gambar',
                  buttonIcon: Icons.image_search,
                  result: _visionResult,
                  errorMessage: _errorMessage,
                  onPressed: _processImageUnderstanding,
                ),
                _MultimodalTab(
                  title: 'Speech-to-Text (Transkripsi)',
                  description: 'Mengonversi rekaman suara percakapan menjadi teks Bahasa Indonesia secara otomatis.',
                  buttonLabel: 'Mulai Transkripsi Audio',
                  buttonIcon: Icons.mic,
                  result: _audioResult,
                  errorMessage: _errorMessage,
                  onPressed: _processSpeechToText,
                ),
              ],
            ),
    );
  }
}

/// Konten satu tab dipisah dari halaman utama agar perubahan state lain tidak
/// membangun ulang seluruh isi tab beserta subtreenya.
class _MultimodalTab extends StatelessWidget {
  const _MultimodalTab({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.result,
    required this.errorMessage,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final String? result;
  final String? errorMessage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) _ErrorBanner(message: errorMessage!),
          if (result != null) ...[
            const Text(
              'Hasil Respons AI:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(child: _AiResultPanel(result: result!)),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'Tekan tombol di atas untuk memulai analisis AI.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hasil AI bersifat statis setelah dimuat. RepaintBoundary mencegah area ini
/// ikut di-repaint ketika indikator loading atau tab lain berubah.
class _AiResultPanel extends StatelessWidget {
  const _AiResultPanel({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            result,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Terjadi Kesalahan: $message',
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }
}
