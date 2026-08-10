import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';
import 'app_glass_surface.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  static const _itemsPerPage = 3;
  static const _pageLabels = [
    'Daily care',
    'Planning and memories',
    'Safety and account',
  ];
  static const _destinations = [
    _NavigationItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavigationItem(
      'Health',
      Icons.favorite_border_rounded,
      Icons.favorite_rounded,
    ),
    _NavigationItem(
      'Medicine',
      Icons.medication_outlined,
      Icons.medication_rounded,
    ),
    _NavigationItem(
      'Visits',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    _NavigationItem(
      'Journals',
      Icons.auto_stories_outlined,
      Icons.auto_stories_rounded,
    ),
    _NavigationItem(
      'Care Book',
      Icons.menu_book_outlined,
      Icons.menu_book_rounded,
    ),
    _NavigationItem(
      'Emergency',
      Icons.sos_outlined,
      Icons.sos_rounded,
      danger: true,
    ),
    _NavigationItem(
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  late final PageController _pageController;
  late int _currentPage = widget.selectedIndex ~/ _itemsPerPage;

  int get _pageCount => (_destinations.length / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant AppBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetPage = widget.selectedIndex ~/ _itemsPerPage;
    if (targetPage != _currentPage) {
      _currentPage = targetPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(28),
        blurSigma: 32,
        tint: Colors.white.withValues(alpha: .34),
        borderColor: Colors.white.withValues(alpha: .88),
        boxShadow: const [],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Semantics(
                  liveRegion: true,
                  label:
                      '${_pageLabels[_currentPage]}, navigation group ${_currentPage + 1} of $_pageCount',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _pageLabels[_currentPage],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.eyebrow.copyWith(
                            color: AppColors.darkGreen,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      Text(
                        '${_currentPage + 1} of $_pageCount',
                        style: AppTextStyles.small.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _PageArrow(
                    icon: Icons.chevron_left_rounded,
                    label: 'Previous navigation pages',
                    enabled: _currentPage > 0,
                    onPressed: () => _goToPage(_currentPage - 1),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pageCount,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        itemBuilder: (context, page) => _buildPage(page),
                      ),
                    ),
                  ),
                  _PageArrow(
                    icon: Icons.chevron_right_rounded,
                    label: 'Next navigation pages',
                    enabled: _currentPage < _pageCount - 1,
                    onPressed: () => _goToPage(_currentPage + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int page) {
    final start = page * _itemsPerPage;
    return Row(
      children: List.generate(_itemsPerPage, (offset) {
        final index = start + offset;
        if (index >= _destinations.length) {
          return const Expanded(child: SizedBox.shrink());
        }
        final destination = _destinations[index];
        return Expanded(
          child: _BottomDestination(
            item: destination,
            selected: widget.selectedIndex == index,
            onTap: () => widget.onDestinationSelected(index),
          ),
        );
      }),
    );
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _pageCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = item.danger ? AppColors.danger : AppColors.darkGreen;
    final selectedBackground = item.danger
        ? const Color(0xFFFFE9E5).withValues(alpha: .88)
        : AppColors.lightGreen.withValues(alpha: .78);
    return PressScale(
      pressedScale: .96,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 21,
                    color: selected ? selectedColor : AppColors.secondaryText,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? selectedColor
                            : AppColors.secondaryText,
                        fontSize: 10.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: -.08,
                      ),
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

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: enabled,
      pressedScale: .92,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          iconSize: 23,
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 48),
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
          color: AppColors.darkGreen,
          disabledColor: AppColors.secondaryText.withValues(alpha: .24),
          tooltip: label,
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(
    this.label,
    this.icon,
    this.selectedIcon, {
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool danger;
}
