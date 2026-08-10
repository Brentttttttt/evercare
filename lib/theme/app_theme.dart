import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_text_styles.dart';

abstract final class AppRadii {
  static const small = 10.0;
  static const medium = 14.0;
  static const large = 18.0;
  static const extraLarge = 22.0;
  static const sheet = 28.0;
  static const full = 999.0;
}

abstract final class AppTheme {
  static Color? _softOverlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return AppColors.primary.withValues(alpha: .1);
    }
    if (states.contains(WidgetState.hovered)) {
      return AppColors.primary.withValues(alpha: .05);
    }
    if (states.contains(WidgetState.focused)) {
      return AppColors.primary.withValues(alpha: .08);
    }
    return null;
  }

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.primaryForeground,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.primaryContainerForeground,
          secondary: AppColors.secondary,
          onSecondary: AppColors.secondaryForeground,
          secondaryContainer: AppColors.secondary,
          onSecondaryContainer: AppColors.secondaryForeground,
          tertiary: AppColors.blue,
          onTertiary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.foreground,
          surfaceContainerLowest: AppColors.card,
          surfaceContainerLow: const Color(0xFFF7F8F7),
          surfaceContainer: AppColors.secondary,
          surfaceContainerHigh: const Color(0xFFE6EAE7),
          surfaceContainerHighest: const Color(0xFFDEE3DF),
          onSurfaceVariant: AppColors.mutedForeground,
          outline: AppColors.input,
          outlineVariant: AppColors.border,
          error: AppColors.destructive,
          onError: AppColors.destructiveForeground,
          errorContainer: AppColors.destructiveContainer,
          onErrorContainer: AppColors.destructiveContainerForeground,
          shadow: AppColors.shadow,
          scrim: AppColors.overlay,
          inverseSurface: AppColors.foreground,
          onInverseSurface: Colors.white,
          inversePrimary: const Color(0xFF8FD2AE),
        );

    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: AppColors.muted,
      hoverColor: AppColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      constraints: const BoxConstraints(minHeight: 50),
      labelStyle: AppTextStyles.bodyMuted,
      hintStyle: AppTextStyles.bodyMuted.copyWith(
        color: AppColors.mutedForeground.withValues(alpha: .8),
      ),
      helperStyle: AppTextStyles.small,
      errorStyle: AppTextStyles.small.copyWith(
        color: AppColors.destructive,
        fontWeight: FontWeight.w600,
      ),
      errorMaxLines: 2,
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      prefixIconColor: AppColors.mutedForeground,
      suffixIconColor: AppColors.mutedForeground,
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppColors.border, width: .8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppColors.ring, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );

    final menuStyle = MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(AppColors.popover),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(AppColors.shadow),
      elevation: const WidgetStatePropertyAll(4),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      ),
      side: const WidgetStatePropertyAll(
        BorderSide(color: AppColors.border, width: .8),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      shadowColor: AppColors.shadow,
      disabledColor: AppColors.mutedForeground.withValues(alpha: .45),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: NoSplash.splashFactory,
      hoverColor: AppColors.primary.withValues(alpha: .04),
      focusColor: AppColors.primary.withValues(alpha: .08),
      highlightColor: AppColors.primary.withValues(alpha: .055),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: EverCarePageTransitionsBuilder(),
          TargetPlatform.iOS: EverCarePageTransitionsBuilder(),
          TargetPlatform.macOS: EverCarePageTransitionsBuilder(),
          TargetPlatform.windows: EverCarePageTransitionsBuilder(),
          TargetPlatform.linux: EverCarePageTransitionsBuilder(),
          TargetPlatform.fuchsia: EverCarePageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        displayMedium: TextStyle(
          fontSize: 28,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.65,
          color: AppColors.foreground,
        ),
        headlineLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.pageTitle,
        headlineSmall: TextStyle(
          fontSize: 22,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
          color: AppColors.foreground,
        ),
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        titleSmall: TextStyle(
          fontSize: 15,
          height: 1.32,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMuted,
        bodySmall: AppTextStyles.small,
        labelLarge: TextStyle(
          fontSize: 15,
          height: 1.22,
          fontWeight: FontWeight.w600,
          letterSpacing: -.05,
        ),
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.small,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: .2),
        selectionHandleColor: AppColors.primary,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: const WidgetStatePropertyAll(AppColors.muted),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border, width: .8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        textStyle: const WidgetStatePropertyAll(AppTextStyles.body),
        hintStyle: const WidgetStatePropertyAll(AppTextStyles.bodyMuted),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.mutedForeground,
        size: 22,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: AppTextStyles.sectionTitle,
        iconTheme: IconThemeData(color: AppColors.foreground, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.foreground, size: 23),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: const BorderSide(color: AppColors.border, width: .8),
        ),
      ),
      inputDecorationTheme: inputTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.input
                : AppColors.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.mutedForeground.withValues(alpha: .6)
                : AppColors.primaryForeground,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Colors.black.withValues(alpha: .08)
                : states.contains(WidgetState.hovered)
                ? Colors.white.withValues(alpha: .06)
                : null,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const WidgetStatePropertyAll(AppColors.card),
          foregroundColor: const WidgetStatePropertyAll(AppColors.foreground),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(AppColors.shadow),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border, width: .8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.mutedForeground.withValues(alpha: .55)
                : AppColors.foreground,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? AppColors.border.withValues(alpha: .65)
                  : AppColors.border,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          foregroundColor: const WidgetStatePropertyAll(
            AppColors.mutedForeground,
          ),
          shape: WidgetStatePropertyAll(const CircleBorder()),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: .8,
        focusElevation: 1,
        hoverElevation: 1.2,
        highlightElevation: .2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        selectedColor: AppColors.primaryContainer,
        secondarySelectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.muted,
        checkmarkColor: AppColors.primaryContainerForeground,
        iconTheme: const IconThemeData(size: 18, color: AppColors.primary),
        side: const BorderSide(color: AppColors.border, width: .7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
        labelStyle: const TextStyle(
          color: AppColors.foreground,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryContainerForeground,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.quick,
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.foreground
                : AppColors.mutedForeground,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.card
                : AppColors.secondary,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Colors.transparent),
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? .35 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.shadow),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.bodyMuted,
        actionsPadding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        modalBackgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 4,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: AppColors.input,
        dragHandleSize: Size(36, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 6,
        headerBackgroundColor: AppColors.card,
        headerForegroundColor: AppColors.foreground,
        dividerColor: AppColors.border,
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.primary),
        todayBorder: const BorderSide(color: AppColors.primary, width: 1.25),
        dayOverlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        yearOverlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.extraLarge),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.mutedForeground,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.card,
        elevation: 6,
        hourMinuteColor: AppColors.muted,
        hourMinuteTextColor: AppColors.foreground,
        dayPeriodColor: AppColors.muted,
        dayPeriodTextColor: AppColors.foreground,
        dialBackgroundColor: AppColors.muted,
        dialHandColor: AppColors.primary,
        dialTextColor: AppColors.foreground,
        entryModeIconColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.extraLarge),
        ),
      ),
      menuTheme: MenuThemeData(style: menuStyle),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.foreground),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: inputTheme,
        menuStyle: menuStyle,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.popover,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 4,
        textStyle: AppTextStyles.body.copyWith(fontSize: 15),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.foreground,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: const BorderSide(color: AppColors.border, width: .8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mutedForeground,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
        overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.foreground,
        iconColor: AppColors.mutedForeground,
        selectedColor: AppColors.primaryContainerForeground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 28,
        horizontalTitleGap: 12,
        minVerticalPadding: 11,
        titleTextStyle: AppTextStyles.cardTitle.copyWith(fontSize: 16),
        subtitleTextStyle: AppTextStyles.bodyMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        textColor: AppColors.foreground,
        collapsedTextColor: AppColors.foreground,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.mutedForeground,
        backgroundColor: AppColors.card,
        collapsedBackgroundColor: AppColors.card,
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: .8),
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
        ),
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: .8),
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.foreground,
        actionTextColor: const Color(0xFFA6E3C1),
        disabledActionTextColor: Colors.white.withValues(alpha: .5),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: .8,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        elevation: 0,
        indicatorColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        height: 76,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.mutedForeground,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryContainerForeground
                : AppColors.mutedForeground,
            fontSize: 11.5,
            height: 1.2,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith(_softOverlay),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
        refreshBackgroundColor: AppColors.card,
        linearMinHeight: 7,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.input,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: .12),
        valueIndicatorColor: AppColors.foreground,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.mutedForeground.withValues(alpha: .4),
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(AppRadii.full),
        interactive: true,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.destructive,
        textColor: AppColors.destructiveForeground,
        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.foreground,
          borderRadius: BorderRadius.circular(AppRadii.small),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        waitDuration: const Duration(milliseconds: 450),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryForeground
              : AppColors.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.input,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.card,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.primaryForeground),
        side: const BorderSide(color: AppColors.input, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.mutedForeground,
        ),
      ),
    );
  }
}
