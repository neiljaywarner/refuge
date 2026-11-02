import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_snapshot.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_os_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('session audit snapshot', () {
    test('keeps coarse facts and drops email, IP, and GPS-free blanks', () {
      final snapshot = buildClientSessionAuditSnapshot(
        now: DateTime.utc(2026, 11, 2, 15, 4, 5),
        osName: 'android',
        osVersion: '14 ${'x' * 80}',
        appVersion: '0.9.2',
        appBuild: '2',
        isWeb: false,
        countryCode: 'us',
        localeTag: 'en-US',
      );

      expect(snapshot.city, 'US');
      expect(snapshot.timezone, 'UTC');
      expect(snapshot.locale, 'en-US');
      expect(snapshot.platform, 'android');
      expect(snapshot.osVersion, hasLength(64));

      final row = snapshot.toRowData();
      expect(row.keys, everyElement(isIn(sessionAuditRowKeys)));
      expect(row['sessionStartedAt'], '2026-11-02T15:04:05.000Z');
      expect(row.containsKey('sessionEndedAt'), isFalse);
      expect(row.values.join(' '), isNot(contains('@')));
    });

    test('web omits os version and does not invent a city', () {
      final snapshot = buildClientSessionAuditSnapshot(
        now: DateTime.utc(2026, 11, 2),
        osName: 'android',
        osVersion: '14',
        appVersion: ' ',
        appBuild: null,
        isWeb: true,
        countryCode: 'tester@example.com',
        localeTag: '203.0.113.10',
      );

      expect(snapshot.platform, 'web');
      expect(snapshot.osName, 'web');
      expect(snapshot.osVersion, isNull);
      expect(snapshot.city, isNull);
      expect(snapshot.locale, isNull);
      expect(snapshot.appVersion, 'unknown');
      expect(snapshot.toRowData().containsKey('city'), isFalse);
    });

    test('uses a timezone region label only when no country is available', () {
      expect(coarseSessionCity(countryCode: null, timezone: 'America/Chicago'), 'Chicago');
      expect(coarseSessionCity(countryCode: 'CA', timezone: 'America/Toronto'), 'CA');
      expect(coarseSessionCity(countryCode: null, timezone: 'CST'), isNull);
      expect(sessionAuditPlatform(isWeb: false, osName: 'ios'), 'ios');
      expect(sessionAuditPlatform(isWeb: false, osName: 'linux'), 'linux');
    });

    test('a UTC timestamp reports the UTC zone name', () {
      expect(auditTimezoneLabel(DateTime.utc(2026, 11, 2)), 'UTC');
    });
  });

  group('session audit controller', () {
    late _FakeSink sink;

    setUp(() {
      sink = _FakeSink();
    });

    ClientSessionAuditController controller({
      Future<ClientSessionAuditSnapshot> Function()? load,
    }) => ClientSessionAuditController(
      sink: sink,
      loadSnapshot: load ?? () async => _sample(),
      clock: () => DateTime.utc(2026, 11, 2, 16),
    );

    test('writes one row per process and survives a failed write', () async {
      final active = controller();
      await active.recordStart();
      await active.recordStart();
      expect(sink.creates, 1);

      sink.createError = StateError('offline');
      final failed = controller();
      await failed.recordStart();
      expect(sink.creates, 2);
    });

    test('records the end after a pause that happened during the write', () async {
      final gate = Completer<ClientSessionAuditSnapshot>();
      final active = controller(load: () => gate.future);
      final pending = active.recordStart();
      await active.recordEnd();
      expect(sink.ends, 0);

      gate.complete(_sample());
      await pending;
      expect(sink.ends, 1);
      expect(sink.endedAt, DateTime.utc(2026, 11, 2, 16));
    });

    test('a failed end update can be retried', () async {
      final active = controller();
      await active.recordStart();
      sink.endError = StateError('forbidden');
      await active.recordEnd();
      expect(sink.ends, 1);

      sink.endError = null;
      await active.recordEnd();
      expect(sink.ends, 2);
    });

    testWidgets('startup writes once and pause records the end', (tester) async {
      final active = controller();
      final binding = startClientSessionAudit(controller: active);
      addTearDown(() {
        if (binding != null) WidgetsBinding.instance.removeObserver(binding);
      });

      await tester.pump();
      expect(sink.creates, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(sink.ends, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump();
      expect(sink.ends, 1);
    });

    test('disabled startup does not write', () {
      expect(startClientSessionAudit(controller: controller(), enabled: false), isNull);
      expect(sink.creates, 0);
    });
  });

  test('loader uses the supplied locale, version, and OS facts', () async {
    final snapshot = await loadClientSessionAuditSnapshot(
      now: () => DateTime.utc(2026, 11, 2, 15),
      loadVersion: () async => (version: '0.9.2', build: '2'),
      readOs: () => const ClientSessionOsFacts(osName: 'android', osVersion: '14'),
      locale: const Locale('en', 'US'),
      isWeb: false,
    );

    expect(snapshot.platform, 'android');
    expect(snapshot.osName, 'android');
    expect(snapshot.osVersion, '14');
    expect(snapshot.appVersion, '0.9.2');
    expect(snapshot.appBuild, '2');
    expect(snapshot.city, 'US');
    expect(snapshot.locale, 'en-US');
    expect(snapshot.toRowData().keys, everyElement(isIn(sessionAuditRowKeys)));
  });
}

ClientSessionAuditSnapshot _sample() => buildClientSessionAuditSnapshot(
  now: DateTime.utc(2026, 11, 2, 15),
  osName: 'ios',
  osVersion: '17',
  appVersion: '0.9.2',
  appBuild: '2',
  isWeb: false,
  countryCode: 'US',
  localeTag: 'en-US',
);

class _FakeSink implements ClientSessionAuditSink {
  int creates = 0;
  int ends = 0;
  Object? createError;
  Object? endError;
  DateTime? endedAt;

  @override
  Future<String?> createSession(ClientSessionAuditSnapshot snapshot) async {
    creates += 1;
    final error = createError;
    if (error != null) throw error;
    return 'row-1';
  }

  @override
  Future<void> markEnded({required String rowId, required DateTime endedAt}) async {
    ends += 1;
    this.endedAt = endedAt;
    final error = endError;
    if (error != null) throw error;
  }
}
