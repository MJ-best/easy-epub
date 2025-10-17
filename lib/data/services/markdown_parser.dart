/// Markdown to HTML parser for EPUB generation
class MarkdownParser {
  /// Convert markdown text to HTML with proper structure
  static String parseToHtml(String markdown) {
    final buffer = StringBuffer();
    final lines = markdown.split('\n');

    bool inParagraph = false;
    bool inList = false;

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
          buffer.writeln('</ul>');
          inList = false;
        }
        buffer.writeln('<p class="txt bl"><br/></p>');
        continue;
      }

      // Heading level 1
      if (trimmed.startsWith('# ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        buffer.writeln('<h1 class="h1">${_escapeHtml(trimmed.substring(2))}</h1>');
        continue;
      }

      // Heading level 2
      if (trimmed.startsWith('## ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        buffer.writeln('<h2 class="h2">${_escapeHtml(trimmed.substring(3))}</h2>');
        continue;
      }

      // Heading level 3
      if (trimmed.startsWith('### ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        buffer.writeln('<h3 class="h3">${_escapeHtml(trimmed.substring(4))}</h3>');
        continue;
      }

      // Unordered list
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        if (inParagraph) {
          buffer.writeln('</p>');
          inParagraph = false;
        }
        if (!inList) {
          buffer.writeln('<ul class="list">');
          inList = true;
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
        if (!inList) {
          buffer.writeln('<ol class="list">');
          inList = true;
        }
        final content = trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '');
        buffer.writeln('<li>${_processInlineMarkdown(content)}</li>');
        continue;
      }

      // Regular paragraph
      if (inList) {
        buffer.writeln('</ul>');
        inList = false;
      }

      if (!inParagraph) {
        buffer.write('<p class="txt bl">');
        inParagraph = true;
      }

      buffer.write(_processInlineMarkdown(trimmed));

      // Check if next line continues paragraph
      if (i < lines.length - 1 && lines[i + 1].trim().isNotEmpty &&
          !_isSpecialLine(lines[i + 1].trim())) {
        buffer.write(' ');
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
      buffer.writeln('</ul>');
    }

    return buffer.toString();
  }

  /// Process inline markdown (bold, italic, links)
  static String _processInlineMarkdown(String text) {
    String result = text;

    // Bold (**text** or __text__)
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${_escapeHtml(match.group(1)!)}</strong>',
    );
    result = result.replaceAllMapped(
      RegExp(r'__(.+?)__'),
      (match) => '<strong>${_escapeHtml(match.group(1)!)}</strong>',
    );

    // Italic (*text* or _text_)
    result = result.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (match) => '<em>${_escapeHtml(match.group(1)!)}</em>',
    );
    result = result.replaceAllMapped(
      RegExp(r'_(.+?)_'),
      (match) => '<em>${_escapeHtml(match.group(1)!)}</em>',
    );

    // Links [text](url)
    result = result.replaceAllMapped(
      RegExp(r'\[(.+?)\]\((.+?)\)'),
      (match) => '<a href="${_escapeHtml(match.group(2)!)}">${_escapeHtml(match.group(1)!)}</a>',
    );

    // Code `code`
    result = result.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (match) => '<code>${_escapeHtml(match.group(1)!)}</code>',
    );

    return _escapeHtml(result);
  }

  /// Check if line is a special markdown line (heading, list, etc.)
  static bool _isSpecialLine(String line) {
    return line.startsWith('#') ||
        line.startsWith('- ') ||
        line.startsWith('* ') ||
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
}
