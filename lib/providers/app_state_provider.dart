import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/archived_item.dart';
import '../models/recording_item.dart';
import '../models/project.dart';
import '../models/continue_context.dart';
import '../models/preset.dart';
import '../models/tag.dart';
import '../constants/languages.dart';
import '../services/subscription_service.dart';
import '../services/tag_service.dart';
import '../services/language_service.dart';
import '../services/reminder_manager.dart';

class AppStateProvider extends ChangeNotifier {
  String _transcription = '';
  String _rewrittenText = '';
  Preset? _selectedPreset;
  Language _selectedLanguage = AppLanguages.defaultLanguage;
  bool _isRecording = false;
  bool _isProcessing = false;
  List<ArchivedItem> _archivedItems = [];
  List<RecordingItem> _recordingItems = [];
  List<Project> _projects = [];
  List<Tag> _tags = [];
  ContinueContext? _continueContext;
  bool _isPremium = false;
  DateTime? _subscriptionExpiry;
  String? _subscriptionType; // 'monthly' or 'yearly'
  
  // Getters
  String get transcription => _transcription;
  String get rewrittenText => _rewrittenText;
  Preset? get selectedPreset => _selectedPreset;
  Language get selectedLanguage => _selectedLanguage;
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  List<ArchivedItem> get archivedItems => _archivedItems;
  List<RecordingItem> get recordingItems => _recordingItems.where((item) => !item.hiddenInLibrary).toList();
  List<RecordingItem> get allRecordingItems => _recordingItems;

  List<RecordingItem> get outcomesItems => _recordingItems.where((item) => !item.hiddenInOutcomes).toList();
List<Project> get projects => _projects;
List<Tag> get tags => _tags;
ContinueContext? get continueContext => _continueContext;
  bool get isPremium => _isPremium;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  String? get subscriptionType => _subscriptionType;
  
  // Initialize and load archived items from Hive
  Future<void> initialize() async {
    // Make sure we wait for everything to load before returning
    try {
      await _loadArchivedItems();
      await _loadRecordingItems();
      await _loadProjects();
      await _loadTags();
      await _loadSavedLanguage(); // 🔥 Load saved language preference
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint('ERROR in initialize: $e');
    }
  }
  
