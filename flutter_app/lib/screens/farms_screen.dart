import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../i18n/farm_strings.dart';
import '../i18n/strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';
import 'account_screen.dart';
import 'farm_detail_screen.dart';
import 'setup_farm_screen.dart';

// ── Dark-surface literals with no token in VanixColors yet ──
// Measured off #flow-root.dark: `--bgcard` flips to #1E1E1E and `--border`
// to #333333, which is what the farm stat chips / setup pill / filter-sheet
// rail resolve to. VanixColors only carries darkSecond (#1C1C1C) and
// darkBorder (#3A3A3A), so these two need locals until the shared theme
// grows tokens for them.
const Color _darkBgCard = Color(0xFF1E1E1E);
const Color _darkBorderSoft = Color(0xFF333333);
// `--bgwarm` in dark — used by the sheet's ✕ button and the trigger dot ring.
const Color _darkBgWarm = Color(0xFF121212);

/// Farms list — screen 05. Mirrors #page-farms in prototype.html: hero
/// (title, 3 stat tiles — no subtitle/ticker, both were removed from the
/// HTML), search + two-pane filter sheet (Status single-select / Location
/// multi-select, `.s7-chip` radio/checkbox rows, Reset + ✕ + Apply + Cancel
/// injected by the shared `wireFilterSheet()`), and the farm cards straight
/// into the list (no "Your Farms" heading — that text is dead/unused in the
/// current HTML) with a corner severity tag, cattle count, and 5 stat chips
/// (Heat / Insemination / Pregnant / Fever / Milk Today). Setup farms render
/// as a row with a "Setup Farm" pill.
///
/// Measured traps this file encodes:
///  • `.farm-row { border: none !important }` kills the inline 1px border —
///    the cards are shadow-only (VanixShadow.card), including the setup row
///    whose inline `1px dashed` never renders.
///  • `#farms-fs-sheet h3` is forced to **17px** by a later `!important`
///    rule, not the inline 20px.
///  • `.s7-cat`'s inline `border:none` beats the stylesheet's
///    `border-bottom`, so the rail rows have **no** divider — only the
///    `!important` 5px `border-inline-start` survives.
///  • In dark, `#flow-root.dark .m-hero p[class~="en"]` (1,3,1) outranks
///    `.m-stat-card p` (1,2,1), so the big stat numbers go --text2, not white.
///  • In dark, `#flow-root.dark #page-farms > div` also matches
///    `#farms-fs-sheet` (a direct child of #page-farms) and outranks the
///    sheet rule, so this sheet's background is #111111, not #1E1E1E.
///  • Every `class="en"` number renders in the Latin face NotoSans.
class FarmsScreen extends StatefulWidget {
  final AppState appState;
  const FarmsScreen({super.key, required this.appState});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  final int _navIndex = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all'; // all | healthy | attention | setup (single-select)
  List<String> _locFilter = const ['all']; // coimbatore | erode | salem (multi-select)

  bool get _hasActiveFilter => _statusFilter != 'all' || !(_locFilter.length == 1 && _locFilter.first == 'all');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _statusKey(FarmStatus s) {
    switch (s) {
      case FarmStatus.healthy:
        return 'healthy';
      case FarmStatus.attention:
        return 'attention';
      case FarmStatus.setup:
        return 'setup';
    }
  }

