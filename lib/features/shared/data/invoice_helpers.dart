/// Utility functions shared between the invoice parser and mapper.
/// Ports the helper functions from the Rust `parser.rs` and `mapper.rs`.

/// Convert `"DD.MM.YYYY. HH:MM:SS"` → ISO 8601 `"YYYY-MM-DDTHH:MM:SS"`.
String parseDate(String raw) {
  final s = raw.trim();
  final spaceIdx = s.indexOf(' ');
  if (spaceIdx < 0) throw FormatException('Expected space in date: "$s"');
  final datePart = s.substring(0, spaceIdx).replaceAll(RegExp(r'\.$'), '');
  final timePart = s.substring(spaceIdx + 1);
  final segs = datePart.split('.');
  if (segs.length != 3) {
    throw FormatException('Expected DD.MM.YYYY in: "$datePart"');
  }
  final dd = int.parse(segs[0]);
  final mm = int.parse(segs[1]);
  final yyyy = segs[2];
  return '$yyyy-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}T$timePart';
}

/// Parse a European-formatted number `"1.234,56"` → `1234.56`.
double parsePrice(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.parse(cleaned);
}

/// Percent-encode characters outside the RFC 3986 unreserved set.
String percentEncode(String s) {
  final buf = StringBuffer();
  for (final byte in s.codeUnits) {
    final ch = String.fromCharCode(byte);
    if (RegExp(r'[A-Za-z0-9\-_\.~]').hasMatch(ch)) {
      buf.write(ch);
    } else {
      buf.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return buf.toString();
}

/// Convert `"YYYY-MM-DDTHH:MM:SS"` → `"YYYYMMDDTHHMMSS"` for filenames.
String compactDate(String date) =>
    date.replaceAll('-', '').replaceAll(':', '');

/// Convert arbitrary text to a lowercase ASCII hyphen-separated slug.
String slugify(String text) {
  final buf = StringBuffer();
  var prevSep = true;
  for (final cp in text.trim().codeUnits) {
    if ((cp >= 0x30 && cp <= 0x39) || // 0-9
        (cp >= 0x41 && cp <= 0x5A) || // A-Z
        (cp >= 0x61 && cp <= 0x7A)) { // a-z
      buf.write(String.fromCharCode(cp).toLowerCase());
      prevSep = false;
    } else if (!prevSep) {
      buf.write('-');
      prevSep = true;
    }
  }
  final result = buf.toString();
  return result.endsWith('-') ? result.substring(0, result.length - 1) : result;
}
