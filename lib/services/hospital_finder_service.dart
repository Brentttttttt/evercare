import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/hospital_location.dart';

enum LocationAccessIssue {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationAccessException implements Exception {
  const LocationAccessException(this.issue);

  final LocationAccessIssue issue;
}

class HospitalFinderException implements Exception {
  const HospitalFinderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads nearby hospitals from Overpass and submitted searches from Nominatim.
///
/// Search is intentionally submit-only. Public Nominatim usage is serialized to
/// at most one request per second, and identical requests are cached in memory.
class HospitalFinderService {
  HospitalFinderService({
    http.Client? client,
    Uri? overpassEndpoint,
    List<Uri>? overpassEndpoints,
    Uri? nominatimEndpoint,
    String userAgent = defaultUserAgent,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  }) : _client = client ?? http.Client(),
       _overpassEndpoints = _resolveOverpassEndpoints(
         overpassEndpoint: overpassEndpoint,
         overpassEndpoints: overpassEndpoints,
       ),
       _nominatimEndpoint =
           nominatimEndpoint ??
           Uri.parse('https://nominatim.openstreetmap.org/search'),
       _userAgent = userAgent,
       _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  static const defaultUserAgent =
      'EverCare/0.1.0 (https://github.com/Brentttttttt/evercare)';
  static final List<Uri> defaultOverpassEndpoints = List<Uri>.unmodifiable([
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://maps.mail.ru/osm/tools/overpass/api/interpreter'),
    Uri.parse('https://overpass.private.coffee/api/interpreter'),
  ]);
  static const _nominatimInterval = Duration(seconds: 1);
  static const _maxNearbyResults = 25;
  static const _overpassTimeout = Duration(seconds: 35);

  final http.Client _client;
  final List<Uri> _overpassEndpoints;
  final Uri _nominatimEndpoint;
  final String _userAgent;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;

  final Map<String, List<HospitalLocation>> _nearbyCache = {};
  final Map<String, Future<List<HospitalLocation>>> _nearbyInFlight = {};
  final Map<String, List<HospitalLocation>> _searchCache = {};
  final Map<String, Future<List<HospitalLocation>>> _searchInFlight = {};

  Future<void> _nominatimQueue = Future<void>.value();
  DateTime? _lastNominatimRequestAt;

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(LocationAccessIssue.servicesDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException(
        LocationAccessIssue.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(LocationAccessIssue.permissionDenied);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<List<HospitalLocation>> findNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 15000,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        !radiusMeters.isFinite ||
        radiusMeters <= 0) {
      throw const HospitalFinderException(
        'The nearby-hospital search area is invalid.',
      );
    }

    final cacheKey = _nearbyCacheKey(latitude, longitude, radiusMeters);
    final cached = _nearbyCache[cacheKey];
    if (cached != null) return Future.value(cached);

    final existingRequest = _nearbyInFlight[cacheKey];
    if (existingRequest != null) return existingRequest;

    final request = _loadNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    _nearbyInFlight[cacheKey] = request;
    return request
        .then((hospitals) {
          final stableResult = List<HospitalLocation>.unmodifiable(hospitals);
          _nearbyCache[cacheKey] = stableResult;
          return stableResult;
        })
        .whenComplete(() => _nearbyInFlight.remove(cacheKey));
  }

  Future<List<HospitalLocation>> search({
    required String query,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final cacheKey = _normalize(trimmedQuery);
    var rawHospitals = _searchCache[cacheKey];
    if (rawHospitals == null) {
      final existingRequest = _searchInFlight[cacheKey];
      final request = existingRequest ?? _loadSearch(trimmedQuery);
      if (existingRequest == null) _searchInFlight[cacheKey] = request;
      try {
        rawHospitals = await request;
        rawHospitals = List<HospitalLocation>.unmodifiable(rawHospitals);
        _searchCache[cacheKey] = rawHospitals;
      } finally {
        if (existingRequest == null) _searchInFlight.remove(cacheKey);
      }
    }

    return _addDistancesAndSort(
      rawHospitals,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    );
  }

  void close() {
    _client.close();
  }

  Future<List<HospitalLocation>> _loadNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final radius = radiusMeters.round();
    final query =
        '''
[out:json][timeout:25];
(
  nwr["amenity"="hospital"](around:$radius,$latitude,$longitude);
  nwr["healthcare"="hospital"](around:$radius,$latitude,$longitude);
);
out center tags;
''';

    final response = await _requestOverpassWithFallback(query);

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Expected an object response.');
      }
      final elements = body['elements'];
      if (elements is! List) return const [];

      final hospitals = <HospitalLocation>[];
      for (final value in elements) {
        if (value is! Map) continue;
        final element = Map<String, dynamic>.from(value);
        final hospital = _hospitalFromOverpass(
          element,
          originLatitude: latitude,
          originLongitude: longitude,
        );
        if (hospital != null) hospitals.add(hospital);
      }
      return _deduplicateAndSort(
        hospitals,
      ).take(_maxNearbyResults).toList(growable: false);
    } on FormatException catch (error) {
      throw HospitalFinderException(
        'The nearby-hospital service returned invalid data: ${error.message}',
      );
    }
  }

