/// The one way a model is reached, and the one place a network call is made.
///
/// Every one of the five contracts is already a bounded `{system, user,
/// responseSchema}` triple built on the device. This file does exactly one
/// thing with that triple: it posts it to an endpoint the product owner
/// controls and returns the response body as a string.
///
/// Three rules, and they are the reason this file is so small.
///
/// **No credential lives here.** The client authenticates to *the owner's*
/// endpoint, which holds the model key. A build of Eter that shipped a model
/// key would be a build that gave it to everyone who downloaded it.
///
/// **No parsing happens here.** The parsers in each contract are the contract.
/// A transport that repaired malformed JSON on the way past would defeat the
/// validation that keeps invented content out of the record.
///
/// **No fallback is produced here.** Every failure path throws. A day with no
/// guidance is a correct outcome; a day with guidance nobody composed is not.
library;

import 'dart:convert';
import 'dart:io';

import '../aether/guidance_contract.dart';
import '../aether/letter.dart';
import '../journal/classification_contract.dart';
import '../journal/day_story.dart';
import '../vessel/positions_composer.dart';
import '../vessel/reading_composer.dart';
import 'prompts.dart';

/// Where the endpoint is and how to prove we may call it.
///
/// Read from `--dart-define` at build time, so a debug build with no defines
/// behaves exactly as the app does today: no transport, and every surface says
/// so.
class EterAiConfig {
  const EterAiConfig({
    required this.endpoint,
    required this.token,
    this.installId,
    this.allowInsecure = false,
  });

  /// An opaque per-install string, so the endpoint can meter one install without
  /// metering everyone.
  ///
  /// This is a real, if small, widening of what leaves the device, and it is
  /// worth being precise about. The endpoint's only previous way to tell callers
  /// apart was the connecting address, which is wrong twice over: behind carrier
  /// NAT thousands of people share one, and the daily cap is global, so a single
  /// looping install could spend the day's budget and every other person would be
  /// refused for it. Metering needs *something* stable per install.
  ///
  /// What this is not: it is random, generated on the device, derived from
  /// nothing about the person, never assembled into a payload, and never stored
  /// server-side except as a short-lived counter keyed on a hash of it. It cannot
  /// be linked to an account, an address or a name by anyone holding it. The
  /// `AI_FLOW.md` §1 rule — no identifier reaches the *model* — is unchanged; this
  /// travels in a header, for the server, and is dropped before the request is
  /// forwarded.
  ///
  /// Null on a build with no endpoint, and null is handled: the endpoint then
  /// falls back to address-based limiting, which is better than nothing.
  final String? installId;

  /// The owner-controlled endpoint. Empty means no transport is configured.
  final String endpoint;

  /// The caller's credential for that endpoint — not for any model.
  final String token;

  /// Permits cleartext to an address that is not loopback.
  ///
  /// For one case only: a phone on the same network as a development machine
  /// running `tool/dev_endpoint.dart`, where tethering to `adb reverse` would
  /// defeat the point of testing the app as it is actually used. It is off
  /// unless a build explicitly asks for it, and a release build cannot use it
  /// regardless — the Android network-security config that permits cleartext
  /// is merged into debug and profile only.
  final bool allowInsecure;

  static const _endpoint = String.fromEnvironment('ETER_AI_ENDPOINT');
  static const _token = String.fromEnvironment('ETER_AI_TOKEN');
  static const _allowInsecure =
      bool.fromEnvironment('ETER_AI_ALLOW_INSECURE');

  /// The configuration this build was compiled with, or null if it was
  /// compiled without one.
  ///
  /// [installId] is not a compile-time define — it is per install, not per
  /// build — so it is supplied by the caller that can read it from the store.
  static EterAiConfig? fromEnvironment({String? installId}) {
    if (_endpoint.isEmpty) return null;
    return EterAiConfig(
      endpoint: _endpoint,
      token: _token,
      installId: installId,
      allowInsecure: _allowInsecure,
    );
  }

  /// HTTPS, or loopback.
  ///
  /// The payload is bounded but it is still a person's records, so it does not
  /// travel a network in the clear. The carve-out is for an endpoint running
  /// on the same machine — `tool/dev_endpoint.dart` during development, and
  /// `10.0.2.2`, which is how the Android emulator addresses its own host.
  /// Nothing leaves the device on those routes.
  bool get isTransportSecure {
    final url = Uri.tryParse(endpoint);
    if (url == null) return false;
    if (url.scheme == 'https') return true;
    if (url.scheme != 'http') return false;
    if (allowInsecure) return true;
    return const {'localhost', '127.0.0.1', '::1', '10.0.2.2'}
        .contains(url.host);
  }
}

class EterTransportException implements Exception {
  const EterTransportException(this.reason, {this.statusCode});

  final String reason;

  /// Present when the endpoint answered and the answer was not a success.
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? reason : '$reason (HTTP $statusCode)';
}

/// The five calls, named on the wire so the endpoint can route, meter and log
/// them separately without inspecting the payload.
enum EterAiCall {
  guidance,
  journalDayStory,
  journalInterpretation,
  vesselReadings,
  positions,
  letter;

  String get wireName => name;
}

/// Posts a JSON body and returns the response body, or throws.
///
/// Injected so the transport can be tested without a socket. The default is
/// [defaultEterPost].
typedef EterPost = Future<String> Function(
  Uri url,
  Map<String, String> headers,
  String body,
);

