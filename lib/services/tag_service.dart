import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import 'analytics_service.dart';

class TagService {
  static const String _boxName = 'tags';
  final Uuid _uuid = const Uuid();

  Future<Box<Tag>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Tag>(_boxName);
    }
    return Hive.box<Tag>(_boxName);
  }

  Future<Tag> createTag(String name, int color) async {
    final box = await _getBox();
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
    await box.put(tag.id, tag);
    AnalyticsService().logCustomEvent(
      eventName: 'tag_created',
      parameters: {'tag_name_length': name.length},
    );
    return tag;
  }

  Future<List<Tag>> getAllTags() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<Tag?> getTagById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  Future<void> updateTag(String id, String name, int color) async {
    final box = await _getBox();
    final tag = box.get(id);
    if (tag != null) {
      final updatedTag = tag.copyWith(name: name, color: color);
      await box.put(id, updatedTag);
    }
  }

  Future<void> deleteTag(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<bool> tagExists(String name) async {
    final tags = await getAllTags();
    return tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase());
  }
}
