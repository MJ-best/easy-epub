/// Markdown to HTML parser for EPUB generation
class MarkdownParser {
  /// Convert markdown text to HTML with proper structure
  static String parseToHtml(String markdown) {
    final buffer = StringBuffer();
    final lines = markdown.split('\n');

    bool inParagraph = false;
    bool inList = false;
    bool inTable = false;
    String? currentListTag;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Empty line handling
      if (trimmed.isEmpty) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        if (inList) {
          buffer.writeln('</$currentListTag>');
          inList = false;
          currentListTag = null;
        }
        if (inTable) {
          buffer.writeln('</table>');
          inTable = false;
        }
        buffer.writeln('<p class="txt bl"><br/></p>');
        continue;
      }

      // Close list if switching contexts
      void closeListIfNeeded() {
        if (inList) {
          buffer.writeln('</$currentListTag>');
          inList = false;
          currentListTag = null;
        }
      }

      // Heading level 1
      if (trimmed.startsWith('# ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        closeListIfNeeded();
        buffer.writeln('<h1 class="h1">${_escapeHtml(trimmed.substring(2))}</h1>');
        continue;
      }

      // Heading level 2
      if (trimmed.startsWith('## ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        closeListIfNeeded();
        buffer.writeln('<h2 class="h2">${_escapeHtml(trimmed.substring(3))}</h2>');
        continue;
      }

      // Heading level 3
      if (trimmed.startsWith('### ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        closeListIfNeeded();
        buffer.writeln('<h3 class="h3">${_escapeHtml(trimmed.substring(4))}</h3>');
        continue;
      }

      // Unordered list
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        if (!inList || currentListTag != 'ul') {
          if (inList) {
            buffer.writeln('</$currentListTag>');
          }
          buffer.writeln('<ul class="list">');
          inList = true;
          currentListTag = 'ul';
        }
        buffer.writeln('<li>${_processInlineMarkdown(trimmed.substring(2))}</li>');
        continue;
      }

      // Ordered list
      if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        if (!inList || currentListTag != 'ol') {
          if (inList) {
            buffer.writeln('</$currentListTag>');
          }
          buffer.writeln('<ol class="list">');
          inList = true;
          currentListTag = 'ol';
        }
        final content = trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '');
        buffer.writeln('<li>${_processInlineMarkdown(content)}</li>');
        continue;
      }

      // Table
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        closeListIfNeeded();

        // Check if this is a separator line
        final isSeparator = RegExp(r'^\|[\s\-:|]+\|$').hasMatch(trimmed);

        if (!inTable && !isSeparator) {
          buffer.writeln('<table style="border-collapse: collapse; width: 100%; margin: 1em 0;">');
          buffer.writeln('<thead>');
          inTable = true;
        }

        if (isSeparator) {
          buffer.writeln('</thead>');
          buffer.writeln('<tbody>');
        } else {
          final cells = trimmed.split('|').where((c) => c.trim().isNotEmpty).toList();
          buffer.write('<tr>');
          for (final cell in cells) {
            final tag = inTable && buffer.toString().contains('</thead>') ? 'td' : 'th';
            buffer.write('<$tag style="border: 1px solid #ddd; padding: 8px;">${_processInlineMarkdown(cell.trim())}</$tag>');
          }
          buffer.writeln('</tr>');
        }
        continue;
      } else if (inTable) {
        buffer.writeln('</tbody>');
        buffer.writeln('</table>');
        inTable = false;
      }

      // Images ![alt](url)
      if (RegExp(r'^\!\[.*?\]\(.*?\)$').hasMatch(trimmed)) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        closeListIfNeeded();

        final match = RegExp(r'^\!\[(.*?)\]\((.*?)\)$').firstMatch(trimmed);
        if (match != null) {
          final alt = match.group(1) ?? '';
          final url = match.group(2) ?? '';
          buffer.writeln('<p class="txt bl center"><img src="${_escapeHtml(url)}" alt="${_escapeHtml(alt)}" style="max-width: 100%; height: auto;"/></p>');
        }
        continue;
      }

      // Regular paragraph
      if (inList) {
        buffer.writeln('</$currentListTag>');
        inList = false;
        currentListTag = null;
      }

      if (!inParagraph) {
        buffer.write('<p class="txt bl">');
        inParagraph = true;
      }

      buffer.write(_processInlineMarkdown(trimmed));

      // Check if next line continues paragraph
      if (i < lines.length - 1 && lines[i + 1].trim().isNotEmpty &&
          !_isSpecialLine(lines[i + 1].trim())) {
        buffer.write('<br/>');
      } else {
        buffer.writeln('</p>');
        inParagraph = false;
      }
    }

    // Close any open tags
    if (inParagraph) {
      buffer.writeln('</p>');
    }
    if (inList) {
      buffer.writeln('</$currentListTag>');
    }
    if (inTable) {
      buffer.writeln('</tbody>');
      buffer.writeln('</table>');
    }

    return buffer.toString();
  }

  /// Process inline markdown (bold, italic, links, images)
  static String _processInlineMarkdown(String text) {
    String result = _escapeHtml(text);

    // Images (inline) ![alt](url) - process before links
    result = result.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\(([^\)]+)\)'),
      (match) => '<img src="${_escapeHtml(match.group(2)!)}" alt="${_escapeHtml(match.group(1)!)}" style="max-width: 100%; height: auto;"/>',
    );

    // Bold (**text** or __text__)
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );
    result = result.replaceAllMapped(
      RegExp(r'__(.+?)__'),
      (match) => '<strong>${match.group(1)}</strong>',
    );

    // Italic (*text* or _text_)
    result = result.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (match) => '<em>${match.group(1)}</em>',
    );
    result = result.replaceAllMapped(
      RegExp(r'_(.+?)_'),
      (match) => '<em>${match.group(1)}</em>',
    );

    // Links [text](url)
    result = result.replaceAllMapped(
      RegExp(r'\[(.+?)\]\((.+?)\)'),
      (match) => '<a href="${_escapeHtml(match.group(2)!)}">${match.group(1)}</a>',
    );

    // Code `code`
    result = result.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (match) => '<code>${match.group(1)}</code>',
    );

    return result;
  }

  /// Check if line is a special markdown line (heading, list, table, image, etc.)
  static bool _isSpecialLine(String line) {
    return line.startsWith('#') ||
        line.startsWith('- ') ||
        line.startsWith('* ') ||
        line.startsWith('|') ||
        line.startsWith('!') ||
        RegExp(r'^\d+\.\s').hasMatch(line);
  }

  /// Escape HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Extract table of contents from markdown headings
  static List<TocEntry> extractTableOfContents(String markdown) {
    final entries = <TocEntry>[];
    final lines = markdown.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      // H1
      if (trimmed.startsWith('# ') && !trimmed.startsWith('## ')) {
        entries.add(TocEntry(
          level: 1,
          title: trimmed.substring(2).trim(),
        ));
      }
      // H2
      else if (trimmed.startsWith('## ') && !trimmed.startsWith('### ')) {
        entries.add(TocEntry(
          level: 2,
          title: trimmed.substring(3).trim(),
        ));
      }
      // H3
      else if (trimmed.startsWith('### ')) {
        entries.add(TocEntry(
          level: 3,
          title: trimmed.substring(4).trim(),
        ));
      }
    }

    return entries;
  }
}

/// Table of contents entry
class TocEntry {
  final int level;
  final String title;

  TocEntry({required this.level, required this.title});
}