  Future<http.Response> _requestOverpassWithFallback(String query) async {
    final failures = <String>[];

    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await _client
            .post(
              endpoint,
              headers: _headers(
                contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
              ),
              body: {'data': query},
            )
            .timeout(_overpassTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode == 429 || response.statusCode >= 500) {
          failures.add('${endpoint.host}: HTTP ${response.statusCode}');
          continue;
        }

        _ensureSuccessful(
          response,
          serviceName: 'OpenStreetMap hospital service',
        );
      } on TimeoutException {
        failures.add('${endpoint.host}: request timed out');
      } on http.ClientException catch (error) {
        failures.add('${endpoint.host}: ${error.message}');
      }
    }

    final details = failures.isEmpty ? '' : ' (${failures.join('; ')})';
    throw HospitalFinderException(
      'OpenStreetMap hospital services are temporarily unavailable after '
      'trying ${_overpassEndpoints.length} provider(s)$details. '
      'Please try again later.',
    );
  }

  Future<List<HospitalLocation>> _loadSearch(String query) async {
    final uri = _nominatimEndpoint.replace(
      queryParameters: {
        ..._nominatimEndpoint.queryParameters,
        'format': 'jsonv2',
        'q': _hospitalSearchQuery(query),
        'countrycodes': 'ph',
        'addressdetails': '1',
        'limit': '15',
        'dedupe': '1',
      },
    );
    final response = await _rateLimitedNominatimRequest(uri);
    _ensureSuccessful(response, serviceName: 'OpenStreetMap search service');

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! List) {
        throw const FormatException('Expected a list response.');
      }

      final hospitals = <HospitalLocation>[];
      for (final value in body) {
        if (value is! Map) continue;
        final hospital = _hospitalFromNominatim(
          Map<String, dynamic>.from(value),
        );
        if (hospital != null) hospitals.add(hospital);
      }
      return _deduplicateAndSort(hospitals);
    } on FormatException catch (error) {
      throw HospitalFinderException(
        'The hospital search service returned invalid data: ${error.message}',
      );
    }
  }

  Future<http.Response> _rateLimitedNominatimRequest(Uri uri) {
    final request = _nominatimQueue.then((_) async {
      final previousRequest = _lastNominatimRequestAt;
      if (previousRequest != null) {
        final elapsed = _now().difference(previousRequest);
        final remaining = _nominatimInterval - elapsed;
        if (remaining > Duration.zero) await _delay(remaining);
      }
      _lastNominatimRequestAt = _now();
      return _client
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 25));
    });
    _nominatimQueue = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  HospitalLocation? _hospitalFromOverpass(
    Map<String, dynamic> element, {
    required double originLatitude,
    required double originLongitude,
  }) {
    final type = element['type']?.toString().trim() ?? '';
    final osmId = element['id']?.toString().trim() ?? '';
    if (type.isEmpty || osmId.isEmpty) return null;

    final center = element['center'];
    final latitude = _asDouble(
      element['lat'] ?? (center is Map ? center['lat'] : null),
    );
    final longitude = _asDouble(
      element['lon'] ?? (center is Map ? center['lon'] : null),
    );
    if (latitude == null || longitude == null) return null;

    final rawTags = element['tags'];
    final tags = rawTags is Map
        ? Map<String, dynamic>.from(rawTags)
        : const <String, dynamic>{};
    final name = _firstNonEmpty([
      tags['name'],
      tags['name:en'],
      tags['official_name'],
      tags['brand'],
      tags['operator'],
    ]);

    return HospitalLocation(
      id: '$type:$osmId',
      name: name ?? 'Hospital',
      address: _overpassAddress(tags),
      latitude: latitude,
      longitude: longitude,
      distanceMeters: Geolocator.distanceBetween(
        originLatitude,
        originLongitude,
        latitude,
        longitude,
      ),
    );
  }

  HospitalLocation? _hospitalFromNominatim(Map<String, dynamic> result) {
    final latitude = _asDouble(result['lat']);
    final longitude = _asDouble(result['lon']);
    if (latitude == null || longitude == null) return null;

    final displayName = result['display_name']?.toString().trim() ?? '';
    final rawAddress = result['address'];
    final address = rawAddress is Map
        ? Map<String, dynamic>.from(rawAddress)
        : const <String, dynamic>{};
    final name = _firstNonEmpty([
      result['name'],
      address['amenity'],
      address['healthcare'],
      displayName.isEmpty ? null : displayName.split(',').first,
    ]);
    if (name == null) return null;

    final osmType = result['osm_type']?.toString().trim() ?? '';
    final osmId = result['osm_id']?.toString().trim() ?? '';
    final placeId = result['place_id']?.toString().trim() ?? '';
    final id = osmType.isNotEmpty && osmId.isNotEmpty
        ? '$osmType:$osmId'
        : placeId.isNotEmpty
        ? 'place:$placeId'
        : '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    return HospitalLocation(
      id: id,
      name: name,
      address: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }

  List<HospitalLocation> _addDistancesAndSort(
    List<HospitalLocation> hospitals, {
    double? originLatitude,
    double? originLongitude,
  }) {
    if (originLatitude == null || originLongitude == null) {
      return List<HospitalLocation>.unmodifiable(
        _deduplicateAndSort(hospitals),
      );
    }
    final withDistances = hospitals
        .map(
          (hospital) => HospitalLocation(
            id: hospital.id,
            name: hospital.name,
            address: hospital.address,
            latitude: hospital.latitude,
            longitude: hospital.longitude,
            distanceMeters: Geolocator.distanceBetween(
              originLatitude,
              originLongitude,
              hospital.latitude,
              hospital.longitude,
            ),
          ),
        )
        .toList();
    return List<HospitalLocation>.unmodifiable(
      _deduplicateAndSort(withDistances),
    );
  }

  List<HospitalLocation> _deduplicateAndSort(List<HospitalLocation> hospitals) {
    final byOsmId = <String, HospitalLocation>{};
    for (final hospital in hospitals) {
      byOsmId.putIfAbsent(hospital.id, () => hospital);
    }

    final unique = <HospitalLocation>[];
    for (final hospital in byOsmId.values) {
      final normalizedName = _normalize(hospital.name);
      final representsExistingPlace = unique.any(
        (existing) =>
            _normalize(existing.name) == normalizedName &&
            Geolocator.distanceBetween(
                  existing.latitude,
                  existing.longitude,
                  hospital.latitude,
                  hospital.longitude,
                ) <
                150,
      );
      if (!representsExistingPlace) unique.add(hospital);
    }

    unique.sort((first, second) {
      final firstDistance = first.distanceMeters;
      final secondDistance = second.distanceMeters;
      if (firstDistance != null && secondDistance != null) {
        final distanceOrder = firstDistance.compareTo(secondDistance);
        if (distanceOrder != 0) return distanceOrder;
      } else if (firstDistance != null) {
        return -1;
      } else if (secondDistance != null) {
        return 1;
      }
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
    return unique;
  }

  String _overpassAddress(Map<String, dynamic> tags) {
    final fullAddress = tags['addr:full']?.toString().trim() ?? '';
    if (fullAddress.isNotEmpty) return fullAddress;

    final street = _joinNonEmpty([
      tags['addr:housenumber'],
      tags['addr:street'] ?? tags['addr:road'],
    ], separator: ' ');
    return _joinUnique([
      street,
      tags['addr:barangay'],
      tags['addr:suburb'],
      tags['addr:village'],
      tags['addr:municipality'],
      tags['addr:town'],
      tags['addr:city'],
      tags['addr:province'],
      tags['addr:postcode'],
    ]);
  }

  Map<String, String> _headers({String? contentType}) => {
    'User-Agent': _userAgent,
    'Accept': 'application/json',
    'Accept-Language': 'en',
    'Content-Type': ?contentType,
  };

  void _ensureSuccessful(
    http.Response response, {
    required String serviceName,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw HospitalFinderException(
      '$serviceName is temporarily unavailable (HTTP ${response.statusCode}).',
    );
  }

  String _hospitalSearchQuery(String query) {
    final normalized = _normalize(query);
    final alreadyMedical = RegExp(
      r'\b(hospital|medical\s+cent(?:er|re)|infirmary)\b',
    ).hasMatch(normalized);
    final inPhilippines = RegExp(
      r'\b(philippines|pilipinas)\b',
    ).hasMatch(normalized);
    return [
      query,
      ?(alreadyMedical ? null : 'hospital'),
      ?(inPhilippines ? null : 'Philippines'),
    ].join(', ');
  }

  String _nearbyCacheKey(
    double latitude,
    double longitude,
    double radiusMeters,
  ) =>
      '${latitude.toStringAsFixed(4)}|${longitude.toStringAsFixed(4)}|'
      '${radiusMeters.round()}';

  static List<Uri> _resolveOverpassEndpoints({
    required Uri? overpassEndpoint,
    required List<Uri>? overpassEndpoints,
  }) {
    if (overpassEndpoint != null && overpassEndpoints != null) {
      throw ArgumentError(
        'Provide either overpassEndpoint or overpassEndpoints, not both.',
      );
    }

    final resolved = overpassEndpoint != null
        ? <Uri>[overpassEndpoint]
        : overpassEndpoints ?? defaultOverpassEndpoints;
    if (resolved.isEmpty) {
      throw ArgumentError.value(
        overpassEndpoints,
        'overpassEndpoints',
        'At least one Overpass endpoint is required.',
      );
    }
    return List<Uri>.unmodifiable(resolved);
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String? _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  String _joinNonEmpty(Iterable<Object?> values, {String separator = ', '}) =>
      values
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .join(separator);

  String _joinUnique(Iterable<Object?> values) {
    final seen = <String>{};
    final parts = <String>[];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || !seen.add(text.toLowerCase())) continue;
      parts.add(text);
    }
    return parts.join(', ');
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
