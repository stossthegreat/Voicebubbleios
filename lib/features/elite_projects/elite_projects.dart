// ============================================================================
// ELITE PROJECTS - MASTER EXPORT
// ============================================================================
// Single import to get everything:
// import 'package:your_app/features/elite_projects/elite_projects.dart';
// ============================================================================

// Core models and types
export 'elite_project_models.dart';

// Data persistence
export 'elite_project_adapters.dart';

// Templates (21 templates for 9 project types)
export 'elite_project_templates.dart';

// AI Context Service (memory, presets, continuation)
export 'elite_project_ai_service.dart';

// Project CRUD and state management
export 'elite_project_service.dart';

// Voice recording integration
export 'elite_project_voice_service.dart';

// Export service (Markdown, HTML, EPUB, etc.)
export 'elite_project_export_service.dart';

// Main router and integration
export 'elite_projects_router.dart';

// ============================================================================
// SCREENS
// ============================================================================

// Project selection/gallery screen
export 'elite_project_selection_screen.dart';

// Original workspace screen
export 'elite_project_workspace_screen.dart';

// NEW: Elite workspace (integrates with flutter_quill)
export 'elite_workspace.dart';

// Section editor screen
export 'elite_project_section_editor.dart';

// Project creation wizard
export 'elite_project_creation_wizard.dart';

// Statistics and progress screen
export 'elite_project_statistics_screen.dart';

// AI memory editor screen
export 'elite_project_memory_editor.dart';

// ============================================================================
// INTEGRATION WIDGETS (drop into existing screens)
// ============================================================================

// Library tab with projects
export 'library_projects_tab.dart';

// "Add to Project" button for output page
export 'add_to_project_widget.dart';

// "Move to Project" for library recordings
export 'move_to_project_widget.dart';

// Recording context widgets
export 'project_recording_widgets.dart';

// ============================================================================
// QUICK START
// ============================================================================
/*

1. INITIALIZE (in main.dart):
   
   import 'package:your_app/features/elite_projects/elite_projects.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Hive.initFlutter();
     
     // Register adapters (use IDs that don't conflict with yours)
     registerEliteProjectAdapters();
     
     // Initialize router
     await eliteProjects.initialize();
     
     runApp(MyApp());
   }

2. ADD TO LIBRARY TAB:

   LibraryProjectsTab(
     projectService: eliteProjects.projectService,
     onProjectTap: (project) {
       Navigator.push(context, MaterialPageRoute(
         builder: (_) => EliteWorkspace(
           project: project,
           projectService: eliteProjects.projectService,
           onRecordPressed: () {
             // Open your recording screen
           },
         ),
       ));
     },
     onCreateProject: () {
       Navigator.push(context, eliteProjects.creationWizardScreen(context));
     },
   )

3. ADD TO OUTPUT PAGE (after recording):

   AddToProjectButton(
     projectService: eliteProjects.projectService,
     content: enhancedText,
     recordingId: recording.id,
   )

4. ADD TO RECORDING SCREEN (show context):

   ProjectRecordingContext(
     project: currentProject,
     section: currentSection,
   )

5. CONNECT AI PRESETS:

   eliteProjects.onAIPresetRequested = (context, presetId, aiContext, project) {
     // aiContext contains EVERYTHING: project info, characters, facts, style
     // Send to your AI backend
     yourAIService.generate(systemPrompt: aiContext, ...);
   };

*/
