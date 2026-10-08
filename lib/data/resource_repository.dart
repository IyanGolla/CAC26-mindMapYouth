import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/resource.dart';

/// Resources ship inside the app as a read-only asset; nothing is fetched.
class ResourceRepository {
  static const asset = 'assets/wa_resources.json';

  static List<Resource> parse(String json, {required bool includeSamples}) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return [
      for (final r in data['resources'] as List)
        Resource.fromJson(r as Map<String, dynamic>),
    ].where((r) => includeSamples || !r.sample).toList();
  }

  static Future<List<Resource>> load() async =>
      parse(await rootBundle.loadString(asset), includeSamples: !kReleaseMode);
}

/// WA-08 counties with a rough centre, used when the user picks a county
/// instead of sharing location.
const counties = <String, ({double lat, double lng})>{
  'King': (lat: 47.49, lng: -121.84),
  'Pierce': (lat: 47.04, lng: -122.14),
  'Snohomish': (lat: 48.05, lng: -121.72),
  'Kittitas': (lat: 47.12, lng: -120.68),
  'Chelan': (lat: 47.86, lng: -120.62),
};
