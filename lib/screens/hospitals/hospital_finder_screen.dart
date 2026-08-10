import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/hospital_location.dart';
import '../../services/hospital_finder_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({
    super.key,
    this.allowSelection = false,
    this.autoLocate = true,
    this.showMapTiles = true,
    this.service,
  });

  final bool allowSelection;
  final bool autoLocate;
  final bool showMapTiles;
  final HospitalFinderService? service;

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  static const _philippines = LatLng(12.8797, 121.7740);
  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'com.example.evercare';

  final _searchController = TextEditingController();
  final _mapController = MapController();
  Timer? _searchDebounce;
  late final HospitalFinderService _service;
  late final bool _ownsService;
  Position? _position;
  List<HospitalLocation> _hospitals = const [];
  HospitalLocation? _selected;
  LocationAccessIssue? _locationIssue;
  String? _error;
  bool _loading = false;
  bool _resolvingSelection = false;
  bool _hasSearched = false;
  int _searchRevision = 0;
  int _operationRevision = 0;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? HospitalFinderService();
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _findNearby());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    if (_ownsService) _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          EverCareHeader(
            title: widget.allowSelection
                ? 'Choose a Hospital'
                : 'Nearby Emergency Hospitals',
            subtitle: 'OpenStreetMap hospital finder',
            showBack: true,
          ),
          Expanded(child: SafeArea(top: false, child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _philippines,
                  initialZoom: 5.4,
                  minZoom: 4,
                  maxZoom: 19,
                ),
                children: [
                  if (widget.showMapTiles)
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: _userAgentPackageName,
                      maxNativeZoom: 19,
                    ),
                  MarkerLayer(markers: _markers),
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    alignment: AttributionAlignment.bottomLeft,
                    attributions: [
                      LogoSourceAttribution(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        tooltip: 'OpenStreetMap copyright and attribution',
                        onTap: _openOpenStreetMapCopyright,
                      ),
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: _openOpenStreetMapCopyright,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _MapSearchBar(
                  controller: _searchController,
                  loading: _loading || _resolvingSelection,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  onSearch: _submitSearch,
                ),
              ),
              Positioned(
                top: 78,
                right: 12,
                child: _GlassMapControl(
                  child: IconButton(
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    tooltip: 'Find hospitals near my location',
                    onPressed: _loading || _resolvingSelection
                        ? null
                        : _findNearby,
                    color: AppColors.primaryGreen,
                    icon: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ),
              if (_loading || _resolvingSelection)
                const Positioned(top: 82, left: 12, child: _LoadingPill()),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x180D1811),
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Expanded(child: _buildResults()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_locationIssue != null && _hospitals.isEmpty) {
      return _LocationHelp(
        issue: _locationIssue!,
        onRetry: _findNearby,
        onSettings: _openRelevantSettings,
      );
    }
    if (_error != null && _hospitals.isEmpty) {
      return _FinderMessage(
        icon: Icons.map_outlined,
        title: 'Hospitals could not be loaded',
        message: _error!,
        actionLabel: 'Try Again',
        onAction: _hasSearched ? _submitSearch : _findNearby,
      );
    }
    if (_loading && _hospitals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hospitals.isEmpty) {
      return _FinderMessage(
        icon: Icons.local_hospital_outlined,
        title: _hasSearched ? 'No hospitals found' : 'Find nearby hospitals',
        message: _hasSearched
            ? 'Try another hospital name, city, or province.'
            : 'Allow location access to see hospitals near you, or search by name.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _hasSearched
                      ? '${_hospitals.length} search results'
                      : '${_hospitals.length} hospitals nearby',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              InkWell(
                onTap: _openOpenStreetMapCopyright,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text('© OpenStreetMap', style: AppTextStyles.small),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(14, 7, 14, 24),
            itemCount: _hospitals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final hospital = _hospitals[index];
              return _HospitalResultCard(
                hospital: hospital,
                selected: hospital.id == _selected?.id,
                allowSelection: widget.allowSelection,
                onTap: () => _selectHospital(hospital),
                onPrimaryAction: () => _selectHospital(hospital),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Marker> get _markers {
    final markers = <Marker>[];
    final position = _position;
    if (position != null) {
      markers.add(
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 42,
          height: 42,
          child: Semantics(
            label: 'Your current location',
            child: const Tooltip(
              message: 'Your location',
              child: _UserLocationMarker(),
            ),
          ),
        ),
      );
    }
    markers.addAll(
      _hospitals.map((hospital) {
        final selected = hospital.id == _selected?.id;
        return Marker(
          key: ValueKey(hospital.id),
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 48,
          height: 52,
          alignment: Alignment.topCenter,
          child: Semantics(
            button: true,
            label: '${hospital.name}, ${hospital.distanceLabel}',
            child: Tooltip(
              message: hospital.name,
              child: GestureDetector(
                onTap: () => _selectHospital(hospital),
                child: _HospitalMapMarker(selected: selected),
              ),
            ),
          ),
        );
      }),
    );
    return markers;
  }

  Future<void> _findNearby() async {
    if (_loading) return;
    _searchDebounce?.cancel();
    final operation = ++_operationRevision;
    setState(() {
      _loading = true;
      _hasSearched = false;
      _locationIssue = null;
      _error = null;
    });
    try {
      final position = await _service.currentPosition();
      if (!mounted || operation != _operationRevision) return;
      setState(() => _position = position);
      _focusPosition(position);
      final hospitals = await _service.findNearby(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || operation != _operationRevision) return;
      setState(() {
        _hospitals = hospitals;
        _selected = hospitals.firstOrNull;
        _loading = false;
      });
    } on LocationAccessException catch (error) {
      if (!mounted || operation != _operationRevision) return;
      setState(() {
        _loading = false;
        _locationIssue = error.issue;
      });
    } on HospitalFinderException catch (error) {
      if (!mounted || operation != _operationRevision) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted || operation != _operationRevision) return;
      setState(() {
        _loading = false;
        _error =
            'The nearby-hospital service is unavailable right now. Check your internet connection and try again.';
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final revision = ++_searchRevision;
    final query = value.trim();
    if (query.length < 3) {
      _operationRevision++;
      setState(() {
        _loading = false;
        _hasSearched = false;
        _error = null;
      });
      return;
    }
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || revision != _searchRevision) return;
      _searchHospitals(query: query, searchRevision: revision);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchRevision++;
    _operationRevision++;
    _searchController.clear();
    setState(() {
      _loading = false;
      _hasSearched = false;
      _error = null;
    });
  }

  Future<void> _submitSearch() async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final revision = ++_searchRevision;
    FocusScope.of(context).unfocus();
    await _searchHospitals(
      query: query,
      searchRevision: revision,
      submitted: true,
    );
  }

  Future<void> _searchHospitals({
    required String query,
    required int searchRevision,
    bool submitted = false,
  }) async {
    if (query.length < 3 && !submitted) return;
    final operation = ++_operationRevision;
    setState(() {
      _loading = true;
      _hasSearched = true;
      _locationIssue = null;
      _error = null;
    });
    try {
      final hospitals = submitted
          ? await _service.search(
              query: query,
              originLatitude: _position?.latitude,
              originLongitude: _position?.longitude,
            )
          : await _service.suggest(
              query: query,
              originLatitude: _position?.latitude,
              originLongitude: _position?.longitude,
            );
      if (!mounted ||
          operation != _operationRevision ||
          searchRevision != _searchRevision) {
        return;
      }
      setState(() {
        _hospitals = hospitals;
        _selected = hospitals.firstOrNull;
        _loading = false;
      });
      if (hospitals.isNotEmpty) _focusHospital(hospitals.first);
    } on HospitalFinderException catch (error) {
      if (!mounted ||
          operation != _operationRevision ||
          searchRevision != _searchRevision) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted ||
          operation != _operationRevision ||
          searchRevision != _searchRevision) {
        return;
      }
      setState(() {
        _loading = false;
        _error =
            'The hospital search service could not complete that request. Check your internet connection and try again.';
      });
    }
  }

  Future<void> _selectHospital(HospitalLocation hospital) async {
    if (_resolvingSelection) return;
    if (widget.allowSelection) {
      var selectedHospital = hospital;
      if (hospital.address.trim().isEmpty) {
        setState(() => _resolvingSelection = true);
        try {
          selectedHospital = await _service.resolveAddress(hospital);
        } on HospitalFinderException catch (error) {
          if (!mounted) return;
          selectedHospital = _withCoordinateAddress(hospital);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${error.message} The coordinates were added instead.',
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          selectedHospital = _withCoordinateAddress(hospital);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The street address could not be loaded. The coordinates were added instead.',
              ),
            ),
          );
        } finally {
          if (mounted) setState(() => _resolvingSelection = false);
        }
      }
      if (mounted) Navigator.pop(context, selectedHospital);
      return;
    }
    setState(() => _selected = hospital);
    _focusHospital(hospital);
    _showEmergencyHospitalActions(hospital);
  }

  HospitalLocation _withCoordinateAddress(HospitalLocation hospital) {
    return HospitalLocation(
      id: hospital.id,
      name: hospital.name,
      address:
          'Coordinates: ${hospital.latitude.toStringAsFixed(6)}, '
          '${hospital.longitude.toStringAsFixed(6)}',
      latitude: hospital.latitude,
      longitude: hospital.longitude,
      distanceMeters: hospital.distanceMeters,
    );
  }

  void _focusPosition(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), 13);
  }

  void _focusHospital(HospitalLocation hospital) {
    _mapController.move(LatLng(hospital.latitude, hospital.longitude), 14.5);
  }

  Future<void> _openRelevantSettings() async {
    if (_locationIssue == LocationAccessIssue.servicesDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _openOpenStreetMapCopyright() async {
    await launchUrl(
      Uri.parse('https://www.openstreetmap.org/copyright'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _showEmergencyHospitalActions(HospitalLocation hospital) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EmergencyHospitalActions(
        hospital: hospital,
        onDirections: () async {
          Navigator.pop(sheetContext);
          await _openGoogleMapsDirections(hospital);
        },
        onDetails: () async {
          Navigator.pop(sheetContext);
          await _openGoogleMapsHospitalDetails(hospital);
        },
      ),
    );
  }

  Future<void> _openGoogleMapsDirections(HospitalLocation hospital) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${hospital.latitude},${hospital.longitude}',
      'travelmode': 'driving',
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open Google Maps directions.',
    );
  }

  Future<void> _openGoogleMapsHospitalDetails(HospitalLocation hospital) async {
    final searchParts = <String>[
      hospital.name,
      if (hospital.address.isNotEmpty) hospital.address,
      'hospital',
    ];
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': searchParts.join(', '),
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open this hospital in Google Maps.',
    );
  }

  Future<void> _launchExternalGoogleUrl(
    Uri uri, {
    required String failureMessage,
  }) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar({
    required this.controller,
    required this.loading,
    required this.onChanged,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return _GlassMapControl(
      borderRadius: 18,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Search hospital, city, or place',
                  helperText: null,
                  filled: false,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear hospital search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Container(width: 1, height: 28, color: AppColors.border),
            IconButton(
              tooltip: 'Search hospitals',
              onPressed: loading ? null : onSearch,
              constraints: const BoxConstraints.tightFor(width: 52, height: 52),
              color: AppColors.primaryGreen,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassMapControl extends StatelessWidget {
  const _GlassMapControl({required this.child, this.borderRadius = 16});

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.white.withValues(alpha: .91),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: Colors.white.withValues(alpha: .82),
              width: .8,
            ),
          ),
          elevation: 0,
          child: child,
        ),
      ),
    );
  }
}

