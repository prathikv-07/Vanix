import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import 'vanix_bottom_nav.dart';

/// Builds the standard 5-tab item set with the Events badge/dot wired to
/// AppState.openEventsCount — every screen's nav bar stays in sync since
/// they all read the same counter (mirrors the JS evUpdateBadges()).
List<VanixNavItem> buildVanixNavItems(VanixStrings t, AppState appState) {
  final count = appState.openEventsCount;
  return [
    VanixNavItem(icon: Icons.home_outlined, label: t.navHome, showDot: count > 0),
    // Farms — the village/buildings glyph (assets/images/Farm_Icon.svg),
    // matching the `fill="currentColor"` SVG in prototype.html's nav
    // (viewBox 483.312×483.312) — not a cow-head icon.
    VanixNavItem(
      iconBuilder: (color) => SvgPicture.asset('assets/images/Farm_Icon.svg', width: 20, height: 20, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
      label: t.navFarms,
    ),
    VanixNavItem(icon: Icons.water_drop_outlined, label: t.navMilk),
    VanixNavItem(icon: Icons.calendar_today_outlined, label: t.navEvents, badgeCount: count),
    // Plain person silhouette (head + shoulders, no outer ring) — matches the
    // bust-only SVG in vanix_screens_preview.html's nav; account_circle_outlined
    // draws an extra circular frame the HTML icon doesn't have.
    VanixNavItem(icon: Icons.person_outline, label: t.navAccount),
  ];
}
