import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_template.dart';
import '../../services/template_service.dart';
import '../../providers/app_state_provider.dart';
import 'template_fill_screen.dart';

// ============================================================
//        TEMPLATE SELECTION SCREEN
// ============================================================
//
// Elite template browser with instant access to productivity.
// Beautiful, fast, and powerful template selection.
//
// ============================================================

class TemplateSelectionScreen extends StatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen>
    with TickerProviderStateMixin {
  final _templateService = TemplateService();
  final _searchController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Business', 'Creative', 'Personal', 'Marketing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF000000);
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Templates',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Professional structures for instant productivity',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search templates...',
                        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Category tabs
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: textColor.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onTap: (index) {
                  setState(() {
                    _selectedCategory = _categories[index];
                  });
                },
                tabs: _categories.map((category) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(category),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Templates grid
            Expanded(
              child: _buildTemplatesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    List<DocumentTemplate> templates;
    
    if (_searchQuery.isNotEmpty) {
      templates = _templateService.searchTemplates(_searchQuery);
    } else if (_selectedCategory == 'All') {
      templates = _templateService.getAllTemplates();
    } else {
      templates = _templateService.getTemplatesByCategory(_selectedCategory);
    }

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          return _buildTemplateCard(templates[index]);
        },
      ),
    );
  }

  Widget _buildTemplateCard(DocumentTemplate template) {
    final surfaceColor = const Color(0xFF1A1A1A);
    final textColor = Colors.white;
    final primaryColor = const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and premium badge
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        template.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (template.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Footer with time estimate
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.estimatedMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _selectTemplate(DocumentTemplate template) {
    // Check if premium template and user has access
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    if (template.isPremium && !appState.isProUser) {
      _showPremiumDialog(template);
      return;
    }

    // Navigate to template fill screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateFillScreen(template: template),
      ),
    );
  }

  void _showPremiumDialog(DocumentTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(
              template.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Premium Template',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This professional template is available with VoiceBubble Pro.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VoiceBubble Pro includes:',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• All premium templates\n• Unlimited voice minutes\n• Advanced AI features\n• Priority support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
              // TODO: Implement navigation to paywall
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upgrade to Pro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}