/// `dart:io` rather than a package, because one POST does not justify a
/// dependency and the thirteen that came out of this build were removed for a
/// reason.
Future<String> defaultEterPost(
  Uri url,
  Map<String, String> headers,
  String body,
) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.postUrl(url);
    headers.forEach(request.headers.set);
    request.write(body);
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EterTransportException(
        'The guidance endpoint refused the request',
        statusCode: response.statusCode,
      );
    }
    return text;
  } on SocketException {
    // These reach a surface, so they are sentences rather than diagnostics.
    throw const EterTransportException(
      'Eter could not reach guidance. Check your connection — everything '
      'else works offline, and nothing was changed.',
    );
  } on HttpException {
    throw const EterTransportException(
      'Guidance could not be reached. Nothing was changed.',
    );
  } finally {
    client.close(force: true);
  }
}

/// One endpoint, five callers.
class EterAiTransport {
  EterAiTransport({
    required this.config,
    this.post = defaultEterPost,
    this.timeout = const Duration(seconds: 45),
  });

  final EterAiConfig config;
  final EterPost post;
  final Duration timeout;

  /// Forwards the triple unchanged and returns whatever came back.
  ///
  /// The endpoint is expected to answer with the model's raw text — the same
  /// string a provider would have returned — either as the whole body or as a
  /// `{"raw": "..."}` envelope. Anything else is a transport failure rather
  /// than a parse failure, because the parsers are not this file's business.
  Future<String> send({
    required EterAiCall call,
    required String system,
    required Map<String, Object?> user,
    required Map<String, Object?> responseSchema,
  }) async {
    final url = Uri.tryParse(config.endpoint);
    if (url == null || !url.isAbsolute) {
      throw const EterTransportException('The endpoint is not a valid URL');
    }
    if (!config.isTransportSecure) {
      throw const EterTransportException(
        'The endpoint must be HTTPS, or on this device',
      );
    }

    final body = jsonEncode({
      'call': call.wireName,
      'promptVersion': EterPrompts.version,
      'system': system,
      'user': user,
      'responseSchema': responseSchema,
    });

    final response = await post(
      url,
      {
        'content-type': 'application/json; charset=utf-8',
        if (config.token.isNotEmpty) 'authorization': 'Bearer ${config.token}',
        // A header, deliberately, and not a field in `body`. The endpoint meters
        // on it and drops it; nothing about it reaches the model. See
        // `EterAiConfig.installId`.
        if (config.installId case final id? when id.isNotEmpty)
          'x-eter-install': id,
      },
      body,
    ).timeout(
      timeout,
      onTimeout: () => throw const EterTransportException(
        'Guidance took too long to answer. Nothing was changed.',
      ),
    );

    return _unwrap(response);
  }

  /// Accepts the model's text either bare or wrapped, and nothing else.
  String _unwrap(String response) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const EterTransportException('The endpoint returned nothing');
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final raw = decoded['raw'];
        if (raw is String && raw.trim().isNotEmpty) return raw;
        if (decoded['error'] is String) {
          throw EterTransportException(decoded['error'] as String);
        }
      }
    } on FormatException {
      // Not JSON at all: it is the model's text, which the parsers will judge.
    }
    return trimmed;
  }
}

// ---------------------------------------------------------------------------
// The five adapters. Each is the same three lines with a different call name,
// which is the point: no adapter gets to be clever about its own contract.
// ---------------------------------------------------------------------------

class TransportAetherProvider implements AetherProvider {
  const TransportAetherProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> compose(AetherProviderRequest request) => transport.send(
        call: EterAiCall.guidance,
        system: request.system,
        user: request.context,
        responseSchema: request.responseSchema,
      );
}

class TransportLetterProvider implements LetterProvider {
  const TransportLetterProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> compose(LetterProviderRequest request) => transport.send(
        call: EterAiCall.letter,
        system: request.system,
        user: request.context,
        responseSchema: request.responseSchema,
      );
}

class TransportJournalDayStoryProvider implements JournalDayStoryProvider {
  const TransportJournalDayStoryProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> compose(JournalDayStoryProviderRequest request) =>
      transport.send(
        call: EterAiCall.journalDayStory,
        system: request.system,
        user: request.context,
        responseSchema: request.responseSchema,
      );
}

/// The one adapter that builds its own prompt, because the classification
/// contract carries the page rather than a composed request. The prompt is
/// still built here on the device, from `EterPrompts`.
class TransportJournalClassificationProvider
    implements JournalClassificationProvider {
  const TransportJournalClassificationProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> classify(JournalClassificationRequest request) {
    final prompt = EterPrompts.journalInterpretation(
      entryText: request.text,
      clarification: request.clarification,
      language: request.language,
      body: request.body,
    );
    return transport.send(
      call: EterAiCall.journalInterpretation,
      system: prompt.system,
      user: prompt.user,
      // The prompt's schema, which names `meal`, `kcal` and `proteinG` — the
      // fields the parser requires. Left to itself a model reaches for
      // `name`, `energy_kcal` and `protein_g`, and the estimate is refused.
      responseSchema: prompt.responseSchema,
    );
  }
}

class TransportVesselReadingProvider implements VesselReadingProvider {
  const TransportVesselReadingProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> compose(VesselReadingProviderRequest request) =>
      transport.send(
        call: EterAiCall.vesselReadings,
        system: request.system,
        user: request.context,
        responseSchema: request.responseSchema,
      );
}

class TransportPositionsProvider implements PositionsProvider {
  const TransportPositionsProvider(this.transport);
  final EterAiTransport transport;

  @override
  Future<String> compose(PositionsProviderRequest request) => transport.send(
        call: EterAiCall.positions,
        system: request.system,
        user: request.context,
        responseSchema: request.responseSchema,
      );
}
