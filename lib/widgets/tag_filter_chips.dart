import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../widgets/tag_chip.dart';
import '../widgets/create_tag_dialog.dart';

class TagFilterChips extends StatefulWidget {
  final String? selectedTagId;
  final Function(String?) onTagSelected;

  const TagFilterChips({
    super.key,
    required this.selectedTagId,
    required this.onTagSelected,
  });

  @override
  State<TagFilterChips> createState() => _TagFilterChipsState();
}

class _TagFilterChipsState extends State<TagFilterChips> {
  final TagService _tagService = TagService();
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _tagService.getAllTags();
    setState(() {
      _tags = tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip
          _buildAllChip(),
          const SizedBox(width: 8),
          
          // Tag chips
          ..._tags.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TagChip(
              tag: tag,
              isSelected: widget.selectedTagId == tag.id,
              size: 'large',
              onTap: () => widget.onTagSelected(tag.id),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAllChip() {
    final isSelected = widget.selectedTagId == null;
    final color = const Color(0xFF64748B);
    
    return GestureDetector(
      onTap: () => widget.onTagSelected(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(isSelected ? 1.0 : 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              'All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final color = const Color(0xFF3B82F6);
    
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => const CreateTagDialog(),
        );
        if (result == true) {
          _loadTags(); // Reload tags after creation
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
