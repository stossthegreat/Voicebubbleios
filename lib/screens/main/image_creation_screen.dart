import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../providers/app_state_provider.dart';
import '../../models/recording_item.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tag_selection_dialog.dart';
import '../../services/analytics_service.dart';

class ImageCreationScreen extends StatefulWidget {
  final String? projectId;
  final String? itemId; // For editing existing items

  const ImageCreationScreen({
    super.key,
    this.projectId,
    this.itemId,
  });

  @override
  State<ImageCreationScreen> createState() => _ImageCreationScreenState();
}

class _ImageCreationScreenState extends State<ImageCreationScreen> {
  late TextEditingController _titleController;
  late TextEditingController _captionController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _captionFocusNode = FocusNode();
  
  List<String> _selectedTags = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  File? _selectedImage;
  String? _savedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _captionController = TextEditingController();
    
    // Add listeners to track changes
    _titleController.addListener(_onTextChanged);
    _captionController.addListener(_onTextChanged);
    
    // Load existing item if editing
    if (widget.itemId != null) {
      _loadExistingItem();
    } else {
      // Auto-focus title for new images
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadExistingItem() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final item = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
    
    if (item != null) {
      setState(() {
        _titleController.text = item.customTitle ?? '';
        _captionController.text = item.finalText;
        _selectedTags = List.from(item.tags);
        _savedImagePath = item.rawTranscript; // Load existing image path
        if (_savedImagePath?.isNotEmpty == true) {
          _selectedImage = File(_savedImagePath!);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _titleFocusNode.dispose();
    _captionFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Discard changes?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _saveImagePermanently(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final fileName = '${const Uuid().v4()}.jpg';
    final savedImage = File(path.join(imagesDir.path, fileName));
    
    await imageFile.copy(savedImage.path);
    return savedImage.path;
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null && widget.itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // Save image permanently if new image selected
      if (_selectedImage != null) {
        _savedImagePath = await _saveImagePermanently(_selectedImage!);
      }
      
      if (widget.itemId != null) {
        // Update existing item
        final existingItem = appState.recordingItems.where((i) => i.id == widget.itemId).firstOrNull;
        if (existingItem != null) {
          final updatedItem = existingItem.copyWith(
            finalText: _captionController.text.trim(),
            customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
            tags: _selectedTags,
            rawTranscript: _savedImagePath ?? existingItem.rawTranscript,
            formattedContent: _savedImagePath ?? existingItem.formattedContent,
          );
          await appState.updateRecording(updatedItem);
        }
      } else {
        // Create new item
        final newItem = RecordingItem(
          id: const Uuid().v4(),
          rawTranscript: _savedImagePath ?? '', // Store image path in rawTranscript
          finalText: _captionController.text.trim(),
          presetUsed: 'Image',
          outcomes: [],
          projectId: widget.projectId,
          createdAt: DateTime.now(),
          editHistory: [],
          presetId: 'image',
          tags: _selectedTags,
          customTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          contentType: 'image',
          formattedContent: _savedImagePath, // Also store in formattedContent for display
        );

        await appState.saveRecording(newItem);

        // Track image document creation
        AnalyticsService().logCustomEvent(
          eventName: 'document_created',
          parameters: {
            'document_type': 'image',
            'source': widget.projectId != null ? 'project' : 'library',
            'creation_method': 'image',
            'has_caption': _captionController.text.isNotEmpty,
          },
        );
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.itemId != null ? 'Image updated' : 'Image saved'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTagSelectionDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TagSelectionDialog(
        selectedTagIds: _selectedTags,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            widget.itemId != null ? 'Edit Image' : 'New Image',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            // Tag button
            IconButton(
              onPressed: _showTagSelectionDialog,
              icon: Icon(
                Icons.label_outline,
                color: _selectedTags.isNotEmpty ? primaryColor : secondaryTextColor,
              ),
            ),
            // Save button
            TextButton(
              onPressed: _isLoading ? null : _saveImage,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tags display
                if (_selectedTags.isNotEmpty)
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      final tags = appState.tags;
                      final selectedTagObjects = _selectedTags
                          .map((tagId) => tags.where((t) => t.id == tagId).firstOrNull)
                          .where((t) => t != null)
                          .toList();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedTagObjects.map((tag) {
                            return TagChip(
                              tag: tag!,
                              isSelected: true,
                              onTap: () {
                                setState(() {
                                  _selectedTags.remove(tag.id);
                                  _hasUnsavedChanges = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                // Image display/picker
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  onPressed: _showImageSourceDialog,
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: _showImageSourceDialog,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 64,
                                color: secondaryTextColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to add image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gallery or Camera',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),

                // Title field
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Image title (optional)',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                
                const SizedBox(height: 16),

                // Caption field
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add a caption or description...',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

                const SizedBox(height: 16),

                // Status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedImage != null ? 'Image selected' : 'No image selected',
                      style: TextStyle(
                        color: _selectedImage != null ? const Color(0xFF10B981) : secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    if (_hasUnsavedChanges)
                      const Text(
                        'Unsaved changes',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}