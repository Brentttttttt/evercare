import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

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
  static const _destinations = [
    _NavigationItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavigationItem(
      'Health',
      Icons.monitor_heart_outlined,
      Icons.monitor_heart_rounded,
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
      minimum: const EdgeInsets.fromLTRB(10, 5, 10, 9),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 7, 5, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      height: 62,
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
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: index == _currentPage ? 17 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primaryGreen
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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
      duration: const Duration(milliseconds: 320),
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
        ? const Color(0xFFFFE9E5)
        : AppColors.lightGreen;
    return PressScale(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: selected ? selectedColor : AppColors.secondaryText,
                  ),
                  const SizedBox(height: 3),
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
                            ? FontWeight.w800
                            : FontWeight.w600,
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
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          iconSize: 25,
          visualDensity: VisualDensity.compact,
          color: AppColors.darkGreen,
          disabledColor: AppColors.border,
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
