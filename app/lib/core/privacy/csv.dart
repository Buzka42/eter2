/// A CSV reader, because every record worth importing arrives as one.
///
/// Written here rather than taken as a dependency: this is a hundred lines of
/// well-specified behaviour (RFC 4180), it runs over a file somebody chose from
/// their own phone, and the alternative is a package in the dependency tree
/// that can read arbitrary input from disk. The formats this exists for —
/// Daylio, Bearable — are exports from mood apps, which means they contain
/// people's prose, which means embedded commas, quotes and newlines are the
/// normal case rather than the edge one.
///
/// What it handles, all of which a real export will contain:
///
/// * fields quoted with `"`, and `""` as an escaped quote inside them
/// * commas and line breaks *inside* a quoted field
/// * `\r\n`, `\n` and a final line with no terminator at all
/// * a UTF-8 byte-order mark, which Excel writes and which otherwise becomes
///   part of the first header's name and makes every column lookup miss
library;

/// One parsed file: rows of fields, in order, with nothing interpreted.
///
/// Deliberately not a map. The header is a row like any other here — which of
/// the rows is a header, and what its names mean, belongs to whichever importer
/// is reading the file.
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldWasQuoted = false;
  // True until the first character of a field is read, so a quote can be told
  // from a quote that merely appears in the middle of unquoted text.
  var atFieldStart = true;

  // Excel and a good many exporters write one. It is invisible, it is not a
  // separator, and left in place it renames the first column to something no
  // lookup will ever match.
  final text = input.startsWith('﻿') ? input.substring(1) : input;

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldWasQuoted = false;
    atFieldStart = true;
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];

    if (inQuotes) {
      if (char == '"') {
        // A doubled quote is one literal quote; a single one closes the field.
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    switch (char) {
      case '"':
        if (atFieldStart) {
          inQuotes = true;
          fieldWasQuoted = true;
          atFieldStart = false;
        } else {
          // A quote in the middle of an unquoted field is just a character.
          // Exports do this, and refusing the file over it would be refusing
          // somebody's diary over their punctuation.
          field.write(char);
        }
      case ',':
        endField();
      case '\r':
        // Swallowed; the '\n' that follows ends the row. A lone '\r' as a line
        // ending is old enough that no export writes one.
        continue;
      case '\n':
        endRow();
      default:
        field.write(char);
        atFieldStart = false;
    }
  }

  // A trailing newline ends the last row and leaves nothing behind. Anything
  // else — text, or a quoted empty field — is a final row with no terminator.
  if (field.isNotEmpty || row.isNotEmpty || fieldWasQuoted) {
    endRow();
  }

  return rows;
}

/// The rows of a CSV addressed by column name.
///
/// Every importer here does the same three things — find the header, decide
/// whether this file is the format it reads, and pull named fields out of each
/// row — and every one of them would otherwise do it slightly differently.
class CsvTable {
  CsvTable._(this.header, this.rows, this._index);

  /// Reads [content], taking its first non-empty row as the header.
  ///
  /// Column names are matched case-insensitively and with surrounding
  /// whitespace removed. That is not tolerance for its own sake: exports differ
  /// between an app's versions in exactly this way, and a header that reads
  /// `Rating/Amount` in one release and `rating/amount` in the next is the same
  /// column.
  static CsvTable? read(String content) {
    final rows = parseCsv(content);
    var start = 0;
    while (start < rows.length && _isBlank(rows[start])) {
      start++;
    }
    if (start >= rows.length) return null;
    final header = [for (final name in rows[start]) name.trim()];
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      // First occurrence wins. A duplicated column name is a broken export and
      // the earlier one is the one the writer meant.
      index.putIfAbsent(header[i].toLowerCase(), () => i);
    }
    return CsvTable._(
      header,
      [
        for (final row in rows.skip(start + 1))
          if (!_isBlank(row)) row,
      ],
      index,
    );
  }

  final List<String> header;
  final List<List<String>> rows;
  final Map<String, int> _index;

  bool has(String column) => _index.containsKey(column.toLowerCase());

  /// True when every one of [columns] is present. What "this file is a Daylio
  /// export" actually means.
  bool hasAll(Iterable<String> columns) => columns.every(has);

  /// The named field of [row], trimmed, or an empty string when the column is
  /// absent or the row is short. A short row is ordinary in the wild: an
  /// exporter that omits trailing empty fields produces them on every entry
  /// that ended with a blank note.
  String field(List<String> row, String column) {
    final at = _index[column.toLowerCase()];
    if (at == null || at >= row.length) return '';
    return row[at].trim();
  }

  static bool _isBlank(List<String> row) =>
      row.every((field) => field.trim().isEmpty);
}
