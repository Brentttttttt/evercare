import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A quiet account action, with no translucent surface or elevation shadow.
class LogoutActionTile extends StatelessWidget {
  const LogoutActionTile({
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    final label = isLoading ? 'Signing out…' : 'Log Out';
    const foreground = AppColors.destructiveContainerForeground;
    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      liveRegion: isLoading,
      label: label,
      hint: isLoading ? null : 'End your EverCare session on this device',
      child: ExcludeSemantics(
        child: Material(
          key: const ValueKey('logout-tile-surface'),
          color: AppColors.destructiveContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEED5D2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            splashColor: foreground.withValues(alpha: .06),
            highlightColor: foreground.withValues(alpha: .035),
            focusColor: foreground.withValues(alpha: .10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: foreground,
                              ),
                            )
                          : const Icon(
                              Icons.logout_rounded,
                              color: foreground,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      const SizedBox(width: 20)
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: foreground,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
