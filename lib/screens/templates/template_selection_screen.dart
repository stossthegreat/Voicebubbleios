import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_templates.dart';
import 'template_fill_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<DocumentTemplate> get _filteredTemplates {
    var templates = _selectedCategory == 'All'
        ? AppTemplates.all
        : AppTemplates.getByCategory(_selectedCategory);

    if (_searchQuery.isNotEmpty) {
      templates = templates.where((t) {
        return t.name.toLowerCase().contains(_searchQuery) ||
            t.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF1A1A1A);
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Templates',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  style: const TextStyle(color: textColor, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Search templates...',
                    hintStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryChip('All', primaryColor, surfaceColor, textColor),
                  ...AppTemplates.categories.map((cat) => 
                    _buildCategoryChip(cat, primaryColor, surfaceColor, textColor)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Templates Grid
            Expanded(
              child: _filteredTemplates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: secondaryTextColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No templates found',
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = _filteredTemplates[index];
                        return _TemplateCard(
                          template: template,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TemplateFillScreen(template: template),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String category,
    Color primaryColor,
    Color surfaceColor,
    Color textColor,
  ) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : textColor.withOpacity(0.8),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: template.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    template.color.withOpacity(0.2),
                    template.color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: template.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      color: template.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (template.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        template.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Section count
                    Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.sections.length} sections',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
