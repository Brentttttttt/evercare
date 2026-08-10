import 'dart:convert';

import 'package:evercare/services/hospital_finder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HospitalFinderService nearby hospitals', () {
    test('uses the validated public Overpass fallback order', () {
      expect(
        HospitalFinderService.defaultOverpassEndpoints.map(
          (endpoint) => endpoint.toString(),
        ),
        [
          'https://overpass-api.de/api/interpreter',
          'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
          'https://overpass.private.coffee/api/interpreter',
        ],
      );
    });

    test('queries Overpass and parses nodes, ways, and relations', () async {
      late http.Request capturedRequest;
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 14.8305,
                'lon': 120.8805,
                'tags': {
                  'name': 'Near Hospital',
                  'amenity': 'hospital',
                  'addr:full': '1 Test Street, Guiguinto, Bulacan',
                },
              },
              {
                'type': 'relation',
                'id': 3,
                'center': {'lat': 14.835, 'lon': 120.885},
                'tags': {
                  'operator': 'Community Medical Center',
                  'healthcare': 'hospital',
                  'addr:barangay': 'Tabang',
                  'addr:city': 'Guiguinto',
                },
              },
              {
                'type': 'way',
                'id': 2,
                'center': {'lat': 14.85, 'lon': 120.9},
                'tags': {
                  'name:en': 'Far Hospital',
                  'amenity': 'hospital',
                  'addr:housenumber': '25',
                  'addr:street': 'Care Road',
                  'addr:municipality': 'Guiguinto',
                  'addr:province': 'Bulacan',
                },
              },
              {
                'type': 'node',
                'id': 99,
                'lat': 14.83051,
                'lon': 120.88051,
                'tags': {'name': 'Near Hospital', 'healthcare': 'hospital'},
              },
              {
                'type': 'way',
                'id': 100,
                'tags': {'name': 'Missing Center Hospital'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = HospitalFinderService(
        client: client,
        overpassEndpoint: Uri.parse('https://example.test/overpass'),
      );
      addTearDown(service.close);

      final hospitals = await service.findNearby(
        latitude: 14.83,
        longitude: 120.88,
        radiusMeters: 12500,
      );

      expect(requestCount, 1);
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url, Uri.parse('https://example.test/overpass'));
      expect(
        capturedRequest.headers['user-agent'],
        HospitalFinderService.defaultUserAgent,
      );
      expect(capturedRequest.bodyFields['data'], contains('around:12500'));
      expect(capturedRequest.bodyFields['data'], contains('nwr'));
      expect(hospitals, hasLength(3));
      expect(hospitals.map((hospital) => hospital.id), [
        'node:1',
        'relation:3',
        'way:2',
      ]);
      expect(hospitals.first.name, 'Near Hospital');
      expect(hospitals.first.address, '1 Test Street, Guiguinto, Bulacan');
      expect(hospitals[1].name, 'Community Medical Center');
      expect(hospitals[1].address, 'Tabang, Guiguinto');
      expect(hospitals[2].address, '25 Care Road, Guiguinto, Bulacan');
      expect(
        hospitals.every((hospital) => hospital.distanceMeters != null),
        isTrue,
      );
    });

    test('caches equivalent nearby searches in memory', () async {
      var requestCount = 0;
      final service = HospitalFinderService(
        client: MockClient((_) async {
          requestCount++;
          return http.Response(jsonEncode({'elements': <Object>[]}), 200);
        }),
        overpassEndpoint: Uri.parse('https://example.test/overpass'),
      );
      addTearDown(service.close);

      await service.findNearby(latitude: 14.83001, longitude: 120.88001);
      await service.findNearby(latitude: 14.83002, longitude: 120.88002);

      expect(requestCount, 1);
    });

    test('falls back to the next Overpass provider after HTTP 504', () async {
      final primary = Uri.parse('https://primary.example.test/interpreter');
      final fallback = Uri.parse('https://fallback.example.test/interpreter');
      final requestedEndpoints = <Uri>[];
      final requestedQueries = <String>[];
      final service = HospitalFinderService(
        client: MockClient((request) async {
          requestedEndpoints.add(request.url);
          requestedQueries.add(request.bodyFields['data']!);
          if (request.url == primary) {
            return http.Response('Gateway timeout', 504);
          }
          return http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'id': 42,
                  'lat': 14.83,
                  'lon': 120.88,
                  'tags': {'name': 'Fallback Community Hospital'},
                },
              ],
            }),
            200,
          );
        }),
        overpassEndpoints: [primary, fallback],
      );
      addTearDown(service.close);

      final hospitals = await service.findNearby(
        latitude: 14.83,
        longitude: 120.88,
      );

      expect(requestedEndpoints, [primary, fallback]);
      expect(
        requestedQueries.every((query) => query.contains('around:15000')),
        isTrue,
      );
      expect(hospitals, hasLength(1));
      expect(hospitals.single.name, 'Fallback Community Hospital');
    });

    test('reports an unavailable Overpass service honestly', () async {
      final service = HospitalFinderService(
        client: MockClient((_) async => http.Response('Unavailable', 503)),
        overpassEndpoint: Uri.parse('https://example.test/overpass'),
      );
      addTearDown(service.close);

      await expectLater(
        service.findNearby(latitude: 14.83, longitude: 120.88),
        throwsA(
          isA<HospitalFinderException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 503'),
          ),
        ),
      );
    });
  });

  group('HospitalFinderService submitted search', () {
    test(
      'uses Nominatim only on submit, caches, and rate limits requests',
      () async {
        final requests = <http.Request>[];
        var now = DateTime.utc(2026, 8, 10, 12);
        final delays = <Duration>[];
        final client = MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {
                'place_id': 10,
                'osm_type': 'way',
                'osm_id': 501,
                'lat': '14.8300',
                'lon': '120.8800',
                'name': 'Guiguinto Community Hospital',
                'display_name':
                    'Guiguinto Community Hospital, Bulacan, Philippines',
                'address': {'amenity': 'Guiguinto Community Hospital'},
              },
              {
                'place_id': 11,
                'osm_type': 'node',
                'osm_id': 502,
                'lat': '14.9000',
                'lon': '120.9500',
                'display_name': 'Bulacan Medical Center, Bulacan, Philippines',
                'address': {'amenity': 'Bulacan Medical Center'},
              },
              {
                'place_id': 12,
                'osm_type': 'node',
                'osm_id': 503,
                'lat': '14.83001',
                'lon': '120.88001',
                'name': 'Guiguinto Community Hospital',
                'display_name': 'Duplicate result, Bulacan, Philippines',
              },
              {'place_id': 13, 'name': 'Invalid result without coordinates'},
            ]),
            200,
          );
        });
        final service = HospitalFinderService(
          client: client,
          nominatimEndpoint: Uri.parse('https://example.test/search'),
          now: () => now,
          delay: (duration) async {
            delays.add(duration);
            now = now.add(duration);
          },
        );
        addTearDown(service.close);

        expect(requests, isEmpty);
        expect(await service.search(query: '   '), isEmpty);
        expect(requests, isEmpty);

        final first = await service.search(query: 'Guiguinto');
        final cachedWithNewOrigin = await service.search(
          query: '  GUIGUINTO  ',
          originLatitude: 14.9,
          originLongitude: 120.95,
        );
        await service.search(query: 'Malolos Medical Center');

        expect(requests, hasLength(2));
        expect(delays, [const Duration(seconds: 1)]);
        expect(requests.first.method, 'GET');
        expect(
          requests.first.headers['user-agent'],
          HospitalFinderService.defaultUserAgent,
        );
        expect(requests.first.url.queryParameters['format'], 'jsonv2');
        expect(requests.first.url.queryParameters['countrycodes'], 'ph');
        expect(requests.first.url.queryParameters['addressdetails'], '1');
        expect(
          requests.first.url.queryParameters['q'],
          'Guiguinto, hospital, Philippines',
        );
        expect(
          requests.last.url.queryParameters['q'],
          'Malolos Medical Center, Philippines',
        );
        expect(first, hasLength(2));
        expect(first.first.name, 'Bulacan Medical Center');
        expect(first.last.name, 'Guiguinto Community Hospital');
        expect(cachedWithNewOrigin.first.name, 'Bulacan Medical Center');
        expect(cachedWithNewOrigin.first.distanceMeters, closeTo(0, 0.01));
      },
    );

    test('serializes concurrent Nominatim searches one second apart', () async {
      var now = DateTime.utc(2026, 8, 10, 12);
      final delays = <Duration>[];
      final requestedQueries = <String>[];
      final service = HospitalFinderService(
        client: MockClient((request) async {
          requestedQueries.add(request.url.queryParameters['q']!);
          return http.Response('[]', 200);
        }),
        nominatimEndpoint: Uri.parse('https://example.test/search'),
        now: () => now,
        delay: (duration) async {
          delays.add(duration);
          now = now.add(duration);
        },
      );
      addTearDown(service.close);

      await Future.wait([
        service.search(query: 'Hospital A'),
        service.search(query: 'Hospital B'),
        service.search(query: 'Hospital C'),
      ]);

      expect(requestedQueries, [
        'Hospital A, Philippines',
        'Hospital B, Philippines',
        'Hospital C, Philippines',
      ]);
      expect(delays, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    });
  });
}
