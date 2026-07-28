import 'dart:convert';

import 'package:eter/core/ai/prompts.dart';
import 'package:eter/core/ai/transport.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/journal/day_story.dart';
import 'package:eter/core/vessel/positions_composer.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The transport is the only place in the app that opens a socket, and its
/// whole job is to not be clever: forward the bounded triple, return the raw
/// string, fail rather than invent.
void main() {
  const config = EterAiConfig(
    endpoint: 'https://ai.example.test/compose',
    token: 'caller-token',
  );

  _Recorder recorder() => _Recorder();

  EterAiTransport transportWith(
    _Recorder record, {
    EterAiConfig configuration = config,
  }) =>
      EterAiTransport(config: configuration, post: record.post);

  group('configuration', () {
    test('a build with no endpoint has no transport', () {
      // The defines are absent under `flutter test`, which is exactly the
      // shipped local-only configuration.
      expect(EterAiConfig.fromEnvironment(), isNull);
    });

    test('loopback is allowed, because nothing leaves the device', () async {
      for (final host in ['127.0.0.1:8787', 'localhost:8787', '10.0.2.2:8787']) {
        final record = recorder();
        await transportWith(
          record,
          configuration: EterAiConfig(endpoint: 'http://$host', token: 't'),
        ).send(
          call: EterAiCall.guidance,
          system: 's',
          user: const {},
          responseSchema: const {},
        );
        expect(record.calls, 1, reason: host);
      }
    });

    test('plain HTTP to anywhere else is refused before anything is sent',
        () async {
      final record = recorder();
      final transport = transportWith(
        record,
        configuration: const EterAiConfig(
          endpoint: 'http://ai.example.test/compose',
          token: 't',
        ),
      );

      await expectLater(
        transport.send(
          call: EterAiCall.guidance,
          system: 'system',
          user: const {},
          responseSchema: const {},
        ),
        throwsA(isA<EterTransportException>()),
      );
      expect(record.calls, 0);
    });

    test('a nonsense endpoint is refused before anything is sent', () async {
      final record = recorder();
      final transport = transportWith(
        record,
        configuration: const EterAiConfig(endpoint: 'not a url', token: 't'),
      );

      await expectLater(
        transport.send(
          call: EterAiCall.guidance,
          system: 'system',
          user: const {},
          responseSchema: const {},
        ),
        throwsA(isA<EterTransportException>()),
      );
      expect(record.calls, 0);
    });
  });

  group('the request on the wire', () {
    test('carries the triple, the call name and the prompt version', () async {
      final record = recorder();
      await transportWith(record).send(
        call: EterAiCall.positions,
        system: 'You are writing today.',
        user: const {'forDate': '2026-07-28'},
        responseSchema: const {'type': 'object'},
      );

      final body = jsonDecode(record.lastBody!) as Map<String, Object?>;
      expect(body['call'], 'positions');
      expect(body['promptVersion'], EterPrompts.version);
      expect(body['system'], 'You are writing today.');
      expect(body['user'], {'forDate': '2026-07-28'});
      expect(body['responseSchema'], {'type': 'object'});
      expect(body.keys, hasLength(5));
    });

    test('authenticates the caller and nothing else', () async {
      final record = recorder();
      await transportWith(record).send(
        call: EterAiCall.guidance,
        system: 's',
        user: const {},
        responseSchema: const {},
      );

      expect(record.lastHeaders!['authorization'], 'Bearer caller-token');
      expect(
        record.lastHeaders!['content-type'],
        'application/json; charset=utf-8',
      );
      expect(record.lastHeaders, hasLength(2));
    });

    test('sends no authorization header when there is no token', () async {
      final record = recorder();
      await transportWith(
        record,
        configuration: const EterAiConfig(
          endpoint: 'https://ai.example.test/compose',
          token: '',
        ),
      ).send(
        call: EterAiCall.guidance,
        system: 's',
        user: const {},
        responseSchema: const {},
      );

      expect(record.lastHeaders!.containsKey('authorization'), isFalse);
    });

    test('each call names itself distinctly', () {
      expect(
        EterAiCall.values.map((call) => call.wireName).toSet(),
        hasLength(EterAiCall.values.length),
      );
    });
  });

  group('the response', () {
    Future<String> answering(String response) =>
        transportWith(recorder()..response = response).send(
          call: EterAiCall.guidance,
          system: 's',
          user: const {},
          responseSchema: const {},
        );

    test('bare model text passes through untouched', () async {
      expect(await answering('  {"dimensions": []}  '), '{"dimensions": []}');
    });

    test('a wrapped answer is unwrapped, and only one level', () async {
      expect(
        await answering(jsonEncode({'raw': '{"dimensions": []}'})),
        '{"dimensions": []}',
      );
    });

    test('malformed model output is forwarded, not repaired', () async {
      // The parsers are the contract. A transport that fixed this would be
      // deciding what the model said.
      expect(await answering('{"dimensions": [ oh dear'), '{"dimensions": [ oh dear');
    });

    test('an empty answer is a failure, not an empty composition', () async {
      await expectLater(answering('   '), throwsA(isA<EterTransportException>()));
    });

    test('an endpoint error is surfaced as one', () async {
      await expectLater(
        answering(jsonEncode({'error': 'rate limit reached'})),
        throwsA(
          isA<EterTransportException>().having(
            (error) => error.reason,
            'reason',
            contains('rate limit'),
          ),
        ),
      );
    });

    test('a slow endpoint times out rather than hanging a surface', () async {
      final transport = EterAiTransport(
        config: config,
        timeout: const Duration(milliseconds: 20),
        post: (url, headers, body) =>
            Future.delayed(const Duration(seconds: 5), () => 'late'),
      );

      await expectLater(
        transport.send(
          call: EterAiCall.guidance,
          system: 's',
          user: const {},
          responseSchema: const {},
        ),
        throwsA(isA<EterTransportException>()),
      );
    });

    test('a transport failure propagates rather than becoming content',
        () async {
      final transport = EterAiTransport(
        config: config,
        post: (url, headers, body) =>
            throw const EterTransportException('unreachable'),
      );

      await expectLater(
        transport.send(
          call: EterAiCall.guidance,
          system: 's',
          user: const {},
          responseSchema: const {},
        ),
        throwsA(isA<EterTransportException>()),
      );
    });
  });

  group('the five adapters', () {
    test('each forwards its own call name and its own triple', () async {
      final record = recorder();
      final transport = transportWith(record);

      await TransportAetherProvider(transport).compose(
        const AetherProviderRequest(
          system: 'guidance system',
          context: {'health': <Object>[]},
          responseSchema: {'a': 1},
        ),
      );
      expect(jsonDecode(record.lastBody!), containsPair('call', 'guidance'));
      expect(
        jsonDecode(record.lastBody!),
        containsPair('system', 'guidance system'),
      );

      await TransportJournalDayStoryProvider(transport).compose(
        const JournalDayStoryProviderRequest(
          system: 'day story system',
          context: {'date': '2026-07-28'},
          responseSchema: {},
        ),
      );
      expect(
        jsonDecode(record.lastBody!),
        containsPair('call', 'journalDayStory'),
      );

      await TransportVesselReadingProvider(transport).compose(
        const VesselReadingProviderRequest(
          system: 'vessel system',
          context: {'positions': <Object>[]},
          responseSchema: {},
        ),
      );
      expect(
        jsonDecode(record.lastBody!),
        containsPair('call', 'vesselReadings'),
      );

      await TransportPositionsProvider(transport).compose(
        const PositionsProviderRequest(
          system: 'positions system',
          context: {'forDate': '2026-07-28'},
          responseSchema: {},
        ),
      );
      expect(jsonDecode(record.lastBody!), containsPair('call', 'positions'));

      expect(record.calls, 4);
    });

    test('interpretation builds its prompt on the device', () async {
      final record = recorder();
      await TransportJournalClassificationProvider(transportWith(record))
          .classify(const JournalClassificationRequest(
        text: 'Two eggs and a slice of rye.',
        source: 'typed',
        responseSchema: {'shape': 'food'},
      ));

      final body = jsonDecode(record.lastBody!) as Map<String, Object?>;
      expect(body['call'], 'journalInterpretation');
      // The instruction came from EterPrompts, not from the endpoint.
      expect(
        body['system'],
        EterPrompts.journalInterpretation(
          entryText: 'Two eggs and a slice of rye.',
        ).system,
      );
      expect(jsonEncode(body['user']), contains('Two eggs'));
    });

    test('a clarification travels with the page it belongs to', () async {
      final record = recorder();
      await TransportJournalClassificationProvider(transportWith(record))
          .classify(const JournalClassificationRequest(
        text: 'Had a bowl of the usual.',
        source: 'spoken',
        responseSchema: {},
        clarification: 'porridge with milk',
      ));

      expect(record.lastBody, contains('porridge with milk'));
    });

    test('every adapter returns the raw string it was given', () async {
      final record = recorder()..response = '{"readings": []}';
      final transport = transportWith(record);

      expect(
        await TransportVesselReadingProvider(transport).compose(
          const VesselReadingProviderRequest(
            system: 's',
            context: {},
            responseSchema: {},
          ),
        ),
        '{"readings": []}',
      );
    });
  });
}

class _Recorder {
  int calls = 0;
  String? lastBody;
  Map<String, String>? lastHeaders;
  Uri? lastUrl;
  String response = '{"ok": true}';

  Future<String> post(
    Uri url,
    Map<String, String> headers,
    String body,
  ) async {
    calls += 1;
    lastUrl = url;
    lastHeaders = headers;
    lastBody = body;
    return response;
  }
}