class _HospitalMapMarker extends StatelessWidget {
  const _HospitalMapMarker({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.12 : 1,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 44 : 40,
        height: selected ? 44 : 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : AppColors.primaryGreen,
            width: selected ? 3 : 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          selected ? Icons.check_rounded : Icons.local_hospital_rounded,
          size: 21,
          color: selected ? Colors.white : AppColors.primaryGreen,
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF2585E6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x2A000000), blurRadius: 6)],
      ),
    );
  }
}

class _HospitalResultCard extends StatelessWidget {
  const _HospitalResultCard({
    required this.hospital,
    required this.selected,
    required this.allowSelection,
    required this.onTap,
    required this.onPrimaryAction,
  });

  final HospitalLocation hospital;
  final bool selected;
  final bool allowSelection;
  final VoidCallback onTap;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${hospital.name}, ${hospital.distanceLabel}',
      hint: allowSelection
          ? 'Select this hospital'
          : 'Show directions and hospital details',
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? AppColors.primaryGreen
                : AppColors.border.withValues(alpha: .72),
            width: selected ? 1.4 : .7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_rounded
                          : Icons.local_hospital_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        if (hospital.address.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            hospital.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.small,
                          ),
                        ],
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              hospital.distanceLabel,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            if (selected)
                              Text(
                                'Selected',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primaryContainerForeground,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: allowSelection
                        ? 'Use ${hospital.name}'
                        : 'Emergency options for ${hospital.name}',
                    onPressed: onPrimaryAction,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: Icon(
                      allowSelection
                          ? Icons.check_circle_outline_rounded
                          : Icons.chevron_right_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyHospitalActions extends StatelessWidget {
  const _EmergencyHospitalActions({
    required this.hospital,
    required this.onDirections,
    required this.onDetails,
  });

  final HospitalLocation hospital;
  final VoidCallback onDirections;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 22,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hospital.name, style: AppTextStyles.sectionTitle),
                        if (hospital.address.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            hospital.address,
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          hospital.distanceLabel,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Close hospital options',
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: .72),
                    width: .7,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _HospitalActionRow(
                      icon: Icons.directions_rounded,
                      title: 'Get Directions in Google Maps',
                      subtitle: 'Open turn-by-turn driving directions',
                      onTap: onDirections,
                      emphasized: true,
                    ),
                    const Divider(
                      height: 1,
                      indent: 68,
                      color: AppColors.border,
                    ),
                    _HospitalActionRow(
                      icon: Icons.contact_phone_outlined,
                      title: 'Find Contact Number & Details',
                      subtitle: 'Check phone numbers and current information',
                      onTap: onDetails,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Google Maps opens outside EverCare. Verify the hospital\'s contact details and availability before traveling when possible.',
                        style: AppTextStyles.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HospitalActionRow extends StatelessWidget {
  const _HospitalActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: emphasized
                        ? AppColors.primaryGreen
                        : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: emphasized ? Colors.white : AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.small),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedForeground,
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationHelp extends StatelessWidget {
  const _LocationHelp({
    required this.issue,
    required this.onRetry,
    required this.onSettings,
  });

  final LocationAccessIssue issue;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final servicesDisabled = issue == LocationAccessIssue.servicesDisabled;
    final deniedForever = issue == LocationAccessIssue.permissionDeniedForever;
    return _FinderMessage(
      icon: Icons.location_off_outlined,
      title: servicesDisabled
          ? 'Turn on device location'
          : 'Location access is needed',
      message: servicesDisabled
          ? 'Enable Location Services, then return to find nearby hospitals.'
          : 'EverCare uses your location only to search for hospitals near you. You can still type a hospital name above.',
      actionLabel: servicesDisabled || deniedForever
          ? 'Open Settings'
          : 'Retry',
      onAction: servicesDisabled || deniedForever ? onSettings : onRetry,
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 9),
          Text('Finding hospitals…', style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _FinderMessage extends StatelessWidget {
  const _FinderMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryGreen),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
