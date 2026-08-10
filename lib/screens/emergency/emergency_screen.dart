import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/emergency_guidance.dart';
import '../../models/emergency_contact.dart';
import '../../repositories/emergency_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import '../hospitals/hospital_finder_screen.dart';
import 'emergency_contacts_screen.dart';
import 'emergency_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  EmergencyRepository? _repository;
  List<EmergencyContact> _contacts = const [];
  bool _initialized = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      _loading = false;
      return;
    }
    _repository = EmergencyRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final primary = _contacts.cast<EmergencyContact?>().firstWhere(
      (contact) => contact?.isPrimary == true,
      orElse: () => null,
    );
    final otherContacts = _contacts
        .where((contact) => contact.id != primary?.id)
        .toList(growable: false);
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: mainPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/emergency_preparedness.png',
            semanticLabel:
                'A daughter reassuring an older woman beside a prepared care bag and medical folder',
            title: 'Prepared care brings peace of mind',
            subtitle: 'Keep trusted contacts and important details nearby.',
            height: 148,
          ),
          const SizedBox(height: 16),
          _EmergencyHotlineCard(onCopy: () => _copyNumber('143')),
          const SizedBox(height: 14),
          _EmergencyHospitalFinderCard(onOpen: _openHospitalFinder),
          const SizedBox(height: 30),
          if (_loading)
            const _EmergencyDetailsLoading()
          else if (_repository == null)
            const EmptyStateCard(
              title: 'Sign in to add emergency contacts',
              message:
                  'Your trusted contacts are saved privately with your EverCare account.',
              icon: Icons.lock_outline_rounded,
            )
          else if (_error != null)
            _EmergencyLoadError(message: _error!, onRetry: _load)
          else ...[
            SectionHeader(
              title: 'Emergency contacts',
              subtitle: 'People you trust, such as a partner or relative',
              actionLabel: 'Manage',
              onAction: _openContacts,
            ),
            const SizedBox(height: 12),
            _AddEmergencyContactCard(onTap: _openAddContact),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Primary emergency contact',
              subtitle: 'The trusted person to contact first',
            ),
            const SizedBox(height: 12),
            if (primary == null)
              EmptyStateCard(
                title: 'No primary contact yet',
                message: 'Add a trusted contact and mark them as primary.',
                icon: Icons.contact_emergency_outlined,
              )
            else
              EmergencyContactCard(
                contact: primary,
                onCopyNumber: () => _copyNumber(primary.phoneNumber),
                onDetails: _openContacts,
              ),
            if (otherContacts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Other emergency contacts',
                subtitle: 'Your additional trusted contacts',
              ),
              const SizedBox(height: 12),
              ...otherContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: EmergencyContactCard(
                    contact: contact,
                    onCopyNumber: () => _copyNumber(contact.phoneNumber),
                    onDetails: _openContacts,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'While waiting for help',
            subtitle: 'Simple reminders during an emergency',
          ),
          const SizedBox(height: 12),
          const EmergencyChecklistCard(
            items: EmergencyGuidance.waitingChecklist,
          ),
          const SizedBox(height: 8),
          const Text(
            'These are general safety reminders, not medical advice. Always follow instructions from qualified emergency personnel.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contacts = await repository.fetchContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'EverCare could not load your emergency details. Please try again.';
      });
    }
  }

  Future<void> _copyNumber(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phoneNumber copied. Open your Phone app to call.'),
      ),
    );
  }

  Future<void> _openContacts() async {
    await Navigator.pushNamed(context, AppRoutes.emergencyContacts);
    if (mounted) await _load();
  }

  Future<void> _openAddContact() async {
    await Navigator.push<void>(
      context,
      EverCarePageRoute(
        builder: (_) => const EmergencyContactsScreen(startAdding: true),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openHospitalFinder() async {
    await Navigator.push<void>(
      context,
      EverCarePageRoute(builder: (_) => const HospitalFinderScreen()),
    );
  }
}

class _AddEmergencyContactCard extends StatelessWidget {
  const _AddEmergencyContactCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add your own emergency contact',
      hint:
          'Enter the name, relationship, and phone number of a trusted person',
      child: Material(
        color: AppColors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.primaryGreen.withValues(alpha: .16),
            width: .7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('emergency-add-contact'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add your own emergency contact',
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Partner, family member, relative, or trusted person',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryGreen,
                    size: 27,
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

class _EmergencyHotlineCard extends StatelessWidget {
  const _EmergencyHotlineCard({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Philippine Red Cross emergency hotline 143',
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7F5), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1D8D2), width: .8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F1712),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.destructiveContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: AppColors.danger,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need immediate help?',
                          style: AppTextStyles.sectionTitle,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Philippine emergency support',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('PHILIPPINE RED CROSS', style: AppTextStyles.eyebrow),
              const SizedBox(height: 2),
              Text(
                '143',
                style: AppTextStyles.metric.copyWith(
                  color: AppColors.danger,
                  fontSize: 48,
                  height: 1,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Emergency hotline', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCopy,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy hotline number'),
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'EverCare copies the number only. Open your Phone app and dial the copied number to place the call.',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyHospitalFinderCard extends StatelessWidget {
  const _EmergencyHospitalFinderCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Find nearby emergency hospitals',
      hint: 'Opens the hospital map',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: .72),
            width: .7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Nearby Emergency Hospitals',
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'View nearby care and driving directions',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedForeground,
                    size: 28,
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

class _EmergencyDetailsLoading extends StatelessWidget {
  const _EmergencyDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading emergency details',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Loading emergency details',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 9),
            FractionallySizedBox(
              widthFactor: .68,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyLoadError extends StatelessWidget {
  const _EmergencyLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 24,
                color: AppColors.warning,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency details unavailable',
                  style: AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
