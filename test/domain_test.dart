import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindmap_youth/core/launch.dart';
import 'package:mindmap_youth/core/pin_hasher.dart';
import 'package:mindmap_youth/data/resource_repository.dart';
import 'package:mindmap_youth/domain/resource.dart';
import 'package:mindmap_youth/domain/resource_ranker.dart';
import 'package:mindmap_youth/domain/risk_signal_detector.dart';

Resource res(String id, String county,
        {double? lat, double? lng, String? cost, bool telehealth = false}) =>
    Resource(
      id: id,
      name: id,
      types: const ['counseling'],
      county: county,
      lat: lat,
      lng: lng,
      cost: cost,
      telehealth: telehealth,
    );

void main() {
  group('haversine', () {
    test('Seattle to Ellensburg is about 95 miles', () {
      final d = haversineMiles(47.6062, -122.3321, 46.9965, -120.5478);
      expect(d, closeTo(94, 4));
    });
    test('same point is zero', () {
      expect(haversineMiles(47, -122, 47, -122), 0);
    });
  });

  group('rankResources', () {
    final all = [
      res('statewide', 'Statewide'),
      res('far', 'Chelan', lat: 47.42, lng: -120.31),
      res('near', 'King', lat: 47.53, lng: -122.03),
    ];

    test('nearest first, statewide last, when a position is known', () {
      final r = rankResources(all, lat: 47.5, lng: -122.0);
      expect(r.map((x) => x.resource.id), ['near', 'far', 'statewide']);
      expect(r.first.miles, lessThan(5));
      expect(r.last.miles, isNull);
    });

    test('chosen county first when there is no position', () {
      final r = rankResources(all, county: 'Chelan');
      expect(r.map((x) => x.resource.id), ['far', 'near', 'statewide']);
    });

    test('filters combine', () {
      final list = [
        res('a', 'King', cost: 'free', telehealth: true),
        res('b', 'King', cost: 'insurance', telehealth: true),
        res('c', 'King', cost: 'sliding'),
      ];
      final r = rankResources(list,
          filter: const ResourceFilter(freeOrSliding: true, telehealth: true));
      expect(r.map((x) => x.resource.id), ['a']);
      expect(
          rankResources(list, filter: const ResourceFilter(type: 'crisis')),
          isEmpty);
    });
  });

  group('RiskSignalDetector', () {
    const d = RiskSignalDetector();

    test('flags high-risk phrases, any case or apostrophe', () {
      expect(d.textHasSignal('I just want to die'), isTrue);
      expect(d.textHasSignal('i DON’T want to be here anymore'), isTrue);
      expect(d.textHasSignal('everyone is better off   without me'), isTrue);
    });

    test('does not flag ordinary entries', () {
      expect(d.textHasSignal('bad day, failed my math test'), isFalse);
      expect(d.textHasSignal('my arms hurt from practice'), isFalse);
      expect(d.textHasSignal(''), isFalse);
      expect(d.textHasSignal(null), isFalse);
    });

    test('lowest mood on three days within a week', () {
      final now = DateTime(2026, 10, 10, 20);
      ({DateTime at, int mood}) e(int daysAgo, int mood) =>
          (at: now.subtract(Duration(days: daysAgo)), mood: mood);
      expect(d.moodPatternHasSignal([e(0, 1), e(1, 1), e(2, 1)], now: now), isTrue);
      // Same day three times is one day.
      expect(
          d.moodPatternHasSignal(
              [e(0, 1), (at: now.subtract(const Duration(hours: 1)), mood: 1), e(1, 1)],
              now: now),
          isFalse);
      expect(d.moodPatternHasSignal([e(0, 1), e(1, 2), e(2, 1)], now: now), isFalse);
      expect(d.moodPatternHasSignal([e(0, 1), e(1, 1), e(9, 1)], now: now), isFalse);
    });
  });

  group('PinHasher', () {
    test('matches PBKDF2-HMAC-SHA256 from Python hashlib', () {
      // hashlib.pbkdf2_hmac('sha256', pin, b'salt', iterations, 32)
      expect(PinHasher.hash('passwd', 'c2FsdA==', iterations: 1),
          'VawEblbjCJ/sFpHCJUS2BflBhSFt3gRl5oudV8INrLw=');
      expect(PinHasher.hash('1234', 'c2FsdA==', iterations: 1000),
          '/vKS0jH25vXnh7ItsSiw5Q0uddDD1/KYnnf3ICZGcXs=');
    });
    test('different salt or pin gives a different hash', () {
      final a = PinHasher.hash('1234', 'c2FsdA==', iterations: 10);
      expect(PinHasher.hash('1234', 'c2FsdA==', iterations: 10), a);
      expect(PinHasher.hash('1235', 'c2FsdA==', iterations: 10), isNot(a));
      expect(PinHasher.hash('1234', 'c2FsdGI=', iterations: 10), isNot(a));
      expect(PinHasher.constantTimeEquals(a, a), isTrue);
    });
  });

  group('links', () {
    test('sms body separator differs by platform', () {
      expect(smsUri('741741', body: 'HOME', platform: TargetPlatform.android).toString(),
          'sms:741741?body=HOME');
      expect(smsUri('741741', body: 'HOME', platform: TargetPlatform.iOS).toString(),
          'sms:741741&body=HOME');
      expect(telUri('988').toString(), 'tel:988');
    });
  });

  group('bundled resources', () {
    final json = File('assets/wa_resources.json').readAsStringSync();

    test('parse, with unique ids and a way to reach each real one', () {
      final all = ResourceRepository.parse(json, includeSamples: true);
      expect(all.map((r) => r.id).toSet().length, all.length);
      for (final r in all.where((r) => !r.sample)) {
        expect(r.phone != null || r.text != null, isTrue, reason: r.id);
      }
    });

    test('samples are left out of release data', () {
      final release = ResourceRepository.parse(json, includeSamples: false);
      expect(release, isNotEmpty);
      expect(release.any((r) => r.sample), isFalse);
    });
  });
}