  List<FarmModel> get _filtered {
    final q = _query.trim().toLowerCase();
    return kFarms.where((f) {
      // Setting up a new farm is owner-only — Manager persona never sees
      // the "Setup Farm" row.
      if (widget.appState.isManager && f.status == FarmStatus.setup) return false;
      if (_statusFilter != 'all' && _statusKey(f.status) != _statusFilter) return false;
      if (!(_locFilter.length == 1 && _locFilter.first == 'all') && !_locFilter.contains(f.locKey)) return false;
      if (q.isNotEmpty && !('${f.name} ${f.nameHi}').toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1:
        break; // current
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
    }
  }

  void _openFarm(FarmModel farm) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FarmDetailScreen(appState: widget.appState, farm: farm)))
        .then((_) => setState(() {}));
  }

  void _openSetupFarm(FarmModel farm) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SetupFarmScreen(appState: widget.appState, farm: farm)))
        .then((_) => setState(() {}));
  }

  void _openFilterSheet() {
    final lang = widget.appState.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FarmsFilterSheet(
        lang: lang,
        isDark: widget.appState.isDark,
        status: _statusFilter,
        location: _locFilter,
        onApply: (status, loc) => setState(() {
          _statusFilter = status;
          _locFilter = loc;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final lang = widget.appState.languageCode;
        final t = VanixStrings.of(lang);
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;

        final list = _filtered;
        final totalFarms = kFarms.where((f) => f.status != FarmStatus.setup).length;
        final totalCattle = kFarms.fold<int>(0, (s, f) => s + f.cattle);
        final totalAlerts = kFarms.fold<int>(0, (s, f) => s + f.alerts);

        return Theme(
          data: theme,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: ListView(
                      // #page-farms scroll container: padding:0 0 120px.
                      padding: const EdgeInsetsDirectional.only(bottom: 120),
                      children: [
                        _buildHero(isDark, lang, textColor, totalFarms, totalCattle, totalAlerts),
                        // The div wrapping search + list: padding:14px 16px 0.
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              Expanded(child: _buildSearch(isDark, lang)),
                              const SizedBox(width: 8),
                              _FilterButton(isDark: isDark, active: _hasActiveFilter, onTap: _openFilterSheet),
                            ],
                          ),
                        ),
                        // #farms-list { margin-top:10px }.
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 0),
                          child: list.isEmpty
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(top: 24),
                                  child: Center(
                                    child: Text(FS.t(lang, 'noFarmsMatch'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final f in list)
                                      f.status == FarmStatus.setup
                                          ? _SetupFarmRow(farm: f, lang: lang, isDark: isDark, onTap: () => _openSetupFarm(f))
                                          : _FarmCard(farm: f, lang: lang, isDark: isDark, isOwner: widget.appState.isOwner, onTap: () => _openFarm(f)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: isDark,
                    selectedIndex: _navIndex,
                    onTap: _onNavTap,
                    items: buildVanixNavItems(t, widget.appState),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // `.m-hero` in #page-farms: padding 18px 16px, border-radius 0 0 14px 14px,
  // box-shadow 0 12px 28px rgba(0,0,0,0.18) — deepened to 0.55 in dark, where
  // the hero surface is #1C1C1C.
  Widget _buildHero(bool isDark, String lang, Color textColor, int totalFarms, int totalCattle, int totalAlerts) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(FS.t(lang, 'farmsTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatTile(value: '$totalFarms', label: FS.t(lang, 'wordFarmsShort'), isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$totalCattle', label: FS.t(lang, 'wordCattleShort'), isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(value: '$totalAlerts', label: FS.t(lang, 'wordAlertsShort'), isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  // `.farms-search-wrap`: height 46, radius 14, 1px --border, padding 0 14,
  // gap 8, 16px search glyph stroked --text2, 14px --text1 input text.
  Widget _buildSearch(bool isDark, String lang) {
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: VanixColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 14, color: isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                hintText: FS.t(lang, 'searchFarms'),
                hintStyle: const TextStyle(fontSize: 14, color: VanixColors.textHint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero pieces ──────────────────────────────────────────────

// `.m-stat-card`: padding 14px 8px, radius 16, 1px --border, plus the shared
// Airbnb card shadow. The big number is `class="en"` → NotoSans, and in dark
// it resolves to --text2 (#8C8780), not #F5F5F5 — see the class doc.
class _StatTile extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatTile({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSans',
                  color: isDark ? VanixColors.textHint : VanixColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}

// ── Filter button ───────────────────────────────────────────

// `#farms-filter-btn`: 46x46, radius 14, 1px --border, 15px funnel stroked
// --text1. `.fs-trigger-dot` — a 10px greenInk dot with a 2px --bgwarm ring
// at top:-2/right:-2 once any filter is applied.
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.isDark, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
            ),
            child: Center(child: FunnelIcon(size: 15, color: isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary)),
          ),
          if (active)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: VanixColors.greenInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? _darkBgWarm : VanixColors.bgWarm, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Farm cards ───────────────────────────────────────────────

// `.farm-row`: radius 18, padding 14, margin-bottom 12, overflow hidden.
// The inline `border:1px solid var(--border)` is dead — `.farm-row { border:
// none !important }` strips it, leaving the shared card shadow as the only
// elevation.
class _FarmCard extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final bool isOwner;
  final VoidCallback onTap;
  const _FarmCard({required this.farm, required this.lang, required this.isDark, required this.isOwner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    final attention = farm.status == FarmStatus.attention;
    final tagBg = attention ? VanixColors.danger : VanixColors.greenInk;
    final tagLabel = attention ? FS.t(lang, 'sevCritical') : FS.t(lang, 'healthyWord');

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Stack(
            children: [
              // `cornerTag()`: radius 0 17px 0 12px, padding 5px 14px 6px 16px,
              // 10px/700 white with letter-spacing .06em (= 0.6px), `class="en"`.
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 14, 6),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: const BorderRadiusDirectional.only(
                      topEnd: Radius.circular(17),
                      bottomStart: Radius.circular(12),
                    ),
                  ),
                  child: Text(tagLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontFamily: 'NotoSans',
                          color: VanixColors.textOnDark)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(farm.nm(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 3),
                              _MetaLine(icon: Icons.place_outlined, text: farm.loc(lang)),
                              // Manager name — owner-only (a Manager doesn't
                              // need to see their own name on their own farm).
                              if (isOwner) ...[
                                const SizedBox(height: 2),
                                _MetaLine(icon: Icons.person_outline, text: farm.mgr(lang)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 28, end: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset('assets/images/GroupCow_Icon.svg',
                                  width: 15, height: 15, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                              const SizedBox(width: 4),
                              Text('${farm.cattle}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'NotoSans', color: textColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Chip(isDark: isDark, value: '${farm.heat}', label: FS.t(lang, 'cattleHeat')),
                        const SizedBox(width: 6),
                        _Chip(isDark: isDark, value: '${farm.insem}', label: FS.t(lang, 'insemWord')),
                        const SizedBox(width: 6),
                        _Chip(isDark: isDark, value: '${farm.preg}', label: FS.t(lang, 'statusPregnantChip')),
                        const SizedBox(width: 6),
                        _Chip(isDark: isDark, value: '${farm.fever}', label: FS.t(lang, 'cattleFever')),
                        const SizedBox(width: 6),
                        _Chip(isDark: isDark, value: '${farm.milkToday} L', label: FS.t(lang, 'statMilkToday')),
                      ],
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

// PIN_SVG / PERSON_SVG: 11px glyphs with margin-inline-end:3px, stroked with
// the paragraph's own --text2 colour.
class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: VanixColors.textHint),
        const SizedBox(width: 3),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
        ),
      ],
    );
  }
}

// `farmChip()` — the `bg`/`color` params that function accepts are dead code
// (never referenced in the returned markup); every chip is plain
// `var(--bgcard)` with a `var(--border)` outline, radius 12, padding 8px 4px,
// a 14/700 `class="en"` value and a 9/600 --text2 label. In dark, --bgcard is
// #1E1E1E and --border is #333333 (not the darkSecond/darkBorder pair the
// hero tiles use).
class _Chip extends StatelessWidget {
  final bool isDark;
  final String value, label;
  const _Chip({required this.isDark, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? _darkBgCard : VanixColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? _darkBorderSoft : VanixColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'NotoSans', color: textColor)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: VanixColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// The setup variant of `.farm-row`: align-items center, gap 10. Its inline
// `1px dashed var(--border)` is stripped by the same
// `.farm-row { border:none !important }`, so it is shadow-only too — there is
// no dashed outline in the real render.
class _SetupFarmRow extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final VoidCallback onTap;
  const _SetupFarmRow({required this.farm, required this.lang, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farm.nm(lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 2),
                    Text('${FS.t(lang, 'notSetUp')} · 0 ${FS.t(lang, 'wordCattle')}',
                        style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // `.farm-setup-pill`: height 36, radius 18, padding 0 14,
              // 1px --border, 12/600 --text1.
              Container(
                height: 36,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? _darkBgCard : VanixColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? _darkBorderSoft : VanixColors.border),
                ),
                child: Text(FS.t(lang, 'setupFarm'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Two-pane filter sheet ────────────────────────────────────

// `#farms-fs-sheet` plus the buttons `wireFilterSheet()` injects: radius
// 24px top, padding 8px 24px 12px, and **no** box-shadow (the inline
// `0 -8px 32px` is killed by the global `[id$="-sheet"]` rule). Header row is
// [title | Reset | ✕], then a 260px body that bleeds to the sheet edges
// (margin-inline -24) with 1px --divider top/bottom rules, then a 52px
// greenInk Apply and a 44px text-only Cancel.
//
// Reset only clears the sheet's own working selection (back to "all"); Cancel
// restores whatever was last actually applied and closes without calling
// onApply — exactly the HTML's snapshot/restore behaviour, since `_status`/
// `_loc` are always re-seeded from the last-applied widget.status/location
// on open.
class _FarmsFilterSheet extends StatefulWidget {
  final String lang;
  final bool isDark;
  final String status;
  final List<String> location;
  final void Function(String status, List<String> location) onApply;
  const _FarmsFilterSheet({
    required this.lang,
    required this.isDark,
    required this.status,
    required this.location,
    required this.onApply,
  });

  @override
  State<_FarmsFilterSheet> createState() => _FarmsFilterSheetState();
}

class _FarmsFilterSheetState extends State<_FarmsFilterSheet> {
  int _cat = 0; // 0 status, 1 location
  late String _status;
  late List<String> _loc;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _loc = List.of(widget.location);
  }

  bool get _locFiltered => !(_loc.length == 1 && _loc.first == 'all');

  void _selectLoc(String val) {
    setState(() {
      if (val == 'all') {
        _loc = ['all'];
        return;
      }
      final next = List.of(_loc)..remove('all');
      if (next.contains(val)) {
        next.remove(val);
      } else {
        next.add(val);
      }
      _loc = next.isEmpty ? ['all'] : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final lang = widget.lang;
    // In dark, `#flow-root.dark #page-farms > div` (2,1,1) also matches this
    // sheet and outranks the generic sheet rule, so the surface is #111111.
    final bg = isDark ? VanixColors.darkPrimary : VanixColors.bgCard;
    final railBg = isDark ? _darkBgCard : VanixColors.bgCard;
    final paneBg = isDark ? _darkBgCard : VanixColors.bgCard;
    final divider = isDark ? VanixColors.darkDivider : VanixColors.divider;
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      // The sheet's own 24px side padding is applied per-child instead of on
      // the whole column, because the 260px body has margin-inline:-24 and so
      // bleeds to the sheet edges (Flutter's Container margin cannot go
      // negative).
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber wrap: padding 6px 0 2px; bar 36x4, radius 2, --border.
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsetsDirectional.only(top: 6, bottom: 2),
            decoration: BoxDecoration(
              color: isDark ? _darkBorderSoft : VanixColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 10, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Forced to 17px by `#farms-fs-sheet h3 { font-size:17px !important }`.
                Expanded(child: Text(FS.t(lang, 'filterWord'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor))),
                const SizedBox(width: 12),
                // `.fs-reset-btn`: 12/600 greenInk, padding 6px 0.
                TextButton(
                  onPressed: () => setState(() {
                    _status = 'all';
                    _loc = ['all'];
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: VanixColors.greenInk,
                  ),
                  child: Text(FS.t(lang, 'resetFilters'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                // `#farms-fs-close`: 38x38 circle on --bgwarm, 15px --text1 ✕.
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? _darkBgWarm : VanixColors.bgWarm,
                      shape: BoxShape.circle,
                    ),
                    child: Text('✕', style: TextStyle(fontSize: 15, color: textColor)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            // margin-top 14; margin-inline -24 in the HTML, i.e. edge-to-edge
            // inside the sheet — realised here by keeping the sheet's side
            // padding off this child.
            margin: const EdgeInsetsDirectional.only(top: 14),
            height: 260,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: divider), bottom: BorderSide(color: divider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // `.fs-cats-rail`: width 126, --bgcard, padding 8px 0,
                // border-inline-end 1px --divider.
                Container(
                  width: 126,
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: railBg,
                    border: BorderDirectional(end: BorderSide(color: divider)),
                  ),
                  child: Column(
                    children: [
                      _CatTab(label: FS.t(lang, 'statusWord'), active: _cat == 0, filtered: _status != 'all', isDark: isDark, onTap: () => setState(() => _cat = 0)),
                      _CatTab(label: FS.t(lang, 'locationWord'), active: _cat == 1, filtered: _locFiltered, isDark: isDark, onTap: () => setState(() => _cat = 1)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: paneBg,
                    // `.fs-panes-wrap`: padding 12px 20px.
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
                    child: _cat == 0 ? _statusPane(isDark, lang) : _locationPane(isDark, lang),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // `#farms-fs-apply`: 100% x 52, radius 26, greenInk, 16/600 white.
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VanixColors.greenInk,
                  foregroundColor: VanixColors.textOnDark,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  widget.onApply(_status, _loc);
                  Navigator.of(context).pop();
                },
                child: Text(FS.t(lang, 'applyFilters')),
              ),
            ),
          ),
          // `.fs-cancel-btn`: full width, min-height 44, 14/600 --text2.
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 44), foregroundColor: VanixColors.textHint),
              child: Text(FS.t(lang, 'cancelWord'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPane(bool isDark, String lang) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _OptRow(label: FS.t(lang, 'filterAllFarms'), active: _status == 'all', multi: false, isDark: isDark, onTap: () => setState(() => _status = 'all')),
        _OptRow(label: FS.t(lang, 'filterHealthy'), active: _status == 'healthy', multi: false, isDark: isDark, onTap: () => setState(() => _status = 'healthy')),
        _OptRow(label: FS.t(lang, 'filterAttention'), active: _status == 'attention', multi: false, isDark: isDark, onTap: () => setState(() => _status = 'attention')),
        _OptRow(label: FS.t(lang, 'filterSetup'), active: _status == 'setup', multi: false, isDark: isDark, onTap: () => setState(() => _status = 'setup')),
      ],
    );
  }

  Widget _locationPane(bool isDark, String lang) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _OptRow(label: FS.t(lang, 'allWord'), active: _loc.contains('all'), multi: true, isDark: isDark, onTap: () => _selectLoc('all')),
        _OptRow(label: FS.t(lang, 'locCoimbatore'), active: _loc.contains('coimbatore'), multi: true, isDark: isDark, onTap: () => _selectLoc('coimbatore')),
        _OptRow(label: FS.t(lang, 'locErode'), active: _loc.contains('erode'), multi: true, isDark: isDark, onTap: () => _selectLoc('erode')),
        _OptRow(label: FS.t(lang, 'locSalem'), active: _loc.contains('salem'), multi: true, isDark: isDark, onTap: () => _selectLoc('salem')),
      ],
    );
  }
}

// `.s7-cat`: transparent background, padding 14px, 13px label, gap 10 to the
// trailing `.fs-rail-dot` (7px greenInk). The only border that survives is
// the `!important` 5px `border-inline-start` — greenInk when `.on`,
// transparent otherwise; the stylesheet's `border-bottom:1px solid
// var(--divider)` is overridden by the button's own inline `border:none`, so
// the rail rows have NO divider between them. Inactive weight is 400 (the
// element default), active is 700; in dark the active label flips to
// --greendeep while the 5px bar stays --greenink.
class _CatTab extends StatelessWidget {
  final String label;
  final bool active, filtered, isDark;
  final VoidCallback onTap;
  const _CatTab({required this.label, required this.active, required this.filtered, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    final activeInk = isDark ? VanixColors.greenDeep : VanixColors.greenInk;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: active ? VanixColors.greenInk : Colors.transparent, width: 5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? activeInk : textColor)),
            ),
            if (filtered) ...[
              const SizedBox(width: 10),
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: VanixColors.greenInk, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}

// `.s7-chip`: a boxless, full-width row (no background/border of its own),
// min-height 48, padding 0 4, gap 12, 14px label at weight 500 → 600 when
// selected. The control is a 22x22 `::before`:
//  • single-select — circle, 2px border; when on, greenInk border + greenInk
//    fill + `box-shadow: inset 0 0 0 4px var(--bgcard)`, i.e. greenInk ring /
//    --bgcard annulus / 10px greenInk core.
//  • multi-select — radius 6 instead, greenInk fill with a 13px white tick.
class _OptRow extends StatelessWidget {
  final String label;
  final bool active, multi, isDark;
  final VoidCallback onTap;
  const _OptRow({required this.label, required this.active, required this.multi, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderCol = isDark ? _darkBorderSoft : VanixColors.border;
    final insetCol = isDark ? _darkBgCard : VanixColors.bgCard;
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: multi
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: active ? VanixColors.greenInk : borderCol, width: 2),
                        color: active ? VanixColors.greenInk : Colors.transparent,
                      ),
                      child: active ? const Icon(Icons.check, size: 13, color: VanixColors.textOnDark) : null,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? VanixColors.greenInk : borderCol, width: 2),
                        color: active ? VanixColors.greenInk : Colors.transparent,
                      ),
                      // 22px box − 2px border = an 18px padding box; the 4px
                      // inset ring leaves a 10px greenInk core.
                      child: active
                          ? Center(
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: insetCol),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: VanixColors.greenInk),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: textColor)),
            ),
          ],
        ),
      ),
    );
  }
}
