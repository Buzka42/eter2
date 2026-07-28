// A local stand-in for the endpoint described in docs/AI_ENDPOINT.md.
//
// It exists so the app can be exercised end to end on one machine before any
// server is deployed. It does the two things that matter: it holds the model
// credential so the client never has to, and it forwards the client's already
// bounded {system, user, responseSchema} triple without adding to it,
// parsing it or repairing what comes back.
//
// It is NOT the production endpoint. It has no authentication worth the name,
// no rate limiting and no persistence, and it listens on loopback only. Do not
// put it on a public address.
//
//   dart run tool/dev_endpoint.dart
//
// The key is read, in order, from:
//   1. the GEMINI_API_KEY environment variable
//   2. app/tool/dev_endpoint.secret — one line, gitignored
//
// Usage from the app:
//   flutter run --dart-define=ETER_AI_ENDPOINT=http://127.0.0.1:8787
//   flutter run --dart-define=ETER_AI_ENDPOINT=http://10.0.2.2:8787   (Android emulator)

import 'dart:convert';
import 'dart:io';

/// Flash-lite carries the free tier's highest request ceiling and is fast
/// enough that a Journal page does not sit spinning.
///
/// Override with ETER_DEV_MODEL. `gemini-3.6-flash` is the obvious step up if
/// the prose reads thin — the voice is most of what this product is, so judge
/// it on the Vessel and the day story rather than on latency.
///
/// Checked against this key on 28 July 2026: the 2.0 and 2.5 lines answer with
/// a free-tier quota of zero, and 2.5-flash is closed to new keys outright.
/// If this one starts refusing, list what the key can actually reach:
///   GET https://generativelanguage.googleapis.com/v1beta/models
const _defaultModel = 'gemini-3.5-flash-lite';

const _calls = {
  'guidance',
  'journalDayStory',
  'journalInterpretation',
  'vesselReadings',
  'positions',
};

Future<void> main(List<String> args) async {
  final key = _readKey();
  if (key == null) {
    stderr.writeln(
      'No key. Set GEMINI_API_KEY, or put the key on one line in\n'
      'app/tool/dev_endpoint.secret (gitignored).',
    );
    exitCode = 2;
    return;
  }
  final model = Platform.environment['ETER_DEV_MODEL'] ?? _defaultModel;
  final port = int.tryParse(Platform.environment['ETER_DEV_PORT'] ?? '') ?? 8787;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Eter dev endpoint · $model · http://127.0.0.1:$port');
  stdout.writeln('Android emulator reaches it at http://10.0.2.2:$port');

  await for (final request in server) {
    try {
      await _handle(request, key: key, model: model);
    } catch (error) {
      stderr.writeln('unhandled: $error');
      _fail(request, HttpStatus.internalServerError, '$error');
    }
  }
}

String? _readKey() {
  final fromEnv = Platform.environment['GEMINI_API_KEY'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
  final file = File('tool/dev_endpoint.secret');
  if (file.existsSync()) {
    final text = file.readAsStringSync().trim();
    if (text.isNotEmpty) return text.split('\n').first.trim();
  }
  return null;
}

Future<void> _handle(
  HttpRequest request, {
  required String key,
  required String model,
}) async {
  if (request.method != 'POST') {
    return _fail(request, HttpStatus.methodNotAllowed, 'POST only');
  }

  final Map<String, Object?> body;
  try {
    body = jsonDecode(await utf8.decoder.bind(request).join())
        as Map<String, Object?>;
  } catch (_) {
    return _fail(request, HttpStatus.badRequest, 'Body must be a JSON object');
  }

  final call = body['call'];
  if (call is! String || !_calls.contains(call)) {
    return _fail(request, HttpStatus.badRequest, 'Unknown call: $call');
  }
  final system = body['system'];
  final user = body['user'];
  if (system is! String || system.isEmpty || user is! Map) {
    return _fail(request, HttpStatus.badRequest, 'Missing system or user');
  }

  final started = DateTime.now();
  // Logged: the call, not the payload. The payload is one person's records.
  stdout.write('→ $call ');

  try {
    final schema = body['responseSchema'];
    final raw = await _generate(
      key: key,
      model: model,
      system: system,
      user: jsonEncode(user),
      schema: schema is Map<String, Object?> ? schema : null,
    );
    stdout.writeln(
      '· ${DateTime.now().difference(started).inMilliseconds} ms '
      '· ${raw.length} chars',
    );
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      // Unparsed and unrepaired. The app's own parsers are the contract.
      ..write(jsonEncode({'raw': raw}));
    await request.response.close();
  } on _ModelException catch (error) {
    stdout.writeln('· failed: ${error.reason}');
    _fail(request, HttpStatus.badGateway, error.reason);
  }
}

class _ModelException implements Exception {
  const _ModelException(this.reason);
  final String reason;
}

Future<String> _generate({
  required String key,
  required String model,
  required String system,
  required String user,
  Map<String, Object?>? schema,
}) async {
  final url = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models/$model:generateContent',
  );
  final payload = jsonEncode({
    'system_instruction': {
      'parts': [
        {'text': system},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': user},
        ],
      },
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      // Constrained decoding against the client's own schema. Without it the
      // model invents plausible field names and the parsers — correctly —
      // refuse the answer. A production endpoint should do the same.
      if (schema != null) 'responseJsonSchema': schema,
      'temperature': 0.7,
    },
  });

  final client = HttpClient();
  try {
    final request = await client.postUrl(url);
    request.headers
      ..set('content-type', 'application/json; charset=utf-8')
      ..set('x-goog-api-key', key);
    request.write(payload);
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw _ModelException('model returned ${response.statusCode}: '
          '${text.replaceAll('\n', ' ').trim()}');
    }
    final decoded = jsonDecode(text) as Map<String, Object?>;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw _ModelException('model returned no candidate: $text');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw _ModelException('model returned no text: $text');
    }
    final out = (parts.first as Map)['text'];
    if (out is! String || out.trim().isEmpty) {
      throw const _ModelException('model returned empty text');
    }
    return out;
  } finally {
    client.close(force: true);
  }
}

void _fail(HttpRequest request, int status, String reason) {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'error': reason}));
  request.response.close();
}
