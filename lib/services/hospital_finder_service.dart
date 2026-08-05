import 'dart:math' as math;

import 'package:flutter_google_places_sdk_platform_interface/flutter_google_places_sdk_platform_interface.dart'
    as places;
import 'package:geolocator/geolocator.dart';

import '../config/google_maps_config.dart';
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

class HospitalFinderService {
  HospitalFinderService({String apiKey = GoogleMapsConfig.apiKey})
    : _apiKey = apiKey;

  static const _fields = [
    places.PlaceField.Id,
    places.PlaceField.DisplayName,
    places.PlaceField.FormattedAddress,
    places.PlaceField.Location,
  ];

  final String _apiKey;
  bool _initialized = false;

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
    double radiusMeters = 30000,
  }) async {
    await _ensureInitialized();
    final response = await places.FlutterGooglePlacesSdkPlatform.instance
        .searchNearby(
          fields: _fields,
          locationRestriction: places.CircularBounds(
            center: places.LatLng(lat: latitude, lng: longitude),
            radius: radiusMeters,
          ),
          includedTypes: const ['hospital'],
          rankPreference: places.NearbySearchRankPreference.Distance,
          regionCode: 'PH',
          maxResultCount: 15,
        );
    return _mapPlaces(
      response.places,
      originLatitude: latitude,
      originLongitude: longitude,
    );
  }

  Future<List<HospitalLocation>> search({
    required String query,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];
    await _ensureInitialized();

    final response = await places.FlutterGooglePlacesSdkPlatform.instance
        .searchByText(
          trimmedQuery,
          fields: _fields,
          includedType: 'hospital',
          maxResultCount: 15,
          locationBias: originLatitude == null || originLongitude == null
              ? null
              : _locationBounds(originLatitude, originLongitude),
          rankPreference: places.TextSearchRankPreference.Relevance,
          regionCode: 'PH',
          strictTypeFiltering: true,
        );
    return _mapPlaces(
      response.places,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final platform = places.FlutterGooglePlacesSdkPlatform.instance;
    if (await platform.isInitialized() != true) {
      await platform.initialize(_apiKey);
    }
    _initialized = true;
  }

  List<HospitalLocation> _mapPlaces(
    List<places.Place> results, {
    double? originLatitude,
    double? originLongitude,
  }) {
    final hospitals = <HospitalLocation>[];
    for (final place in results) {
      final location = place.latLng;
      final name = place.name?.trim() ?? '';
      if (location == null || name.isEmpty) continue;
      final distance = originLatitude == null || originLongitude == null
          ? null
          : Geolocator.distanceBetween(
              originLatitude,
              originLongitude,
              location.lat,
              location.lng,
            );
      hospitals.add(
        HospitalLocation(
          id: place.id?.trim().isNotEmpty == true
              ? place.id!.trim()
              : '${location.lat},${location.lng}',
          name: name,
          address: place.address?.trim() ?? '',
          latitude: location.lat,
          longitude: location.lng,
          distanceMeters: distance,
        ),
      );
    }
    hospitals.sort((a, b) {
      final first = a.distanceMeters;
      final second = b.distanceMeters;
      if (first == null && second == null) return a.name.compareTo(b.name);
      if (first == null) return 1;
      if (second == null) return -1;
      return first.compareTo(second);
    });
    return hospitals;
  }

  places.LatLngBounds _locationBounds(double latitude, double longitude) {
    const radiusMeters = 25000.0;
    final latitudeDelta = radiusMeters / 111320;
    final longitudeScale = math.cos(latitude * math.pi / 180).abs();
    final longitudeDelta =
        radiusMeters / (111320 * longitudeScale.clamp(.1, 1));
    return places.LatLngBounds(
      southwest: places.LatLng(
        lat: latitude - latitudeDelta,
        lng: longitude - longitudeDelta,
      ),
      northeast: places.LatLng(
        lat: latitude + latitudeDelta,
        lng: longitude + longitudeDelta,
      ),
    );
  }
}
