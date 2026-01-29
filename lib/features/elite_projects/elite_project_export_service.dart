// ============================================================================
// ELITE PROJECT EXPORT SERVICE
// ============================================================================
// Professional exports that ACTUALLY WORK
// Unlike Scrivener's broken compile that makes users cry
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'elite_project_models.dart';

class EliteProjectExportService {
  
  // ============================================================================
  // MAIN EXPORT METHODS
  // ============================================================================

  /// Export project to specified format
  static Future<String?> exportProject(
    EliteProject project,
    ExportFormat format, {
    List<String>? sectionIds,  // Export specific sections only
    Map<String, String>? contentMap,  // Section ID -> content
  }) async {
    switch (format) {
      case ExportFormat.markdown:
        return await _exportMarkdown(project, contentMap);
      case ExportFormat.txt:
        return await _exportPlainText(project, contentMap);
      case ExportFormat.html:
        return await _exportHTML(project, contentMap);
      case ExportFormat.epub:
        return await _exportEPUB(project, contentMap);
      case ExportFormat.pdf:
        return await _exportPDF(project, contentMap);
      case ExportFormat.docx:
        return await _exportDOCX(project, contentMap);
      case ExportFormat.showNotes:
        return await _exportShowNotes(project, contentMap);
      case ExportFormat.transcript:
        return await _exportTranscript(project, contentMap);
      case ExportFormat.script:
        return await _exportVideoScript(project, contentMap);
      case ExportFormat.description:
        return await _exportVideoDescription(project, contentMap);
      case ExportFormat.latex:
        return await _exportLaTeX(project, contentMap);
      default:
        return await _exportMarkdown(project, contentMap);
    }
  }

  // ============================================================================
  // MARKDOWN EXPORT
  // ============================================================================

