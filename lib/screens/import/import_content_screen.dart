import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../models/recording_item.dart';
import '../../providers/app_state_provider.dart';
import '../../services/share_handler_service.dart';
import '../../services/ai_service.dart';
import '../../services/feature_gate.dart';
import '../../services/analytics_service.dart';
import '../main/recording_detail_screen.dart';
import '../main/preset_selection_screen.dart';
import '../paywall/paywall_screen.dart';

/// Screen for processing imported/shared content
class ImportContentScreen extends StatefulWidget {
  final SharedContent content;
  /// Optional: If provided, imported content will be appended to this note
  final String? appendToNoteId;

  const ImportContentScreen({
    super.key,
    required this.content,
    this.appendToNoteId,
  });

  @override
  State<ImportContentScreen> createState() => _ImportContentScreenState();
}

class _ImportContentScreenState extends State<ImportContentScreen> {
  bool _isProcessing = false;
  bool _isTranscribing = false;
  String? _extractedText;
  String? _error;
  String? _savedImagePath; // For image imports

  // Colors
  static const _backgroundColor = Color(0xFF000000);
  static const _surfaceColor = Color(0xFF1A1A1A);
  static const _textColor = Colors.white;
  static const _secondaryTextColor = Color(0xFF94A3B8);
  static const _primaryColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _processContent();
  }

  Future<void> _processContent() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      switch (widget.content.type) {
        case SharedContentType.text:
          // Direct text - just use it
          if (widget.content.text != null) {
            _extractedText = _cleanImportedText(widget.content.text!);
          } else if (widget.content.filePath != null) {
            // Text file - read contents
            final file = File(widget.content.filePath!);
            if (await file.exists()) {
              _extractedText = _cleanImportedText(await file.readAsString());
            } else {
              _error = 'File not found';
            }
          }
          break;

        case SharedContentType.audio:
          await _transcribeAudio();
          break;

        case SharedContentType.pdf:
          await _extractPdfText();
          break;

        case SharedContentType.document:
          await _extractDocxText();
          break;

        case SharedContentType.image:
          await _processImageImport();
          break;

        case SharedContentType.video:
          _extractedText = _buildPlaceholderText(
            'Video Import',
            'Video transcription coming soon!\n\n'
            'For now, you can:\n'
            '- Extract the audio and share it separately\n'
            '- Use voice recording to describe the content',
          );
          break;

        case SharedContentType.unknown:
          // Check for OCR mode (mimeType == 'image/ocr')
          if (widget.content.mimeType == 'image/ocr') {
            await _processImageOCR();
          } else {
            _error = 'Unsupported file type: ${widget.content.mimeType ?? "unknown"}';
          }
          break;

        default:
          _error = 'Unsupported file type: ${widget.content.mimeType ?? "unknown"}';
      }
    } catch (e) {
      debugPrint('Error processing content: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _buildPlaceholderText(String title, String message) {
    return '[$title]\n\n'
           'File: ${widget.content.fileName ?? "Unknown"}\n\n'
           '$message';
  }

  /// Clean up excessive whitespace from any imported text.
  /// Preserves single paragraph breaks but removes excessive spacing.
  String _cleanImportedText(String text) {
    // Normalize line endings
    var cleaned = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Remove trailing whitespace from each line
    cleaned = cleaned.split('\n').map((line) => line.trimRight()).join('\n');

    // Collapse 3+ consecutive newlines down to 2 (one blank line = paragraph break)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove lines that contain ONLY whitespace (spaces/tabs but no text)
    cleaned = cleaned.replaceAll(RegExp(r'\n[ \t]+\n'), '\n\n');

    return cleaned.trim();
  }

  /// Extract text from PDF using Syncfusion PDF library
  Future<void> _extractPdfText() async {
    if (widget.content.filePath == null) {
      _error = 'No PDF file path';
      return;
    }

    try {
      Uint8List bytes;
      final path = widget.content.filePath!;

      if (path.startsWith('content://')) {
        // Handle Android content:// URI — may not be readable as a regular file
        try {
          final sourceFile = File(path);
          if (await sourceFile.exists()) {
            bytes = await sourceFile.readAsBytes();
          } else {
            _error = 'Cannot access this PDF. Try opening it first, then sharing to VoiceBubble.';
            return;
          }
        } catch (e) {
          debugPrint('Content URI read error: $e');
          _error = 'Cannot access this PDF. Try using "Open with" instead of "Share".';
          return;
        }
      } else {
        final file = File(path);
        if (!await file.exists()) {
          _error = 'PDF file not found';
          return;
        }
        bytes = await file.readAsBytes();
      }

      // Validate PDF magic bytes (%PDF)
      if (bytes.length < 4 ||
          bytes[0] != 0x25 || bytes[1] != 0x50 ||
          bytes[2] != 0x44 || bytes[3] != 0x46) {
        _error = 'This file does not appear to be a valid PDF.';
        return;
      }

      PdfDocument? document;
      try {
        document = PdfDocument(inputBytes: bytes);
      } catch (e) {
        debugPrint('PDF load error: $e');
        _error = 'Could not open this PDF. It may be encrypted or corrupted.';
        return;
      }

      final StringBuffer textBuffer = StringBuffer();
      int successPages = 0;
      int failedPages = 0;

      // Page-by-page extraction with individual error handling
      for (int i = 0; i < document.pages.count; i++) {
        try {
          final extractor = PdfTextExtractor(document);
          final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
          if (pageText.trim().isNotEmpty) {
            if (textBuffer.isNotEmpty) textBuffer.write('\n\n');
            textBuffer.write(pageText.trim());
            successPages++;
          }
        } catch (e) {
          debugPrint('PDF page $i error: $e');
          failedPages++;
          // Continue — don't let one bad page kill the import
        }
      }

      document.dispose();

      final extractedText = textBuffer.toString().trim();

      if (extractedText.isEmpty) {
        _error = failedPages > 0
            ? 'Could not extract text. The PDF may be scanned/image-based or damaged.'
            : 'No text found in this PDF. It may be an image-based (scanned) PDF.';
        return;
      }

      _extractedText = _cleanImportedText(extractedText);
      if (failedPages > 0 && successPages > 0) {
        _extractedText = '⚠️ Note: $failedPages page(s) could not be read.\n\n$_extractedText';
      }
      debugPrint('PDF done: ${_extractedText!.length} chars, $successPages ok, $failedPages failed');
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      _error = 'Failed to process PDF: ${e.toString()}';
      AnalyticsService().logError(
        errorType: 'pdf_import_failed',
        errorMessage: e.toString(),
        context: 'import_content_screen_pdf',
      );
    }
  }

  /// Extract text from Word documents (.docx)
  Future<void> _extractDocxText() async {
    if (widget.content.filePath == null) {
      _error = 'No document file path';
      return;
    }

    try {
      final file = File(widget.content.filePath!);
      if (!await file.exists()) {
        _error = 'Document file not found';
        return;
      }

      final bytes = await file.readAsBytes();
      final extension = widget.content.filePath!.toLowerCase();

      // Check if it's a .doc (old format) or .docx (new format)
      if (extension.endsWith('.doc') && !extension.endsWith('.docx')) {
        _error = 'Old .doc format is not supported. Please save as .docx and try again.';
        return;
      }

      // .docx is a ZIP archive containing XML files
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find the main document content (word/document.xml)
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) {
        _error = 'Invalid Word document: missing document.xml';
        return;
      }

      // Decode the XML content
      final xmlContent = utf8.decode(documentFile.content as List<int>);

      // Parse XML and extract text from <w:t> elements (Word text elements)
      final textBuffer = StringBuffer();

      // Simple regex-based extraction of text from XML
      // <w:t>text</w:t> or <w:t xml:space="preserve">text</w:t>
      final textRegex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      final matches = textRegex.allMatches(xmlContent);

      String currentParagraph = '';
      int lastEnd = 0;

      for (final match in matches) {
        final text = match.group(1) ?? '';

        // Check if there's a paragraph break between this and the last match
        final between = xmlContent.substring(lastEnd, match.start);
        if (between.contains('</w:p>')) {
          // End of paragraph - add to buffer with newline
          if (currentParagraph.isNotEmpty) {
            textBuffer.writeln(currentParagraph.trim());
            textBuffer.writeln();
          }
          currentParagraph = text;
        } else {
          currentParagraph += text;
        }
        lastEnd = match.end;
      }

      // Add final paragraph
      if (currentParagraph.isNotEmpty) {
        textBuffer.write(currentParagraph.trim());
      }

      final extractedText = textBuffer.toString().trim();

      if (extractedText.isEmpty) {
        _error = 'No text could be extracted from this document.';
        return;
      }

      _extractedText = _cleanImportedText(extractedText);
      debugPrint('DOCX extraction complete: ${_extractedText!.length} chars');
    } catch (e) {
      debugPrint('DOCX extraction error: $e');
      _error = 'Failed to extract text from document: ${e.toString()}';
      AnalyticsService().logError(
        errorType: 'docx_import_failed',
        errorMessage: e.toString(),
        context: 'import_content_screen_docx',
      );
    }
  }

  /// Process image import — save to permanent storage
  Future<void> _processImageImport() async {
    if (widget.content.filePath == null) {
      _error = 'No image file path';
      return;
    }

    try {
      final sourceFile = File(widget.content.filePath!);
      if (!await sourceFile.exists()) {
        _error = 'Image file not found';
        return;
      }

      // Copy to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = widget.content.filePath!.split('.').last.toLowerCase();
      final fileName = '${const Uuid().v4()}.$ext';
      final savedPath = p.join(imagesDir.path, fileName);
      await sourceFile.copy(savedPath);

      _savedImagePath = savedPath;
      _extractedText = '[Image ready to import]';
      debugPrint('Image saved to: $savedPath');
    } catch (e) {
      debugPrint('Image import error: $e');
      _error = 'Failed to import image: ${e.toString()}';
    }
  }

  /// OCR — Extract text from image using Google ML Kit
  Future<void> _processImageOCR() async {
    if (widget.content.filePath == null) {
      _error = 'No image file path';
      AnalyticsService().logImageToTextUsed(
        characterCount: 0,
        success: false,
        source: 'no_file_path',
      );
      return;
    }

    try {
      final file = File(widget.content.filePath!);
      if (!await file.exists()) {
        _error = 'Image file not found';
        AnalyticsService().logImageToTextUsed(
          characterCount: 0,
          success: false,
          source: 'file_not_found',
        );
        return;
      }

      final inputImage = InputImage.fromFilePath(widget.content.filePath!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

        if (recognizedText.text.trim().isEmpty) {
          _error = 'No text detected in this image. Try a clearer photo with visible text.';
          AnalyticsService().logImageToTextUsed(
            characterCount: 0,
            success: false,
            source: 'no_text_detected',
          );
          return;
        }

        // Build structured text preserving blocks and lines
        final StringBuffer textBuffer = StringBuffer();
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            textBuffer.writeln(line.text);
          }
          textBuffer.writeln(); // Paragraph break between blocks
        }

        _extractedText = _cleanImportedText(textBuffer.toString());
        debugPrint('OCR complete: ${_extractedText!.length} chars from ${recognizedText.blocks.length} blocks');

        AnalyticsService().logImageToTextUsed(
          characterCount: _extractedText!.length,
          success: true,
          source: widget.content.type.name,
        );
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OCR error: $e');
      _error = 'Text extraction failed: ${e.toString()}';
      AnalyticsService().logImageToTextUsed(
        characterCount: 0,
        success: false,
        source: 'ocr_error',
      );
    }
  }

  /// Save imported image to note
  Future<void> _saveImageImport() async {
    if (_savedImagePath == null) return;

    HapticFeedback.mediumImpact();

    final appState = context.read<AppStateProvider>();

    if (widget.appendToNoteId != null) {
      // Update existing note with image
      final existingItem = appState.allRecordingItems.firstWhere(
        (r) => r.id == widget.appendToNoteId,
        orElse: () => throw Exception('Note not found'),
      );

      final updatedItem = existingItem.copyWith(
        rawTranscript: _savedImagePath,
        contentType: 'image',
      );
      await appState.updateRecording(updatedItem);

      if (mounted) Navigator.pop(context, true);
    } else {
      // Create new image note
      String title = widget.content.fileName ?? 'Imported Image';
      if (title.contains('.')) title = title.substring(0, title.lastIndexOf('.'));
      title = title.replaceAll('_', ' ').replaceAll('-', ' ');

      final newItem = RecordingItem(
        id: const Uuid().v4(),
        rawTranscript: _savedImagePath!,
        finalText: '',
        presetUsed: 'Image Import',
        outcomes: [],
        projectId: null,
        createdAt: DateTime.now(),
        editHistory: ['Imported image: ${widget.content.fileName}'],
        presetId: 'image_import',
        tags: [],
        contentType: 'image',
        customTitle: title,
      );
      await appState.saveRecording(newItem);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecordingDetailScreen(recordingId: newItem.id),
          ),
        );
      }
    }
  }

  Future<void> _transcribeAudio() async {
    if (widget.content.filePath == null) {
      _error = 'No audio file path';
      return;
    }

    // Check if user is Pro first
    final isPro = await FeatureGate.isPro();
    if (!isPro) {
      _error = 'Audio transcription is a Pro feature. Upgrade to transcribe audio files.';
      return;
    }

    // Check if user can use STT
    final canUse = await FeatureGate.canUseSTT(context);
    if (!canUse) {
      _error = 'No transcription time remaining. Upgrade to Pro for more time.';
      return;
    }

    setState(() => _isTranscribing = true);

    try {
      final file = File(widget.content.filePath!);

      if (!await file.exists()) {
        _error = 'Audio file not found';
        return;
      }

      final fileSize = await file.length();
      debugPrint('Audio file size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Transcribe
      final aiService = AIService();
      _extractedText = await aiService.transcribeAudio(file);

      if (_extractedText == null || _extractedText!.isEmpty) {
        _error = 'No speech detected in audio file';
        return;
      }

      // Track usage (estimate: ~1 min per MB for compressed audio)
      final estimatedSeconds = (fileSize / 1000000 * 60).round().clamp(10, 600);
      await FeatureGate.trackSTTUsage(estimatedSeconds);

      debugPrint('Transcription complete: ${_extractedText!.length} chars');
    } catch (e) {
      _error = 'Transcription failed: $e';
    } finally {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Future<void> _saveAsNote() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    HapticFeedback.mediumImpact();

    final appState = context.read<AppStateProvider>();

    // If we're appending to an existing note
    if (widget.appendToNoteId != null) {
      final existingItem = appState.allRecordingItems.firstWhere(
        (r) => r.id == widget.appendToNoteId,
        orElse: () => throw Exception('Note not found'),
      );

      // Append the imported text to the existing content
      final newText = existingItem.finalText.isEmpty
          ? _extractedText!
          : '${existingItem.finalText}\n\n---\n[Imported from: ${widget.content.fileName ?? "file"}]\n\n${_extractedText!}';

      // Build new Quill Delta JSON so the editor loads the updated content
      // This is critical: the editor prioritizes formattedContent over finalText
      // If we just set finalText, the old formattedContent will be loaded instead
      final newDelta = [
        {'insert': '$newText\n'}
      ];
      final newFormattedContent = jsonEncode(newDelta);

      final updatedItem = existingItem.copyWith(
        finalText: newText,
        formattedContent: newFormattedContent, // Editor will load THIS, which has the new text
      );

      await appState.updateRecording(updatedItem);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate content was imported
      }
      return;
    }

    // Otherwise create a new note
    // Generate title from filename or content
    String title = widget.content.fileName ?? 'Imported Content';
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.')); // Remove extension
    }
    // Clean up title
    title = title.replaceAll('_', ' ').replaceAll('-', ' ');
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }

    final newItem = RecordingItem(
      id: const Uuid().v4(),
      rawTranscript: _extractedText!,
      finalText: _extractedText!,
      presetUsed: 'Imported ${widget.content.displayName}',
      outcomes: [],
      projectId: null,
      createdAt: DateTime.now(),
      editHistory: [_extractedText!],
      presetId: 'imported_${widget.content.type.name}',
      tags: ['imported'],
      contentType: widget.content.type == SharedContentType.audio ? 'voice' : 'text',
      customTitle: title,
    );

    await appState.saveRecording(newItem);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecordingDetailScreen(recordingId: newItem.id),
        ),
      );
    }
  }

  Future<void> _processWithAI() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    HapticFeedback.mediumImpact();

    final appState = context.read<AppStateProvider>();
    appState.setTranscription(_extractedText!);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PresetSelectionScreen(fromRecording: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.content.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.content.icon, color: widget.content.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Import ${widget.content.displayName}',
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isProcessing || _isTranscribing) {
      return _buildLoadingState();
    }

    // Error state
    if (_error != null) {
      return _buildErrorState();
    }

    // Success state - show preview
    return _buildSuccessState();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                color: widget.content.color,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isTranscribing ? 'Transcribing audio...' : 'Processing...',
              style: const TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.content.fileName != null)
              Text(
                widget.content.fileName!,
                style: TextStyle(color: _secondaryTextColor.withOpacity(0.7), fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (_isTranscribing) ...[
              const SizedBox(height: 16),
              Text(
                'This may take a moment...',
                style: TextStyle(color: _secondaryTextColor.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isProFeatureError = _error!.contains('Pro feature');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isProFeatureError ? const Color(0xFFFFD700) : const Color(0xFFEF4444)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                isProFeatureError ? Icons.workspace_premium : Icons.error_outline,
                color: isProFeatureError ? const Color(0xFFFFD700) : const Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isProFeatureError ? 'Pro Feature' : 'Import Failed',
              style: const TextStyle(
                color: _textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: _secondaryTextColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    side: BorderSide(color: _secondaryTextColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: _secondaryTextColor)),
                ),
                const SizedBox(width: 16),
                if (isProFeatureError)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaywallScreen(
                            onSubscribe: () => Navigator.pop(context),
                            onRestore: () => Navigator.pop(context),
                            onClose: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium, color: Colors.black, size: 18),
                    label: const Text('Upgrade to Pro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _processContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final wordCount = _extractedText?.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length ?? 0;

    return Column(
      children: [
        // File info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.content.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.content.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(widget.content.icon, color: widget.content.color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content.fileName ?? 'Shared ${widget.content.displayName}',
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.content.type == SharedContentType.image && _savedImagePath != null
                        ? 'Image ready to import'
                        : '$wordCount words - Ready to save',
                      style: const TextStyle(color: _secondaryTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Content preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: widget.content.type == SharedContentType.image && _savedImagePath != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_savedImagePath!),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.content.fileName ?? 'Image',
                          style: const TextStyle(color: _secondaryTextColor, fontSize: 13),
                        ),
                      ],
                    )
                  : SelectableText(
                      _extractedText ?? 'No content',
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary: Process with AI (only if creating new note, not appending)
                if (widget.appendToNoteId == null &&
                    (widget.content.canProcessWithAI || widget.content.type == SharedContentType.text))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _extractedText != null ? _processWithAI : null,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      label: const Text(
                        'Process with AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        disabledBackgroundColor: _primaryColor.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (widget.appendToNoteId == null &&
                    (widget.content.canProcessWithAI || widget.content.type == SharedContentType.text))
                  const SizedBox(height: 12),

                // Save/Add button
                SizedBox(
                  width: double.infinity,
                  child: widget.appendToNoteId != null
                    // When appending, make it primary action with filled button
                    ? ElevatedButton.icon(
                        onPressed: _extractedText != null
                          ? (widget.content.type == SharedContentType.image && _savedImagePath != null
                              ? _saveImageImport
                              : _saveAsNote)
                          : null,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                        label: const Text(
                          'Add to Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor: _primaryColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    // When creating new, use outlined button
                    : OutlinedButton.icon(
                        onPressed: _extractedText != null
                          ? (widget.content.type == SharedContentType.image && _savedImagePath != null
                              ? _saveImageImport
                              : _saveAsNote)
                          : null,
                        icon: Icon(Icons.save_alt, color: _secondaryTextColor, size: 20),
                        label: Text(
                          'Save as Note',
                          style: TextStyle(color: _secondaryTextColor, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: _secondaryTextColor.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
