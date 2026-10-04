import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class CvExtractionResult {
  const CvExtractionResult({
    required this.text,
    required this.likelyScanned,
    required this.mimeType,
  });

  final String text;
  final bool likelyScanned;
  final String mimeType;
}

/// Extracts embedded text from PDF and DOCX. Does not run OCR.
class CvTextExtractor {
  const CvTextExtractor();

  CvExtractionResult extract({
    required String extension,
    required List<int> bytes,
  }) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'docx') {
      final text = _extractDocx(bytes);
      return CvExtractionResult(
        text: text,
        likelyScanned: false,
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }
    if (ext == 'pdf') {
      return _extractPdf(bytes);
    }
    throw const CvExtractException('unsupported');
  }

  String _extractDocx(List<int> bytes) {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const CvExtractException('unreadable');
    }
    final file = archive.findFile('word/document.xml');
    if (file == null) throw const CvExtractException('unreadable');
    XmlDocument document;
    try {
      document = XmlDocument.parse(utf8.decode(file.content));
    } catch (_) {
      throw const CvExtractException('unreadable');
    }
    final buffer = StringBuffer();
    for (final paragraph in document.findAllElements('w:p')) {
      final text = paragraph
          .findAllElements('w:t')
          .map((node) => node.innerText)
          .join();
      if (text.trim().isNotEmpty) buffer.writeln(text.trim());
    }
    final result = buffer.toString().trim();
    if (result.length < 20) throw const CvExtractException('unreadable');
    return result;
  }

  CvExtractionResult _extractPdf(List<int> bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    if (!raw.startsWith('%PDF')) {
      throw const CvExtractException('unreadable');
    }
    final buffer = StringBuffer();
    final streamPattern = RegExp(r'stream\r?\n([\s\S]*?)endstream');
    for (final match in streamPattern.allMatches(raw)) {
      final group = match.group(1);
      if (group == null || group.isEmpty) continue;
      final headerStart = raw.lastIndexOf('<<', match.start);
      final header = headerStart == -1
          ? ''
          : raw.substring(headerStart, match.start);
      var payload = latin1.encode(group);
      if (payload.isNotEmpty && (payload.last == 10 || payload.last == 13)) {
        payload = payload.sublist(0, payload.length - 1);
      }
      String decoded;
      if (header.contains('/FlateDecode')) {
        try {
          decoded = latin1.decode(Inflate(payload).getBytes());
        } catch (_) {
          continue;
        }
      } else {
        decoded = group;
      }
      buffer.write(_pdfOperatorsToText(decoded));
    }
    if (buffer.isEmpty) {
      buffer.write(_pdfOperatorsToText(raw));
    }
    final text = buffer.toString().replaceAll(RegExp(r'[ \t]+\n'), '\n').trim();
    final imageHeavy = RegExp(r'/Subtype\s*/Image').hasMatch(raw);
    final likelyScanned = text.length < 40 && (imageHeavy || text.length < 20);
    if (text.length < 20 && !imageHeavy) {
      throw const CvExtractException('unreadable');
    }
    return CvExtractionResult(
      text: text,
      likelyScanned: likelyScanned,
      mimeType: 'application/pdf',
    );
  }

  String _pdfOperatorsToText(String content) {
    final buffer = StringBuffer();
    final tj = RegExp(r'\((?:\\.|[^\\)])*\)\s*Tj');
    for (final match in tj.allMatches(content)) {
      buffer.writeln(_unescapePdfString(match.group(0)!));
    }
    final tjArray = RegExp(r'\[(?:.|\n)*?\]\s*TJ', caseSensitive: false);
    for (final match in tjArray.allMatches(content)) {
      final chunk = match.group(0)!;
      for (final part in RegExp(r'\((?:\\.|[^\\)])*\)').allMatches(chunk)) {
        buffer.write(_unescapePdfString(part.group(0)!));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _unescapePdfString(String raw) {
    final start = raw.indexOf('(');
    final end = raw.lastIndexOf(')');
    if (start < 0 || end <= start) return '';
    final inner = raw.substring(start + 1, end);
    final buffer = StringBuffer();
    for (var i = 0; i < inner.length; i++) {
      final char = inner[i];
      if (char == r'\' && i + 1 < inner.length) {
        final next = inner[++i];
        buffer.write(switch (next) {
          'n' => '\n',
          'r' => '\r',
          't' => '\t',
          '(' || ')' || r'\' => next,
          _ => next,
        });
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}

class CvExtractException implements Exception {
  const CvExtractException(this.code);
  final String code;
}