  /// Load saved language preference from storage
  Future<void> _loadSavedLanguage() async {
    try {
      final languageCode = await LanguageService.getSelectedLanguage();
      final language = AppLanguages.all.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => AppLanguages.defaultLanguage,
      );
      _selectedLanguage = language;
      debugPrint('✅ Loaded saved language: ${language.name} (${language.code})');
    } catch (e) {
      debugPrint('❌ Error loading saved language: $e');
      _selectedLanguage = AppLanguages.defaultLanguage;
    }
  }
  
  /// Check and update subscription status from Firebase
  Future<void> checkSubscriptionStatus() async {
    try {
      final subscriptionService = SubscriptionService();
      final hasActive = await subscriptionService.hasActiveSubscription();
      _isPremium = hasActive;
      
      debugPrint('📊 Subscription status checked: isPremium = $_isPremium');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error checking subscription status: $e');
    }
  }
  
  void setSubscriptionStatus({
    required bool isPremium,
    DateTime? expiry,
    String? type,
  }) {
    _isPremium = isPremium;
    _subscriptionExpiry = expiry;
    _subscriptionType = type;
    debugPrint('💎 Subscription updated: isPremium=$isPremium, type=$type, expiry=$expiry');
    notifyListeners();
  }
  
  Future<void> _loadArchivedItems() async {
    final box = await Hive.openBox<ArchivedItem>('archived_items');
    _archivedItems = box.values.toList();
    _archivedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }
  
  Future<void> _loadRecordingItems() async {
    try {
      final box = await Hive.openBox<RecordingItem>('recording_items');
      _recordingItems = box.values.toList();
      _recordingItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('📚 Loaded ${_recordingItems.length} recording items from Hive');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _loadRecordingItems: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  Future<void> _loadProjects() async {
    try {
      final box = await Hive.openBox<Project>('projects');
      _projects = box.values.toList();
      _projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      debugPrint('📚 Loaded ${_projects.length} projects from Hive');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in _loadProjects: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  Future<void> _loadTags() async {
    try {
      final tagService = TagService();
      _tags = await tagService.getAllTags();
      debugPrint('🏷️ Loaded ${_tags.length} tags');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ ERROR in _loadTags: $e');
    }
  }
  
  void setTranscription(String text) {
    debugPrint('📝 setTranscription called with: "${text.length > 50 ? text.substring(0, 50) : text}..." (${text.length} chars)');
    _transcription = text;
    debugPrint('📝 _transcription is now: "${_transcription.length > 50 ? _transcription.substring(0, 50) : _transcription}..."');
    notifyListeners();
  }
  
  void setRewrittenText(String text) {
    _rewrittenText = text;
    notifyListeners();
  }
  
  void setSelectedPreset(Preset? preset) {
    _selectedPreset = preset;
    notifyListeners();
  }
  
  void setSelectedLanguage(Language language) async {
    _selectedLanguage = language;
    notifyListeners();
    // 🔥 Save language preference to storage
    await LanguageService.saveSelectedLanguage(language.code);
    debugPrint('💾 Saved language preference: ${language.name} (${language.code})');
  }
  
  void setRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }
  
  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
  
  Future<void> saveToArchive(ArchivedItem item) async {
    final box = await Hive.openBox<ArchivedItem>('archived_items');
    await box.add(item);
    await _loadArchivedItems();
  }
  
  // NEW: Save recording with new model (preferred method)
  Future<void> saveRecording(RecordingItem item) async {
    try {
      debugPrint('💾 saveRecording called for item: ${item.id}');
      
      final box = await Hive.openBox<RecordingItem>('recording_items');
      debugPrint('💾 Box opened, current items: ${box.length}');
      
      await box.add(item);
      debugPrint('💾 Item added to box, new count: ${box.length}');
      
      await _loadRecordingItems();
      debugPrint('💾 Items loaded, _recordingItems count: ${_recordingItems.length}');
      
      // Also save to old format for backward compatibility
      final archivedItem = ArchivedItem(
        id: item.id,
        presetName: item.presetUsed,
        originalText: item.rawTranscript,
        rewrittenText: item.finalText,
        timestamp: item.createdAt,
      );
      await saveToArchive(archivedItem);
      
      debugPrint('✅ Recording saved to both stores successfully');
      debugPrint('✅ recordingItems getter returns: ${recordingItems.length} items');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in saveRecording: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  // Update an existing recording
  Future<void> updateRecording(RecordingItem item) async {
    final box = await Hive.openBox<RecordingItem>('recording_items');
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.id == item.id,
      orElse: () => null,
    );
    if (key != null) {
      await box.put(key, item);
      await _loadRecordingItems();
      debugPrint('📝 Recording updated: ${item.id}');
    }
  }
  
  Future<void> deleteFromArchive(String id) async {
    final box = await Hive.openBox<ArchivedItem>('archived_items');
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.id == id,
      orElse: () => null,
    );
    if (key != null) {
      await box.delete(key);
      await _loadArchivedItems();
    }
  }
  
  Future<void> hideInLibrary(String id) async {
    final item = _recordingItems.firstWhere((item) => item.id == id);
    final updatedItem = item.copyWith(hiddenInLibrary: true);
    await updateRecording(updatedItem);
  }
  
  Future<void> hideInOutcomes(String id) async {
    final item = _recordingItems.firstWhere((item) => item.id == id);
    final updatedItem = item.copyWith(hiddenInOutcomes: true);
    await updateRecording(updatedItem);
  }
  
  // Tag Management
  Future<void> addTagToRecording(String recordingId, String tagId) async {
    try {
      final index = _recordingItems.indexWhere((item) => item.id == recordingId);
      if (index != -1) {
        final item = _recordingItems[index];
        if (!item.tags.contains(tagId)) {
          final updatedItem = item.copyWith(
            tags: [...item.tags, tagId],
          );
          _recordingItems[index] = updatedItem;
          
          // Save to Hive
          final box = await Hive.openBox<RecordingItem>('recording_items');
          await box.put(updatedItem.id, updatedItem);
          
          debugPrint('🏷️ Added tag $tagId to recording $recordingId');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error adding tag: $e');
    }
  }
  
  Future<void> removeTagFromRecording(String recordingId, String tagId) async {
    try {
      final index = _recordingItems.indexWhere((item) => item.id == recordingId);
      if (index != -1) {
        final item = _recordingItems[index];
        final updatedTags = item.tags.where((t) => t != tagId).toList();
        final updatedItem = item.copyWith(tags: updatedTags);
        _recordingItems[index] = updatedItem;
        
        // Save to Hive
        final box = await Hive.openBox<RecordingItem>('recording_items');
        await box.put(updatedItem.id, updatedItem);
        
        debugPrint('🏷️ Removed tag $tagId from recording $recordingId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error removing tag: $e');
    }
  }
  
  List<RecordingItem> getRecordingsByTag(String tagId) {
    return _recordingItems.where((item) => 
      !item.hiddenInLibrary && item.tags.contains(tagId)
    ).toList();
  }
  
  Future<void> refreshTags() async {
    await _loadTags();
  }
  
  // Keep the old deleteRecording for permanent deletion when needed
  Future<void> deleteRecording(String id) async {
    final box = await Hive.openBox<RecordingItem>('recording_items');
    final key = box.keys.firstWhere(
      (k) => box.get(k)?.id == id,
      orElse: () => null,
    );
    if (key != null) {
      // Cancel any scheduled reminder before deleting
      final item = box.get(key);
      if (item != null) {
        await ReminderManager().cancelReminderForDeletedItem(item);
      }
      
      await box.delete(key);
      await _loadRecordingItems();
      debugPrint('🗑️ Recording deleted: $id');
    }
  }
  
  Future<void> clearArchive() async {
    final box = await Hive.openBox<ArchivedItem>('archived_items');
    await box.clear();
    _archivedItems = [];
    
    final recordingBox = await Hive.openBox<RecordingItem>('recording_items');
    await recordingBox.clear();
    _recordingItems = [];
    
    final projectBox = await Hive.openBox<Project>('projects');
    await projectBox.clear();
    _projects = [];
    
    notifyListeners();
  }
  
  // Project management methods
  Future<void> saveProject(Project project) async {
    final box = await Hive.openBox<Project>('projects');
    await box.put(project.id, project);
    await _loadProjects();
    notifyListeners();
  }
  
  Future<void> deleteProject(String id) async {
    final box = await Hive.openBox<Project>('projects');
    await box.delete(id);
    await _loadProjects();
    notifyListeners();
  }
  
  Future<void> addItemToProject(String projectId, String itemId) async {
    final projectBox = await Hive.openBox<Project>('projects');
    final project = projectBox.get(projectId);
    
    if (project != null && !project.itemIds.contains(itemId)) {
      final updatedProject = project.copyWith(
        itemIds: [...project.itemIds, itemId],
        updatedAt: DateTime.now(),
      );
      await projectBox.put(projectId, updatedProject);
      
      // Update recording item
      final recordingBox = await Hive.openBox<RecordingItem>('recording_items');
      for (final key in recordingBox.keys) {
        final item = recordingBox.get(key);
        if (item?.id == itemId) {
          final updatedItem = item!.copyWith(projectId: projectId);
          await recordingBox.put(key, updatedItem);
          break;
        }
      }
      
      await _loadProjects();
      await _loadRecordingItems();
      notifyListeners();
    }
  }
  
  // Continue context management
  void setContinueContext(ContinueContext? context) {
    _continueContext = context;
    notifyListeners();
  }
  
  void clearContinueContext() {
    _continueContext = null;
    notifyListeners();
  }
  
  void reset() {
    debugPrint('🔄 RESET called! Clearing transcription: "${_transcription.length > 30 ? _transcription.substring(0, 30) : _transcription}..."');
    debugPrint('🔄 Stack trace: ${StackTrace.current.toString().split('\n').take(5).join('\n')}');
    _transcription = '';
    _rewrittenText = '';
    _selectedPreset = null;
    _isRecording = false;
    _isProcessing = false;
    notifyListeners();
  }
}

