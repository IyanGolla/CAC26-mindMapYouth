import 'dart:math';

import 'resource.dart';

class ResourceFilter {
  const ResourceFilter({
    this.type,
    this.freeOrSliding = false,
    this.telehealth = false,
    this.lgbtqAffirming = false,
    this.spanish = false,
  });

  final String? type;
  final bool freeOrSliding;
  final bool telehealth;
  final bool lgbtqAffirming;
  final bool spanish;

  bool matches(Resource r) {
    if (type != null && !r.types.contains(type)) return false;
    if (freeOrSliding && r.cost != 'free' && r.cost != 'sliding') return false;
    if (telehealth && !r.telehealth) return false;
    if (lgbtqAffirming && !r.lgbtqAffirming) return false;
    if (spanish && !r.languages.contains('es')) return false;
    return true;
  }

  ResourceFilter copyWith({
    String? Function()? type,
    bool? freeOrSliding,
    bool? telehealth,
    bool? lgbtqAffirming,
    bool? spanish,
  }) =>
      ResourceFilter(
        type: type != null ? type() : this.type,
        freeOrSliding: freeOrSliding ?? this.freeOrSliding,
        telehealth: telehealth ?? this.telehealth,
        lgbtqAffirming: lgbtqAffirming ?? this.lgbtqAffirming,
        spanish: spanish ?? this.spanish,
      );
}

class RankedResource {
  const RankedResource(this.resource, this.miles);
  final Resource resource;

  /// Null when there is no position to measure from, or the resource has none.
  final double? miles;
}

/// Great-circle distance in miles.
double haversineMiles(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMiles = 3958.8;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * earthRadiusMiles * asin(min(1.0, sqrt(a)));
}

/// Filters, then orders: nearest first when a position is known, otherwise the
/// chosen county first. Resources with no place (statewide lines) go last,
/// alphabetically.
List<RankedResource> rankResources(
  List<Resource> all, {
  ResourceFilter filter = const ResourceFilter(),
  double? lat,
  double? lng,
  String? county,
}) {
  final hasPosition = lat != null && lng != null;
  final ranked = [
    for (final r in all.where(filter.matches))
      RankedResource(
        r,
        hasPosition && r.hasLocation
            ? haversineMiles(lat, lng, r.lat!, r.lng!)
            : null,
      ),
  ];

  int group(RankedResource x) {
    if (x.resource.statewide) return 2;
    if (hasPosition) return 0;
    return x.resource.county == county ? 0 : 1;
  }

  ranked.sort((a, b) {
    final g = group(a).compareTo(group(b));
    if (g != 0) return g;
    if (a.miles != null && b.miles != null) {
      final d = a.miles!.compareTo(b.miles!);
      if (d != 0) return d;
    }
    return a.resource.name.compareTo(b.resource.name);
  });
  return ranked;
}