  static Future<String?> _exportMarkdown(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln('# ${project.name}');
    if (project.subtitle != null) {
      buffer.writeln('*${project.subtitle}*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    _writeTOCMarkdown(buffer, project.structure.sections, 0);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Content
    _writeContentMarkdown(buffer, project.structure.sections, contentMap, 2);
    
    // Save file
    return await _saveExportFile(
      project,
      buffer.toString(),
      'md',
    );
  }

  static void _writeTOCMarkdown(
    StringBuffer buffer,
    List<ProjectSection> sections,
    int depth,
  ) {
    for (final section in sections) {
      final indent = '  ' * depth;
      final anchor = section.title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
      buffer.writeln('$indent- [${section.title}](#$anchor)');
      if (section.children.isNotEmpty) {
        _writeTOCMarkdown(buffer, section.children, depth + 1);
      }
    }
  }

  static void _writeContentMarkdown(
    StringBuffer buffer,
    List<ProjectSection> sections,
    Map<String, String>? contentMap,
    int headingLevel,
  ) {
    for (final section in sections) {
      final heading = '#' * headingLevel;
      buffer.writeln('$heading ${section.title}');
      buffer.writeln();
      
      if (section.description != null) {
        buffer.writeln('*${section.description}*');
        buffer.writeln();
      }
      
      // Section content
      final content = contentMap?[section.id];
      if (content != null && content.isNotEmpty) {
        buffer.writeln(content);
        buffer.writeln();
      }
      
      // Child sections
      if (section.children.isNotEmpty) {
        _writeContentMarkdown(buffer, section.children, contentMap, headingLevel + 1);
      }
      
      buffer.writeln();
    }
  }

  // ============================================================================
  // PLAIN TEXT EXPORT
  // ============================================================================

  static Future<String?> _exportPlainText(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln(project.name.toUpperCase());
    if (project.subtitle != null) {
      buffer.writeln(project.subtitle);
    }
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Content
    _writeContentPlainText(buffer, project.structure.sections, contentMap, 0);
    
    return await _saveExportFile(project, buffer.toString(), 'txt');
  }

  static void _writeContentPlainText(
    StringBuffer buffer,
    List<ProjectSection> sections,
    Map<String, String>? contentMap,
    int depth,
  ) {
    for (final section in sections) {
      final indent = '  ' * depth;
      buffer.writeln('$indent${section.title}');
      buffer.writeln('$indent${'-' * section.title.length}');
      buffer.writeln();
      
      final content = contentMap?[section.id];
      if (content != null && content.isNotEmpty) {
        // Indent content
        final lines = content.split('\n');
        for (final line in lines) {
          buffer.writeln('$indent$line');
        }
        buffer.writeln();
      }
      
      if (section.children.isNotEmpty) {
        _writeContentPlainText(buffer, section.children, contentMap, depth + 1);
      }
    }
  }

  // ============================================================================
  // HTML EXPORT
  // ============================================================================

  static Future<String?> _exportHTML(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${_escapeHtml(project.name)}</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_getHTMLStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <article>');
    buffer.writeln('    <header>');
    buffer.writeln('      <h1>${_escapeHtml(project.name)}</h1>');
    if (project.subtitle != null) {
      buffer.writeln('      <p class="subtitle">${_escapeHtml(project.subtitle!)}</p>');
    }
    buffer.writeln('    </header>');
    buffer.writeln();
    
    // Table of contents
    buffer.writeln('    <nav class="toc">');
    buffer.writeln('      <h2>Table of Contents</h2>');
    buffer.writeln('      <ul>');
    _writeTOCHTML(buffer, project.structure.sections);
    buffer.writeln('      </ul>');
    buffer.writeln('    </nav>');
    buffer.writeln();
    
    // Content
    buffer.writeln('    <main>');
    _writeContentHTML(buffer, project.structure.sections, contentMap, 2);
    buffer.writeln('    </main>');
    buffer.writeln();
    buffer.writeln('  </article>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return await _saveExportFile(project, buffer.toString(), 'html');
  }

  static String _getHTMLStyles() {
    return '''
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { 
      font-family: 'Georgia', serif; 
      line-height: 1.7; 
      max-width: 800px; 
      margin: 0 auto; 
      padding: 40px 20px;
      color: #333;
      background: #fafafa;
    }
    article { background: white; padding: 60px; border-radius: 8px; box-shadow: 0 2px 20px rgba(0,0,0,0.1); }
    header { text-align: center; margin-bottom: 40px; padding-bottom: 40px; border-bottom: 1px solid #eee; }
    h1 { font-size: 2.5em; margin-bottom: 10px; color: #1a1a1a; }
    .subtitle { font-style: italic; color: #666; font-size: 1.2em; }
    h2 { font-size: 1.8em; margin: 40px 0 20px; color: #2a2a2a; }
    h3 { font-size: 1.4em; margin: 30px 0 15px; color: #3a3a3a; }
    h4 { font-size: 1.2em; margin: 25px 0 12px; color: #4a4a4a; }
    p { margin-bottom: 1em; }
    .toc { margin: 30px 0; padding: 20px; background: #f5f5f5; border-radius: 8px; }
    .toc h2 { margin: 0 0 15px; font-size: 1.2em; }
    .toc ul { list-style: none; }
    .toc li { margin: 8px 0; }
    .toc a { color: #6366f1; text-decoration: none; }
    .toc a:hover { text-decoration: underline; }
    .section { margin-bottom: 40px; }
    .section-description { font-style: italic; color: #666; margin-bottom: 15px; }
    ''';
  }

  static void _writeTOCHTML(StringBuffer buffer, List<ProjectSection> sections) {
    for (final section in sections) {
      final anchor = section.title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
      buffer.writeln('        <li><a href="#$anchor">${_escapeHtml(section.title)}</a>');
      if (section.children.isNotEmpty) {
        buffer.writeln('          <ul>');
        _writeTOCHTML(buffer, section.children);
        buffer.writeln('          </ul>');
      }
      buffer.writeln('        </li>');
    }
  }

  static void _writeContentHTML(
    StringBuffer buffer,
    List<ProjectSection> sections,
    Map<String, String>? contentMap,
    int level,
  ) {
    for (final section in sections) {
      final anchor = section.title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
      final tag = 'h${level.clamp(1, 6)}';
      
      buffer.writeln('      <section class="section" id="$anchor">');
      buffer.writeln('        <$tag>${_escapeHtml(section.title)}</$tag>');
      
      if (section.description != null) {
        buffer.writeln('        <p class="section-description">${_escapeHtml(section.description!)}</p>');
      }
      
      final content = contentMap?[section.id];
      if (content != null && content.isNotEmpty) {
        // Convert paragraphs
        final paragraphs = content.split('\n\n');
        for (final para in paragraphs) {
          if (para.trim().isNotEmpty) {
            buffer.writeln('        <p>${_escapeHtml(para.trim())}</p>');
          }
        }
      }
      
      if (section.children.isNotEmpty) {
        _writeContentHTML(buffer, section.children, contentMap, level + 1);
      }
      
      buffer.writeln('      </section>');
    }
  }

  // ============================================================================
  // EPUB EXPORT (Novel-specific)
  // ============================================================================

  static Future<String?> _exportEPUB(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    // For now, export as HTML which can be converted
    // TODO: Implement full EPUB generation with mimetype, META-INF, OEBPS structure
    
    final html = await _exportHTML(project, contentMap);
    // Return path to HTML file - user can use Calibre or similar to convert
    return html;
  }

  // ============================================================================
  // PDF EXPORT
  // ============================================================================

  static Future<String?> _exportPDF(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    // Export as HTML for now - can use printing package for PDF
    // TODO: Implement PDF generation with pdf package
    return await _exportHTML(project, contentMap);
  }

  // ============================================================================
  // DOCX EXPORT
  // ============================================================================

  static Future<String?> _exportDOCX(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    // Export as Markdown/HTML - can be opened in Word
    // TODO: Implement DOCX generation with docx package
    return await _exportMarkdown(project, contentMap);
  }

  // ============================================================================
  // PODCAST-SPECIFIC EXPORTS
  // ============================================================================

  static Future<String?> _exportShowNotes(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${project.name} - Show Notes');
    buffer.writeln();
    
    for (final section in project.structure.sections) {
      if (section.title.toLowerCase().contains('episode')) {
        buffer.writeln('## ${section.title}');
        buffer.writeln();
        
        for (final child in section.children) {
          if (child.title.toLowerCase().contains('show notes') ||
              child.title.toLowerCase().contains('notes')) {
            final content = contentMap?[child.id];
            if (content != null) {
              buffer.writeln(content);
              buffer.writeln();
            }
          }
        }
        
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    
    return await _saveExportFile(project, buffer.toString(), 'md');
  }

  static Future<String?> _exportTranscript(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('TRANSCRIPT: ${project.name}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final section in project.structure.sections) {
      buffer.writeln('[${section.title}]');
      buffer.writeln();
      
      final content = contentMap?[section.id];
      if (content != null) {
        buffer.writeln(content);
        buffer.writeln();
      }
      
      for (final child in section.children) {
        final childContent = contentMap?[child.id];
        if (childContent != null) {
          buffer.writeln(childContent);
          buffer.writeln();
        }
      }
    }
    
    return await _saveExportFile(project, buffer.toString(), 'txt');
  }

  // ============================================================================
  // YOUTUBE-SPECIFIC EXPORTS
  // ============================================================================

  static Future<String?> _exportVideoScript(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('VIDEO SCRIPT: ${project.name}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final section in project.structure.sections) {
      if (section.title.toLowerCase().contains('video')) {
        buffer.writeln('### ${section.title} ###');
        buffer.writeln();
        
        for (final child in section.children) {
          if (child.title.toLowerCase().contains('hook') ||
              child.title.toLowerCase().contains('script') ||
              child.title.toLowerCase().contains('content')) {
            buffer.writeln('[${child.title}]');
            final content = contentMap?[child.id];
            if (content != null) {
              buffer.writeln(content);
            }
            buffer.writeln();
          }
        }
        
        buffer.writeln('-' * 30);
        buffer.writeln();
      }
    }
    
    return await _saveExportFile(project, buffer.toString(), 'txt');
  }

  static Future<String?> _exportVideoDescription(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    for (final section in project.structure.sections) {
      if (section.title.toLowerCase().contains('video')) {
        buffer.writeln('=== ${section.title} ===');
        buffer.writeln();
        
        for (final child in section.children) {
          if (child.title.toLowerCase().contains('description')) {
            final content = contentMap?[child.id];
            if (content != null) {
              buffer.writeln(content);
            }
            buffer.writeln();
          }
        }
        
        buffer.writeln();
      }
    }
    
    return await _saveExportFile(project, buffer.toString(), 'txt');
  }

  // ============================================================================
  // LATEX EXPORT (Research)
  // ============================================================================

  static Future<String?> _exportLaTeX(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    final buffer = StringBuffer();
    
    // Document preamble
    buffer.writeln(r'\documentclass[12pt,a4paper]{article}');
    buffer.writeln(r'\usepackage[utf8]{inputenc}');
    buffer.writeln(r'\usepackage[margin=1in]{geometry}');
    buffer.writeln(r'\usepackage{hyperref}');
    buffer.writeln(r'\usepackage{setspace}');
    buffer.writeln(r'\doublespacing');
    buffer.writeln();
    buffer.writeln(r'\title{' + _escapeLatex(project.name) + r'}');
    if (project.subtitle != null) {
      buffer.writeln(r'\author{' + _escapeLatex(project.subtitle!) + r'}');
    }
    buffer.writeln(r'\date{\today}');
    buffer.writeln();
    buffer.writeln(r'\begin{document}');
    buffer.writeln();
    buffer.writeln(r'\maketitle');
    buffer.writeln();
    buffer.writeln(r'\tableofcontents');
    buffer.writeln(r'\newpage');
    buffer.writeln();
    
    // Content
    _writeContentLaTeX(buffer, project.structure.sections, contentMap, 0);
    
    buffer.writeln();
    buffer.writeln(r'\end{document}');
    
    return await _saveExportFile(project, buffer.toString(), 'tex');
  }

  static void _writeContentLaTeX(
    StringBuffer buffer,
    List<ProjectSection> sections,
    Map<String, String>? contentMap,
    int depth,
  ) {
    final commands = [r'\section', r'\subsection', r'\subsubsection', r'\paragraph'];
    final command = commands[depth.clamp(0, commands.length - 1)];
    
    for (final section in sections) {
      buffer.writeln('$command{${_escapeLatex(section.title)}}');
      buffer.writeln();
      
      final content = contentMap?[section.id];
      if (content != null && content.isNotEmpty) {
        buffer.writeln(_escapeLatex(content));
        buffer.writeln();
      }
      
      if (section.children.isNotEmpty) {
        _writeContentLaTeX(buffer, section.children, contentMap, depth + 1);
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  static Future<String?> _saveExportFile(
    EliteProject project,
    String content,
    String extension,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/VoiceBubble/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = project.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filename = '${safeName}_$timestamp.$extension';
      final file = File('${exportDir.path}/$filename');
      
      await file.writeAsString(content);
      
      return file.path;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static String _escapeLatex(String text) {
    return text
        .replaceAll(r'\', r'\textbackslash{}')
        .replaceAll('&', r'\&')
        .replaceAll('%', r'\%')
        .replaceAll(r'$', r'\$')
        .replaceAll('#', r'\#')
        .replaceAll('_', r'\_')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}')
        .replaceAll('~', r'\textasciitilde{}')
        .replaceAll('^', r'\textasciicircum{}');
  }

  // ============================================================================
  // PLATFORM-SPECIFIC EXPORTS
  // ============================================================================

  /// Generate Teachable-compatible course export
  static Future<Map<String, dynamic>?> exportForTeachable(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    if (project.type != EliteProjectType.course) return null;
    
    final modules = <Map<String, dynamic>>[];
    
    for (final section in project.structure.sections) {
      final lessons = <Map<String, dynamic>>[];
      
      for (final child in section.children) {
        lessons.add({
          'title': child.title,
          'description': child.description ?? '',
          'content': contentMap?[child.id] ?? '',
          'type': 'text',
        });
      }
      
      modules.add({
        'title': section.title,
        'description': section.description ?? '',
        'lessons': lessons,
      });
    }
    
    return {
      'course': {
        'title': project.name,
        'subtitle': project.subtitle ?? '',
        'modules': modules,
      },
      'exportedAt': DateTime.now().toIso8601String(),
      'format': 'teachable',
    };
  }

  /// Generate Substack-compatible newsletter export
  static Future<String?> exportForSubstack(
    EliteProject project,
    Map<String, String>? contentMap,
  ) async {
    // Substack accepts Markdown with some specific formatting
    return await _exportMarkdown(project, contentMap);
  }
}
