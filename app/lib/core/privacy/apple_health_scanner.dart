/// Finds `<Record>` elements in an Apple Health export, without reading it all.
///
/// `export.xml` is the largest file this product will ever be handed. A phone
/// carried for a few years produces one in the **hundreds of megabytes** —
/// heart rate alone is a sample every few seconds — and the ordinary approach
/// of reading a file into a string and handing it to a parser asks a phone to
/// hold all of it, plus a document tree several times its size, at once. It
/// does not survive that.
///
/// So this is a scanner rather than a parser. It is fed the file in chunks, it
/// keeps only what is left over at each chunk boundary, and it emits one record
/// at a time. Nothing is retained.
///
/// **It is not a general XML parser and must not be used as one.** It
/// understands exactly the shape Apple writes:
///
/// ```xml
/// <Record type="HKQuantityTypeIdentifierBodyMass" unit="kg"
///         startDate="2024-03-01 08:15:00 +0100" value="70.5"/>
/// ```
///
/// Attributes are read; children — `MetadataEntry`, and the workout elements —
/// are skipped, which is why a record written with a closing tag rather than as
/// self-closing reads the same as one without.
library;

/// One `<Record>` element's attributes, uninterpreted.
class AppleHealthRecord {
  const AppleHealthRecord(this.attributes);

  final Map<String, String> attributes;

  String? operator [](String name) => attributes[name];

  /// `HKQuantityTypeIdentifierBodyMass`, and so on.
  String get type => attributes['type'] ?? '';

  String get unit => attributes['unit'] ?? '';

  /// The reading. Null when absent or not a number — a category record such as
  /// sleep carries a name here instead.
  double? get value => double.tryParse(attributes['value'] ?? '');

  DateTime? get start => parseAppleDate(attributes['startDate']);
  DateTime? get end => parseAppleDate(attributes['endDate']);
}

/// `2024-03-01 08:15:00 +0100`.
///
/// Apple writes a local wall clock and the offset that was in force, which is
/// the only format in the file and is not ISO 8601 — the space instead of `T`
/// and the space before the offset both defeat `DateTime.parse`. The offset
/// matters and is not decoration: a night's sleep recorded in one country and
/// read in another lands on the wrong day without it.
DateTime? parseAppleDate(String? raw) {
  if (raw == null) return null;
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})'
    r'(?:\s*([+-])(\d{2}):?(\d{2}))?$',
  ).firstMatch(raw.trim());
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;

  final local = DateTime.utc(year, month, day, hour, minute, second);
  // `DateTime` rolls a day that does not exist forward rather than refusing it.
  if (local.month != month || local.day != day) return null;

  final sign = match.group(7);
  if (sign == null) return local;
  final offset = Duration(
    hours: int.parse(match.group(8)!),
    minutes: int.parse(match.group(9)!),
  );
  // The stamp is a wall clock *plus* the offset it was written under, so the
  // instant is the wall clock with that offset taken back off.
  return sign == '+' ? local.subtract(offset) : local.add(offset);
}

/// Feeds chunks in, gets records out.
///
/// Stateful by necessity: a chunk boundary falls in the middle of a tag on
/// almost every chunk of a real file, and the leftover has to survive until the
/// rest of that tag arrives.
class AppleHealthScanner {
  AppleHealthScanner({this.maximumTagLength = 64 * 1024, this.keep});

  /// Decides, from the raw text of a tag, whether it is worth reading.
  ///
  /// The file is overwhelmingly made of records nothing here wants: three
  /// years of a worn watch is a couple of hundred thousand heart-rate samples
  /// around four thousand nights of sleep. Parsing the attributes of every one
  /// of them — a regex over every tag — is most of the cost of the scan, and
  /// all of that work is thrown away.
  ///
  /// A substring test over the tag is far cheaper than that and cannot be
  /// wrong in the dangerous direction: it is applied to the tag's own text, so
  /// a filter that matches too much only costs time.
  final bool Function(String tag)? keep;

