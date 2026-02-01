import 'package:flutter/material.dart';
import '../constants/visual_constants.dart';

class BackgroundPickerDialog extends StatefulWidget {
  final String currentBackground;
  final Function(String) onSelect;

  const BackgroundPickerDialog({
    super.key,
    required this.currentBackground,
    required this.onSelect,
  });

  @override
  State<BackgroundPickerDialog> createState() => _BackgroundPickerDialogState();
}

class _BackgroundPickerDialogState extends State<BackgroundPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedId = widget.currentBackground;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final primaryColor = const Color(0xFF3B82F6);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose Background',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: primaryColor,
                    labelColor: primaryColor,
                    unselectedLabelColor: textColor.withOpacity(0.5),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Colors'),
                      Tab(text: 'Gradients'),
                      Tab(text: 'Textures'),
                      Tab(text: 'Images'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBackgroundGrid(BackgroundType.solidColor),
                  _buildBackgroundGrid(BackgroundType.gradient),
                  _buildBackgroundGrid(BackgroundType.texture),
                  _buildBackgroundGrid(BackgroundType.illustrated),
                ],
              ),
            ),
            
            // Apply button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedId != null
                      ? () => widget.onSelect(_selectedId!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: primaryColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Apply Background',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGrid(BackgroundType type) {
    final backgrounds = VisualConstants.getByType(type);
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: backgrounds.length,
      itemBuilder: (context, index) {
        final background = backgrounds[index];
        final isSelected = _selectedId == background.id;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedId = background.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                children: [
                  // Background preview
                  Positioned.fill(
                    child: background.buildBackground(context),
                  ),
                  
                  // Overlay for better text visibility
                  if (type == BackgroundType.solidColor &&
                      (background.primaryColor?.computeLuminance() ?? 0) < 0.5)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  
                  // Name label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        background.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  
                  // Selected checkmark
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
