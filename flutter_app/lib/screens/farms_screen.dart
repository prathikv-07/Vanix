import 'package:flutter/material.dart';
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

/// Farms list — screen 04. Mirrors #page-farms in prototype.html: hero
/// (title, 3 stat tiles — no subtitle/ticker, both were removed from the
/// HTML), search + two-pane filter sheet (Status single-select / Location
/// multi-select, boxless radio/checkbox rows, Reset + Cancel + Apply,
/// matching the shared `wireFilterSheet()` convention used app-wide), and
/// the farm cards straight into the list (no "Your Farms" heading — that
/// text is dead/unused in the current HTML) with a severity corner tag,
/// cattle count, and 5 stat chips (Heat / Insemination / Pregnant / Fever /
/// Milk Today). Setup farms render as a dashed-style row with a
/// "Setup Farm" pill.
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
      // the dashed "Setup Farm" row.
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
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;

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
                    padding: const EdgeInsetsDirectional.only(bottom: 120),
                    children: [
                      _buildHero(isDark, lang, textColor, totalFarms, totalCattle, totalAlerts),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            Expanded(child: _buildSearch(isDark, lang)),
                            const SizedBox(width: 10),
                            _FilterButton(isDark: isDark, active: _hasActiveFilter, onTap: _openFilterSheet),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 0),
                        child: list.isEmpty
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(top: 24),
                                child: Center(
                                  child: Text(FS.t(lang, 'noFarmsMatch'),
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

  // Mirrors the `.m-hero` block in #page-farms: title, then straight into
  // the 3 stat tiles — no subtitle, no activity ticker (both removed from
  // the current HTML).
  Widget _buildHero(bool isDark, String lang, Color textColor, int totalFarms, int totalCattle, int totalAlerts) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10), blurRadius: 24, offset: const Offset(0, 10))],
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

  Widget _buildSearch(bool isDark, String lang) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : VanixColors.textPrimary),
      decoration: InputDecoration(
        hintText: FS.t(lang, 'searchFarms'),
        prefixIcon: const Icon(Icons.search, size: 18, color: VanixColors.textHint),
      ),
    );
  }
}

// ── Hero pieces ──────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatTile({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}

// ── Filter button ───────────────────────────────────────────