  /// A guard against a file that is not what it claims to be. A `<Record` with
  /// no closing `>` would otherwise grow the buffer until the phone gives up;
  /// a real record is a few hundred characters.
  final int maximumTagLength;

  String _carry = '';

  /// Every record that finished inside [chunk].
  ///
  /// A chunk that ends mid-tag keeps the partial tag for the next call, so the
  /// caller can pass a stream through unchanged.
  List<AppleHealthRecord> add(String chunk) {
    // Copied to a local because a field cannot be promoted: it could in
    // principle be a getter returning something different on each read, so the
    // language will not let a null check stand for the call.
    final filter = keep;
    final records = <AppleHealthRecord>[];
    var text = _carry + chunk;
    var from = 0;

    while (true) {
      final open = text.indexOf('<Record', from);
      if (open < 0) break;
      // `<RecordX` is not a `<Record`. Apple writes no such element today and
      // that is exactly the sort of thing that changes.
      final after = open + '<Record'.length;
      if (after < text.length && !_isTagBreak(text[after])) {
        from = after;
        continue;
      }
      final close = _endOfTag(text, after);
      if (close < 0) {
        // Unfinished. Keep from the opening angle bracket so the whole tag is
        // seen once the rest arrives.
        if (text.length - open > maximumTagLength) {
          // Not a record, or not a file. Step past it rather than growing for
          // ever.
          from = after;
          continue;
        }
        _carry = text.substring(open);
        return records;
      }
      final tag = text.substring(after, close);
      if (filter == null || filter(tag)) {
        final attributes = parseAttributes(tag);
        if (attributes.isNotEmpty) records.add(AppleHealthRecord(attributes));
      }
      from = close + 1;
    }

    // Nothing unfinished, but the tail may still be the first few characters
    // of a tag — a chunk that ends on `<Rec` is ordinary. Keeping the last few
    // characters costs nothing, and anything complete inside them has already
    // been consumed above, so nothing can be emitted twice.
    final tail = text.length < 16 ? text.length : 16;
    _carry = text.substring(text.length - tail);
    return records;
  }

  /// Ends the scan.
  ///
  /// Always empty, and it exists to say so: whatever is still held is by
  /// definition an unfinished tag, and half a record is not a record. A
  /// well-formed export leaves nothing here; a truncated one leaves the tag it
  /// was cut off in the middle of, and that reading is lost rather than
  /// guessed at.
  void flush() => _carry = '';

  static bool _isTagBreak(String char) =>
      char == ' ' || char == '\t' || char == '\n' || char == '\r' || char == '>';

  /// The index of the `>` that ends this tag, skipping any inside quotes.
  ///
  /// A quoted attribute can hold one: source names are free text and
  /// `sourceName="Bob's > phone"` is somebody's actual device.
  static int _endOfTag(String text, int from) {
    var quote = '';
    for (var i = from; i < text.length; i++) {
      final char = text[i];
      if (quote.isNotEmpty) {
        if (char == quote) quote = '';
        continue;
      }
      if (char == '"' || char == "'") {
        quote = char;
        continue;
      }
      if (char == '>') return i;
    }
    return -1;
  }

  /// `type="X" unit="kg" value="70.5"` → a map.
  ///
  /// Entity references are resolved for the five XML defines them for. A source
  /// name containing an ampersand is ordinary and would otherwise arrive as
  /// `&amp;`.
  static Map<String, String> parseAttributes(String tag) {
    final attributes = <String, String>{};
    for (final match in RegExp(
      '''([A-Za-z_][\\w.:-]*)\\s*=\\s*("([^"]*)"|'([^']*)')''',
    ).allMatches(tag)) {
      final name = match.group(1)!;
      final value = match.group(3) ?? match.group(4) ?? '';
      attributes[name] = _unescape(value);
    }
    return attributes;
  }

  static String _unescape(String value) => value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      // Last, or an escaped `&amp;lt;` becomes a tag.
      .replaceAll('&amp;', '&');
}
