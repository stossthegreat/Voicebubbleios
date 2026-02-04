import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recording_item.dart';

class ExportService {
  // Export as plain text
  Future<File> exportAsText(RecordingItem note) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _sanitizeFileName(note.customTitle ?? 'note');
    final file = File('${directory.path}/$fileName.txt');
    
    await file.writeAsString(note.finalText);
    return file;
  }

  // Export as Markdown
  Future<File> exportAsMarkdown(RecordingItem note) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _sanitizeFileName(note.customTitle ?? 'note');
    final file = File('${directory.path}/$fileName.md');
    
    // Get text content - prefer finalText, fallback to formattedContent conversion
    String textContent = note.finalText;
    if (textContent.isEmpty && note.formattedContent != null) {
      // TODO: Convert Quill Delta to plain text if needed
      textContent = note.formattedContent!;
    }
    
    if (textContent.isEmpty) {
      textContent = 'No content available';
    }
    
    final markdown = '''# ${note.customTitle ?? 'Untitled'}

Created: ${note.formattedDate}
${note.tags.isNotEmpty ? 'Tags: ${note.tags.join(', ')}' : ''}

---

$textContent
''';
    
    await file.writeAsString(markdown);
    return file;
  }

  // Export as HTML
  Future<File> exportAsHtml(RecordingItem note) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _sanitizeFileName(note.customTitle ?? 'note');
    final file = File('${directory.path}/$fileName.html');
    
    final html = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${note.customTitle ?? 'Untitled'}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      max-width: 800px;
      margin: 40px auto;
      padding: 20px;
      line-height: 1.6;
      color: #333;
    }
    h1 {
      color: #2c3e50;
      border-bottom: 2px solid #3498db;
      padding-bottom: 10px;
    }
    .metadata {
      color: #7f8c8d;
      font-size: 14px;
      margin-bottom: 30px;
    }
    .content {
      white-space: pre-wrap;
    }
    .tags {
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #ecf0f1;
    }
    .tag {
      display: inline-block;
      background: #3498db;
      color: white;
      padding: 4px 12px;
      border-radius: 12px;
      margin-right: 8px;
      font-size: 13px;
    }
  </style>
</head>
<body>
  <h1>${note.customTitle ?? 'Untitled'}</h1>
  
  <div class="metadata">
    <p>Created: ${note.formattedDate}</p>
    ${note.presetUsed != 'Free Text' ? '<p>Type: ${note.presetUsed}</p>' : ''}
  </div>
  
  <div class="content">
${note.finalText}
  </div>
  
  ${note.tags.isNotEmpty ? '''
  <div class="tags">
    ${note.tags.map((tag) => '<span class="tag">$tag</span>').join('\n    ')}
  </div>
  ''' : ''}
</body>
</html>''';
    
    await file.writeAsString(html);
    return file;
  }

  // Export as PDF
  Future<File> exportAsPdf(RecordingItem note) async {
    final pdf = pw.Document();

    // Get text content - prefer finalText, fallback to formattedContent conversion
    String textContent = note.finalText;
    if (textContent.isEmpty && note.formattedContent != null) {
      // TODO: Convert Quill Delta to plain text if needed
      textContent = note.formattedContent!;
    }

    // Split content into paragraphs for proper pagination
    final paragraphs = textContent.isEmpty
        ? ['No content available']
        : textContent.split('\n').where((p) => p.trim().isNotEmpty).toList();

    // If no paragraphs after filtering, add placeholder
    if (paragraphs.isEmpty) {
      paragraphs.add('No content available');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                note.customTitle ?? 'Untitled',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            // Metadata
            pw.Text(
              'Created: ${note.formattedDate}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),

            if (note.presetUsed != 'Free Text')
              pw.Text(
                'Type: ${note.presetUsed}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),

            pw.SizedBox(height: 20),

            pw.Divider(),

            pw.SizedBox(height: 20),

            // Content - split into paragraphs for proper page breaks
            ...paragraphs.map((paragraph) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                paragraph,
                style: const pw.TextStyle(
                  fontSize: 12,
                  lineSpacing: 1.5,
                ),
              ),
            )),

            // Tags
            if (note.tags.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags.map((tag) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      tag,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _sanitizeFileName(note.customTitle ?? 'note');
    final file = File('${directory.path}/$fileName.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Share file after export
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Shared from VoiceBubble',
    );
  }

  // Helper to sanitize file names
  String _sanitizeFileName(String name) {
    // Remove special characters and limit length
    String sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    
    return sanitized.isEmpty ? 'note' : sanitized;
  }
}