// Mirrors `.fs-trigger-dot` — a small greenInk dot overlaid on the filter
// button once any filter (status or location) is active.
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.isDark, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
            ),
            child: Center(child: FunnelIcon(size: 15, color: isDark ? Colors.white : VanixColors.textPrimary)),
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
                  border: Border.all(color: isDark ? const Color(0xFF121212) : VanixColors.bgWarm, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Farm cards ───────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final bool isOwner;
  final VoidCallback onTap;
  const _FarmCard({required this.farm, required this.lang, required this.isDark, required this.isOwner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final attention = farm.status == FarmStatus.attention;
    final tagBg = attention ? VanixColors.danger : VanixColors.greenInk;
    final tagLabel = attention ? FS.t(lang, 'sevCritical') : FS.t(lang, 'healthyWord');

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Stack(
            children: [
              // Corner severity tag.
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
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.white)),
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
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 28, end: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset('assets/images/GroupCow_Icon.svg', width: 15, height: 15, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                              const SizedBox(width: 4),
                              Text('${farm.cattle}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
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

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: VanixColors.textHint),
        const SizedBox(width: 4),
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

// Mirrors `farmChip()` in prototype.html — the `bg`/`color` params that
// function accepts are dead code there (never used in the returned
// markup); every chip is actually plain `var(--bgcard)` with a
// `var(--border)` outline, `text1` value, `text2` label. No per-chip
// tinting — this matches the real current render exactly.
class _Chip extends StatelessWidget {
  final bool isDark;
  final String value, label;
  const _Chip({required this.isDark, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: VanixColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _SetupFarmRow extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final VoidCallback onTap;
  const _SetupFarmRow({required this.farm, required this.lang, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
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
              Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? VanixColors.darkPrimary : VanixColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                ),
                child: Text(FS.t(lang, 'setupFarm'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Two-pane filter sheet ────────────────────────────────────

// Mirrors the shared `wireFilterSheet()` two-pane bottom sheet used
// app-wide (Milk Log / Events / Farm Detail / Farms): a white left rail
// (Status single-select / Location multi-select) with a 5px greenInk
// active-border + divider between categories, boxless option rows with a
// left-side radio (single-select) or checkbox (multi-select) — both
// greenInk — "Filter" flush left + "Reset" flush right on one header row,
// and a greenInk Apply + a plain-text Cancel below it. Reset only clears
// the sheet's own working selection (back to "all"); Cancel restores
// whatever was last actually applied and closes without calling onApply
// — exactly like the HTML's snapshot/restore behavior, since `_status`/
// `_loc` here are always re-seeded from the last-applied widget.status/
// location on open.
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
    final bg = isDark ? VanixColors.darkSecond : Colors.white;
    final railBg = isDark ? const Color(0xFF1E1E1E) : VanixColors.bgCard;
    final paneBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsetsDirectional.only(top: 8, bottom: 2),
            decoration: BoxDecoration(color: VanixColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(FS.t(lang, 'filterWord'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor))),
                TextButton(
                  onPressed: () => setState(() {
                    _status = 'all';
                    _loc = ['all'];
                  }),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), foregroundColor: VanixColors.greenInk),
                  child: Text(FS.t(lang, 'resetFilters'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(top: 14),
            height: 260,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? VanixColors.darkDivider : VanixColors.divider), bottom: BorderSide(color: isDark ? VanixColors.darkDivider : VanixColors.divider))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 126,
                  color: railBg,
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
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
                    child: _cat == 0 ? _statusPane(isDark, lang) : _locationPane(isDark, lang),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_status, _loc);
                Navigator.of(context).pop();
              },
              child: Text(FS.t(lang, 'applyFilters')),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 44), foregroundColor: VanixColors.textHint),
            child: Text(FS.t(lang, 'cancelWord'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _statusPane(bool isDark, String lang) {
    return ListView(
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
      children: [
        _OptRow(label: FS.t(lang, 'allWord'), active: _loc.contains('all'), multi: true, isDark: isDark, onTap: () => _selectLoc('all')),
        _OptRow(label: FS.t(lang, 'locCoimbatore'), active: _loc.contains('coimbatore'), multi: true, isDark: isDark, onTap: () => _selectLoc('coimbatore')),
        _OptRow(label: FS.t(lang, 'locErode'), active: _loc.contains('erode'), multi: true, isDark: isDark, onTap: () => _selectLoc('erode')),
        _OptRow(label: FS.t(lang, 'locSalem'), active: _loc.contains('salem'), multi: true, isDark: isDark, onTap: () => _selectLoc('salem')),
      ],
    );
  }
}

// Mirrors `.s7-cat` — transparent background always, a 5px start border
// that's greenInk only when active (`.s7-cat.on`), a bottom divider
// between rail rows, and a small trailing greenInk dot (`.fs-rail-dot`)
// once that category's pane holds a non-"all" selection.
class _CatTab extends StatelessWidget {
  final String label;
  final bool active, filtered, isDark;
  final VoidCallback onTap;
  const _CatTab({required this.label, required this.active, required this.filtered, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isDark ? VanixColors.darkDivider : VanixColors.divider),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 20,
              margin: const EdgeInsetsDirectional.only(end: 9),
              color: active ? VanixColors.greenInk : Colors.transparent,
            ),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? VanixColors.greenInk : textColor)),
            ),
            if (filtered) Container(width: 7, height: 7, decoration: const BoxDecoration(color: VanixColors.greenInk, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

// Mirrors `.s7-chip` — a boxless, full-width row (no background/border)
// with a left-side 22px control: a filled greenInk circle with a white
// inset ring for single-select ("radio"), or a rounded greenInk square
// with a white checkmark for multi-select ("checkbox"). Label goes bold
// when selected.
class _OptRow extends StatelessWidget {
  final String label;
  final bool active, multi, isDark;
  final VoidCallback onTap;
  const _OptRow({required this.label, required this.active, required this.multi, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderCol = isDark ? VanixColors.darkBorder : VanixColors.border;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: multi ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: multi ? BorderRadius.circular(6) : null,
                border: Border.all(color: active ? VanixColors.greenInk : borderCol, width: 2),
                color: active ? VanixColors.greenInk : Colors.transparent,
              ),
              child: active
                  ? (multi
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? VanixColors.darkSecond : VanixColors.bgCard),
                        ))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: textColor))),
          ],
        ),
      ),
    );
  }
}
