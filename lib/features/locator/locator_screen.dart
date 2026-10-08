import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/state.dart';
import '../../data/resource_repository.dart';
import '../../domain/resource.dart';
import '../../domain/resource_ranker.dart';

const _types = ['crisis', 'counseling', 'peer support', 'substance use'];

class LocatorScreen extends ConsumerStatefulWidget {
  const LocatorScreen({super.key});

  @override
  ConsumerState<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends ConsumerState<LocatorScreen> {
  ResourceFilter _filter = const ResourceFilter();
  bool _map = false;
  bool _locating = false;

  Future<void> _useLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No problem. Pick a county instead.')));
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      // Kept in memory for this session only.
      ref
          .read(positionProvider.notifier)
          .set((lat: p.latitude, lng: p.longitude));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Couldn\'t get a location. Pick a county instead.')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = ref.watch(servicesProvider).resources;
    final county = ref.watch(settingsProvider).county;
    final position = ref.watch(positionProvider);
    final origin = position ?? counties[county];
    final ranked = rankResources(
      resources,
      filter: _filter,
      lat: origin?.lat,
      lng: origin?.lng,
      county: county,
    );

    Widget chip(String label, bool on, ValueChanged<bool> set) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(label: Text(label), selected: on, onSelected: set),
        );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 110, 8),
            child: Text('Find help',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(county),
                    initialValue: county,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'County',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All of Washington')),
                      for (final c in counties.keys)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) {
                      ref.read(positionProvider.notifier).set(null);
                      ref.read(settingsProvider.notifier).setCounty(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: position == null
                      ? 'Use my location (stays on this phone)'
                      : 'Stop using my location',
                  isSelected: position != null,
                  onPressed: _locating
                      ? null
                      : position == null
                          ? _useLocation
                          : () => ref.read(positionProvider.notifier).set(null),
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(position == null
                          ? Icons.my_location
                          : Icons.location_disabled),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                for (final type in _types)
                  chip(
                    type[0].toUpperCase() + type.substring(1),
                    _filter.type == type,
                    (on) => setState(() => _filter =
                        _filter.copyWith(type: () => on ? type : null)),
                  ),
                chip('Free or sliding', _filter.freeOrSliding,
                    (v) => setState(() => _filter = _filter.copyWith(freeOrSliding: v))),
                chip('Phone or video', _filter.telehealth,
                    (v) => setState(() => _filter = _filter.copyWith(telehealth: v))),
                chip('LGBTQ+ affirming', _filter.lgbtqAffirming,
                    (v) => setState(() => _filter = _filter.copyWith(lgbtqAffirming: v))),
                chip('Spanish', _filter.spanish,
                    (v) => setState(() => _filter = _filter.copyWith(spanish: v))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.list), label: Text('List')),
                ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text('Map')),
              ],
              selected: {_map},
              onSelectionChanged: (s) => setState(() => _map = s.first),
            ),
          ),
          Expanded(
            child: ranked.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nothing matches those filters. Try removing one, or '
                        'tap "Need help now?" to reach someone today.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _map
                    ? _ResourceMap(ranked: ranked, origin: origin)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: ranked.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ResourceTile(ranked[i],
                            showDistance: position != null),
                      ),
          ),
        ],
      ),
    );
  }
}

String verifiedLabel(Resource r) => r.sample
    ? 'Sample listing, not a real place'
    : r.verifiedOn == null
        ? 'Not yet verified'
        : 'Last verified ${r.verifiedOn}';

class _ResourceTile extends StatelessWidget {
  const _ResourceTile(this.item, {required this.showDistance});
  final RankedResource item;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final r = item.resource;
    final t = Theme.of(context).textTheme;
    final where = r.statewide ? 'Statewide' : '${r.county} County';
    final distance = showDistance && item.miles != null
        ? ' · ${item.miles!.toStringAsFixed(item.miles! < 10 ? 1 : 0)} mi'
        : '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/resource/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: t.titleMedium),
              const SizedBox(height: 4),
              Text('$where$distance · ${r.types.join(', ')}'),
              if (r.hours != null) Text(r.hours!),
              const SizedBox(height: 4),
              Text(verifiedLabel(r), style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceMap extends StatelessWidget {
  const _ResourceMap({required this.ranked, required this.origin});
  final List<RankedResource> ranked;
  final ({double lat, double lng})? origin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placed = [
      for (final x in ranked)
        if (x.resource.hasLocation) x.resource,
    ];
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: origin != null
                  ? LatLng(origin!.lat, origin!.lng)
                  : const LatLng(47.4, -121.3),
              initialZoom: origin != null ? 9 : 7.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.mindmapyouth.mindmap_youth',
              ),
              MarkerLayer(
                markers: [
                  for (final r in placed)
                    Marker(
                      point: LatLng(r.lat!, r.lng!),
                      width: 48,
                      height: 48,
                      child: Semantics(
                        button: true,
                        label: r.name,
                        child: GestureDetector(
                          onTap: () => context.push('/resource/${r.id}'),
                          child: Icon(Icons.location_on,
                              size: 44, color: scheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Map pictures load from OpenStreetMap, so it can see which area '
            'is being viewed. Your entries and location are never sent. Phone '
            'and text lines are in the list.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
