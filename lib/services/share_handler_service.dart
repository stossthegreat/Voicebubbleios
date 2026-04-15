import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Handles files shared TO VoiceBubble from other apps
class ShareHandlerService {
  static final ShareHandlerService _instance = ShareHandlerService._internal();
  factory ShareHandlerService() => _instance;
  ShareHandlerService._internal();

  StreamSubscription? _mediaSubscription;
  bool _initialized = false;

  final _pendingShareController = StreamController<SharedContent>.broadcast();
  Stream<SharedContent> get pendingShares => _pendingShareController.stream;

  /// Buffer for cold-start share that may arrive before any listener subscribes
  SharedContent? _bufferedContent;

  /// Get and clear any buffered content from cold start
  SharedContent? consumeBufferedContent() {
    final content = _bufferedContent;
    _bufferedContent = null;
    return content;
  }

  /// Initialize - call once at app startup in main()
  void initialize() {
    if (_initialized) {
      debugPrint('ShareHandlerService already initialized');
      return;
    }

    debugPrint('Initializing ShareHandlerService...');

    // Listen for shares while app is running (warm start)
    _mediaSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia, onError: (err) {
      debugPrint('Share media stream error: $err');
    });

    // Handle shares that opened the app (cold start)
    _checkInitialShares();

    _initialized = true;
    debugPrint('ShareHandlerService initialized');
  }

  Future<void> _checkInitialShares() async {
    // Check for shared media files (includes text in newer API)
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      debugPrint('App opened with ${initialMedia.length} shared file(s)');
      _handleSharedMedia(initialMedia);
    }
  }

  void _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    debugPrint('Received ${files.length} shared file(s):');

    for (final file in files) {
      debugPrint('  Path: ${file.path}');
      debugPrint('  MIME: ${file.mimeType}');
      debugPrint('  Type: ${file.type}');

      final contentType = _getContentType(file.mimeType, file.type, file.path);
      final content = SharedContent(
        type: contentType,
        filePath: file.path,
        mimeType: file.mimeType,
        fileName: _extractFileName(file.path),
      );
      _bufferedContent = content; // Buffer in case no listener yet
      _pendingShareController.add(content);
    }

    // Reset so we don't process again
    ReceiveSharingIntent.instance.reset();
  }

  SharedContentType _getContentType(String? mimeType, SharedMediaType? mediaType, [String? filePath]) {
    // Check media type first (but NOT text — it misclassifies files like PDFs)
    if (mediaType == SharedMediaType.image) return SharedContentType.image;
    if (mediaType == SharedMediaType.video) return SharedContentType.video;

    // Check MIME type — check PDF/document before generic text/image
    if (mimeType != null) {
      final mime = mimeType.toLowerCase();
      if (mime.contains('pdf')) return SharedContentType.pdf;
      if (mime.contains('word') || mime.contains('document') || mime.contains('msword')) {
        return SharedContentType.document;
      }
      if (mime.startsWith('image/')) return SharedContentType.image;
      if (mime.startsWith('audio/')) return SharedContentType.audio;
      if (mime.startsWith('video/')) return SharedContentType.video;
      if (mime.startsWith('text/')) return SharedContentType.text;
    }

    // Fallback: check file extension (critical for external shares where MIME may be null/wrong)
    if (filePath != null) {
      final ext = filePath.toLowerCase().split('.').last;
      switch (ext) {
        case 'pdf': return SharedContentType.pdf;
        case 'doc':
        case 'docx': return SharedContentType.document;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'webp': return SharedContentType.image;
        case 'mp3':
        case 'wav':
        case 'm4a':
        case 'ogg':
        case 'flac': return SharedContentType.audio;
        case 'mp4':
        case 'mov':
        case 'avi': return SharedContentType.video;
        case 'txt':
        case 'md': return SharedContentType.text;
      }
    }

    // If media type is text and nothing else matched, treat as text
    if (mediaType == SharedMediaType.text) return SharedContentType.text;

    return SharedContentType.unknown;
  }

  String _extractFileName(String path) {
    return path.split('/').last;
  }

  void dispose() {
    _mediaSubscription?.cancel();
    _pendingShareController.close();
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED CONTENT MODELS
// ════════════════════════════════════════════════════════════════

enum SharedContentType {
  text,
  image,
  audio,
  video,
  pdf,
  document,
  unknown,
}

class SharedContent {
  final SharedContentType type;
  final String? filePath;
  final String? text;
  final String? mimeType;
  final String? fileName;

  SharedContent({
    required this.type,
    this.filePath,
    this.text,
    this.mimeType,
    this.fileName,
  });

  /// Display name for UI
  String get displayName {
    switch (type) {
      case SharedContentType.text: return 'Text';
      case SharedContentType.image: return 'Image';
      case SharedContentType.audio: return 'Audio';
      case SharedContentType.video: return 'Video';
      case SharedContentType.pdf: return 'PDF';
      case SharedContentType.document: return 'Document';
      case SharedContentType.unknown: return 'File';
    }
  }

  /// Icon for UI
  IconData get icon {
    switch (type) {
      case SharedContentType.text: return Icons.text_fields;
      case SharedContentType.image: return Icons.image;
      case SharedContentType.audio: return Icons.audiotrack;
      case SharedContentType.video: return Icons.videocam;
      case SharedContentType.pdf: return Icons.picture_as_pdf;
      case SharedContentType.document: return Icons.description;
      case SharedContentType.unknown: return Icons.insert_drive_file;
    }
  }

  /// Color for UI
  Color get color {
    switch (type) {
      case SharedContentType.text: return const Color(0xFF3B82F6); // Blue
      case SharedContentType.image: return const Color(0xFF10B981); // Green
      case SharedContentType.audio: return const Color(0xFFF59E0B); // Amber
      case SharedContentType.video: return const Color(0xFFEC4899); // Pink
      case SharedContentType.pdf: return const Color(0xFFEF4444); // Red
      case SharedContentType.document: return const Color(0xFF8B5CF6); // Purple
      case SharedContentType.unknown: return const Color(0xFF64748B); // Gray
    }
  }

  /// Whether this content can be transcribed
  bool get canTranscribe => type == SharedContentType.audio;

  /// Whether this content can be processed by AI
  bool get canProcessWithAI => type == SharedContentType.text ||
                                type == SharedContentType.audio;
}
