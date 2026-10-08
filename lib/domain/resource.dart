/// A help resource from the bundled, read-only JSON asset.
class Resource {
  const Resource({
    required this.id,
    required this.name,
    required this.types,
    required this.county,
    this.lat,
    this.lng,
    this.phone,
    this.text,
    this.textBody,
    this.website,
    this.hours,
    this.ages,
    this.cost,
    this.languages = const [],
    this.telehealth = false,
    this.lgbtqAffirming = false,
    this.notes,
    this.whatToExpect,
    this.verifiedOn,
    this.source,
    this.sample = false,
  });

  final String id;
  final String name;
  final List<String> types;

  /// County name, or "Statewide".
  final String county;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? text;
  final String? textBody;
  final String? website;
  final String? hours;
  final String? ages;
  final String? cost;
  final List<String> languages;
  final bool telehealth;
  final bool lgbtqAffirming;
  final String? notes;
  final String? whatToExpect;
  final String? verifiedOn;
  final String? source;

  /// Placeholder listing for development. Never shown in release builds.
  final bool sample;

  bool get statewide => county == 'Statewide';
  bool get hasLocation => lat != null && lng != null;

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
        id: j['id'] as String,
        name: j['name'] as String,
        types: (j['type'] as List).cast<String>(),
        county: j['county'] as String,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        phone: j['phone'] as String?,
        text: j['text'] as String?,
        textBody: j['text_body'] as String?,
        website: j['website'] as String?,
        hours: j['hours'] as String?,
        ages: j['ages'] as String?,
        cost: j['cost'] as String?,
        languages: ((j['languages'] as List?) ?? const []).cast<String>(),
        telehealth: j['telehealth'] as bool? ?? false,
        lgbtqAffirming: j['lgbtq_affirming'] as bool? ?? false,
        notes: j['notes'] as String?,
        whatToExpect: j['what_to_expect'] as String?,
        verifiedOn: j['verified_on'] as String?,
        source: j['source'] as String?,
        sample: j['sample'] as bool? ?? false,
      );
}
