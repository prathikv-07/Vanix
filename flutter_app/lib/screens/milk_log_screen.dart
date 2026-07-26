import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../i18n/farm_strings.dart';
import '../models/milk_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import '../widgets/milk_filter_sheet.dart';
import '../widgets/option_sheet.dart';
import 'events_screen.dart';
import 'farms_screen.dart';
import 'account_screen.dart';
import 'milk_add_entry_screen.dart';
import 'milk_summary_screen.dart';

// ── Values measured off #page-milk in prototype.html via getComputedStyle
// that have no shared token yet. See the report for the tokens worth adding
// to lib/theme/vanix_theme.dart.
const Color _pageBgDark = Color(0xFF121212); // dark --bgwarm
const Color _textHintDark = Color(0xFF9E988E); // dark --text2
const Color _amberBox = Color(0xFFC07E10); // .m-entry litres box, mid band
const Color _pillTextDark = Color(0xFFEDEDED); // .m-pill colour in dark
const Color _lateBgDark = Color(0xFF33290F); // .m-late in dark
const Color _lateBorderDark = Color(0xFF8A6A1F);
const Color _lateTextDark = Color(0xFFE8C87A);
const Color _updBgDark = Color(0xFF0F2A1E); // .m-upd in dark
const Color _actDelBgDark = Color(0xFF2A1512); // #s7-act-del in dark
const Color _grabber = Color(0xFFE0E0E0); // #s7-act grabber pill

const String _en = 'NotoSans'; // class="en" → Latin face, not Devanagari

/// 0 2px 6px rgba(0,0,0,.08) — the .s7-period-btn / #s7-filter / #s7-open-stats
/// shadow. Dark mode deepens it to .40 (`.dark .m-hero button`).
List<BoxShadow> _controlShadow(bool isDark) => [
      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08), blurRadius: 6, offset: const Offset(0, 2)),
    ];

/// Milk Log — mirrors #page-milk in prototype.html: hero (period pill,
/// total + delta, 3 stat tiles, view-complete-summary), date-grouped entry
/// cards, filter bottom sheet, FAB → add entry.
class MilkLogScreen extends StatefulWidget {
  final AppState appState;
  // When true (e.g. tapping the Manager persona's "Milking (Morning)" Home
  // row), the Add Entry sheet opens immediately on top of the list —
  // mirrors window.openAddMilkEntry() in prototype.html.
  final bool openAddOnStart;
  const MilkLogScreen({super.key, required this.appState, this.openAddOnStart = false});

  @override
  State<MilkLogScreen> createState() => _MilkLogScreenState();
}

class _MilkLogScreenState extends State<MilkLogScreen> {
  final int _navIndex = 2;
  final DateTime _today = DateTime(2026, 7, 3);
  late List<MilkEntry> _entries;
  String _period = 'Today';
  MilkFilter _filter = const MilkFilter();
  bool _showSummary = false;

  bool get _isDark => widget.appState.isDark;
  Color get _text1 => _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  Color get _text2 => _isDark ? _textHintDark : VanixColors.textHint;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _green => _isDark ? VanixColors.greenDeep : VanixColors.greenInk;

  @override
  void initState() {
    super.initState();
    _entries = MilkSeed.entries(_today);
    if (widget.openAddOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAddEntry());
    }
  }

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (i == 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FarmsScreen(appState: widget.appState)));
      return;
    }
    if (i == 3) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState)));
      return;
    }
    if (i == 4) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState)));
      return;
    }
  }

  List<MilkEntry> get _visibleTodayEntries {
    var list = _entries.where((e) => _isSameDay(e.date, _today)).toList();
    if (_filter.farm != null) list = list.where((e) => e.farm == _filter.farm).toList();
    if (_filter.session != null) list = list.where((e) => e.session == _filter.session).toList();
    if (_filter.sort == 'highest') list.sort((a, b) => b.litres.compareTo(a.litres));
    if (_filter.sort == 'lowest') list.sort((a, b) => a.litres.compareTo(b.litres));
    return list;
  }

  Map<String, List<MilkEntry>> get _groupedEntries {
    final map = <String, List<MilkEntry>>{};
    for (final e in _entries) {
      final label = _dateLabel(e.date);
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  String _dateLabel(DateTime d) {
    if (_isSameDay(d, _today)) return 'Today — ${d.day} Jul';
    if (_isSameDay(d, _today.subtract(const Duration(days: 1)))) return 'Yesterday — ${d.day} Jul';
    return '${d.day} Jul';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  double get _totalToday => _visibleTodayEntries.fold(0, (sum, e) => sum + e.litres);
  MilkEntry? get _maxEntry => _visibleTodayEntries.isEmpty ? null : _visibleTodayEntries.reduce((a, b) => a.litres >= b.litres ? a : b);
  MilkEntry? get _minEntry => _visibleTodayEntries.isEmpty ? null : _visibleTodayEntries.reduce((a, b) => a.litres <= b.litres ? a : b);

  Future<void> _openAddEntry({MilkEntry? editing}) async {
    final result = await Navigator.of(context).push<MilkEntryResult>(
      MaterialPageRoute(builder: (_) => MilkAddEntryScreen(appState: widget.appState, allEntries: _entries, today: _today, editing: editing)),
    );
    if (result == null) return;
    final farmer = !widget.appState.isOwner;
    setState(() {
      if (result.delete && editing != null) {
        if (farmer) {
          _requestDelete(editing);
        } else {
          _entries.removeWhere((e) => e.id == editing.id);
        }
      } else if (result.entry != null) {
        final idx = _entries.indexWhere((e) => e.id == result.entry!.id);
        if (idx >= 0) {
          if (farmer) {
            // Farmer edits are a request, not a direct change.
            _requestEdit(_entries[idx], result.entry!.litres);
          } else {
            _entries[idx] = result.entry!;
          }
        } else {
          // A brand-new entry is logging (allowed for farmers too).
          _entries.add(result.entry!);
        }
      }
    });
  }

  // ── Farmer edit/delete → pending owner-approval request (mirrors the
  // .m-sub pending sub-card in prototype.html). Owner approves/rejects. ──
  void _requestEdit(MilkEntry e, double proposed) {
    e.pendingApproval = true;
    e.pendingKind = 'edit';
    e.pendingLitres = proposed;
    e.pendingBy = e.manager;
    e.pendingLabel = '${FS.t(widget.appState.languageCode, 'mpEditTo')} $proposed L';
  }

  void _requestDelete(MilkEntry e) {
    e.pendingApproval = true;
    e.pendingKind = 'delete';
    e.pendingBy = e.manager;
    e.pendingLabel = FS.t(widget.appState.languageCode, 'mpDeleteEntry');
  }

  void _approvePending(MilkEntry e) {
    setState(() {
      if (e.pendingKind == 'delete') {
        _entries.removeWhere((x) => x.id == e.id);
        return;
      }
      if (e.pendingKind == 'add') {
        e.litres = double.parse((e.litres + (e.pendingLitres ?? 0)).toStringAsFixed(1));
      } else if (e.pendingKind == 'edit') {
        e.litres = e.pendingLitres ?? e.litres;
      }
      e.updated = true;
      e.updatedAt = TimeOfDay.now();
      _clearPending(e);
    });
  }

  void _rejectPending(MilkEntry e) => setState(() => _clearPending(e));

  void _clearPending(MilkEntry e) {
    e.pendingApproval = false;
    e.pendingKind = null;
    e.pendingLitres = null;
    e.pendingLabel = null;
    e.pendingBy = null;
  }

  // ── Entry actions sheet (#s7-act): grabber, title, approval note, then an
  // Edit row (bgWarm / border / r14) and a Delete row (dangerBg / danger). ──
  void _openEntryActions(MilkEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = _isDark;
        return Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, -8))],
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // grabber — 36x4 @ #E0E0E0, r2, wrapper padding 6/0/2
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _grabber, borderRadius: BorderRadius.circular(2))),
                ),
              ),
              const SizedBox(height: 12),
              Text('${entry.cow} — ${entry.session.label} · ${entry.litres} L',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1, fontFamily: _en)),
              const SizedBox(height: 2),
              const Text('Changes are sent to the Farm Owner for approval', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              const SizedBox(height: 14),
              _ActRow(
                icon: Icons.edit_outlined,
                label: 'Edit entry',
                bg: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                borderColor: _border,
                fg: _text1,
                onTap: () {
                  Navigator.pop(context);
                  _openAddEntry(editing: entry);
                },
              ),
              const SizedBox(height: 8),
              _ActRow(
                icon: Icons.delete_outline,
                label: 'Delete entry',
                bg: isDark ? _actDelBgDark : VanixColors.dangerBg,
                borderColor: VanixColors.danger,
                fg: VanixColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (!widget.appState.isOwner) {
                      _requestDelete(entry);
                    } else {
                      _entries.removeWhere((e) => e.id == entry.id);
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    final t = VanixStrings.of(widget.appState.languageCode);
    final total = _totalToday;
    final maxE = _maxEntry;
    final minE = _minEntry;
    final groups = _groupedEntries.entries.toList();

    return Scaffold(
      backgroundColor: isDark ? _pageBgDark : VanixColors.bgWarm,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _buildHero(isDark, total, maxE, minE),
                  if (_showSummary)
                    MilkSummaryContent(appState: widget.appState, padding: const EdgeInsets.fromLTRB(20, 16, 20, 0))
                  else
                    Padding(
                      // .m-list wrapper — padding:12px 16px 0
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var gi = 0; gi < groups.length; gi++) ...[
                            // Section label margin is 12px 0 10px on the first
                            // group and 18px 0 10px after; CSS collapses that
                            // 18 against the preceding card's 10px bottom
                            // margin, so only 8 is added here.
                            Padding(
                              padding: EdgeInsets.only(top: gi == 0 ? 12 : 8, bottom: 10),
                              child: Text(
                                groups[gi].key.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.96, color: _text2, fontFamily: _en),
                              ),
                            ),
                            for (final entry in groups[gi].value)
                              _EntryCard(
                                entry: entry,
                                isDark: isDark,
                                isFarmer: !widget.appState.isOwner,
                                lang: widget.appState.languageCode,
                                onTap: () => _openEntryActions(entry),
                                onApprove: () => _approvePending(entry),
                                onReject: () => _rejectPending(entry),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // FAB (#s7-fab) — right:18 bottom:104, 56px, --dark1 fill,
          // 0 10px 24px rgba(0,0,0,.28); lifted by the bottom safe-area
          // so it never overlaps the floating nav bar.
          Positioned(
            right: 18,
            bottom: 104 + MediaQuery.of(context).padding.bottom,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: FloatingActionButton(
                backgroundColor: VanixColors.darkPrimary,
                elevation: 0,
                highlightElevation: 0,
                onPressed: () => _openAddEntry(),
                child: const Icon(Icons.add, size: 24, color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: VanixBottomNav(isDark: isDark, selectedIndex: _navIndex, onTap: _onNavTap, items: buildVanixNavItems(t, widget.appState)),
          ),
        ],
      ),
    );
  }

  // ── .m-hero — bg --bgwarm (#1C1C1C dark), r0/0/14/14, padding 18px 16px
  // 20px, shadow 0 12px 28px @18% (@55% dark). `#s7-stats.stats-open .m-hero`
  // drops the shadow, so it goes while the summary is expanded. ──
  Widget _buildHero(bool isDark, double total, MilkEntry? maxE, MilkEntry? minE) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: _showSummary
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milk Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _text1)),
              Row(
                children: [
                  _PeriodPill(
                    label: _period,
                    isDark: isDark,
                    onTap: () => showOptionSheet(
                      context: context,
                      title: 'Show data for',
                      options: const ['Today', 'This Week', 'This Month', 'This Year', 'Custom…'],
                      current: _period,
                      onSelect: (v) => setState(() => _period = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Top-right control is always the FILTER funnel (opens the milk filter sheet) —
                  // in both the normal log view and the expanded summary view.
                  _IconCircle(icon: Icons.filter_alt_outlined, isDark: isDark, onTap: () => showMilkFilterSheet(context, current: _filter, onApply: (f) => setState(() => _filter = f))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // letter-spacing .08em at 11px = 0.88px
          const Text('TOTAL MILK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.88, color: VanixColors.textHint, fontFamily: _en)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${total.toStringAsFixed(1)} L',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.0, color: _text1, fontFamily: _en)),
              const SizedBox(width: 10),
              // .m-delta is --greenink on light, but `.dark .m-hero span` wins
              // over `.dark .m-delta`, so it renders #F5F5F5 in dark.
              Flexible(
                child: Text('▲ 8% vs yesterday',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? VanixColors.textOnDarkDim : VanixColors.greenInk, fontFamily: _en)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatBox(value: '${_visibleTodayEntries.length}', label: 'Cows milked', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatBox(value: maxE != null ? '${maxE.litres} L' : '—', label: maxE != null ? 'Max — ${maxE.cow}' : 'Max', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatBox(value: minE != null ? '${minE.litres} L' : '—', label: minE != null ? 'Min — ${minE.cow}' : 'Min', isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          // #s7-open-stats / #s7-stats-collapse — min-height 38, r19, 1px
          // --border, 0 2px 6px @8%, label 13/600 --greenink (no icon).
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), boxShadow: _controlShadow(isDark)),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showSummary = !_showSummary),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.transparent,
                  foregroundColor: _green,
                  side: BorderSide(color: _border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                ),
                child: Text(_showSummary ? 'Hide complete summary' : 'View complete summary',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// .s7-period-btn — h32, r16, padding 0 12, 1px --border, transparent fill,
/// 0 2px 6px @8%, label 12/600 --text1, gap 6, 11px chevron.
class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _PeriodPill({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    final border = isDark ? VanixColors.darkBorder : VanixColors.border;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _controlShadow(isDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 11, color: textColor),
          ],
        ),
      ),
    );
  }
}

/// #s7-filter — 32x32 circle, 1px --border, transparent, 0 2px 6px @8%,
/// 15px funnel glyph stroked #111111 (#F5F5F5 in dark).
class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
          boxShadow: _controlShadow(isDark),
        ),
        child: Icon(icon, size: 15, color: isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary),
      ),
    );
  }
}

/// .m-tile — flex:1, padding 10, r12, 1px --border, --bgcard fill, no shadow.
/// Value 18/700 (Latin face); label 11/400 --text2 with a 2px top gap.
class _StatBox extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatBox({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSubSurface : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary, fontFamily: _en)),
          const SizedBox(height: 2),
          // `.dark .m-tile p + p` pins the label to #8C8780 in dark too.
          Text(label, style: const TextStyle(fontSize: 11, color: VanixColors.textHint), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// #s7-act-edit / #s7-act-del — min-height 50, gap 12, r14, 1px border,
/// padding 0 16, label 15/500, 17px leading glyph.
class _ActRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, borderColor, fg;
  final VoidCallback onTap;
  const _ActRow({required this.icon, required this.label, required this.bg, required this.borderColor, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: bg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// .m-card.m-entry — --bgcard, 1px --border, r16, padding 14px 16px,
/// margin-bottom 10, NO shadow. Right-hand litres box is 64 wide, min-height
/// 64, r14, and stretches to the row height.
class _EntryCard extends StatelessWidget {
  final MilkEntry entry;
  final bool isDark;
  final bool isFarmer;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _EntryCard({required this.entry, required this.isDark, required this.isFarmer, required this.lang, required this.onTap, required this.onApprove, required this.onReject});

  // Litres-box bands measured off the seeded entries: 12.5/8.2 → #1E7A52,
  // 5.0/4.1 → #C07E10, 2.0 → #D44C3A.
  Color get _boxColor {
    if (entry.litres >= 8) return VanixColors.greenInk;
    if (entry.litres >= 4) return _amberBox;
    return VanixColors.danger;
  }

  Color get _text1 => isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  Color get _border => isDark ? VanixColors.darkBorder : VanixColors.border;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.cow} — ${entry.breed}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text1)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              // .m-pill — --bgwarm, 1px --border, r10,
                              // padding 2px 10px, 11/600 --text1
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(entry.session.label,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? _pillTextDark : VanixColors.textPrimary, fontFamily: _en)),
                              ),
                              const SizedBox(width: 8),
                              if (entry.onTime)
                                // .m-ok — bare 12px ✓ glyph, no chip
                                Text('✓', style: TextStyle(fontSize: 12, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk, fontFamily: _en))
                              else
                                // .m-late — --warnbg, 1px --warning, r10,
                                // padding 2px 8px, 10/600 #8A5A00
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? _lateBgDark : VanixColors.warningBg,
                                    border: Border.all(color: isDark ? _lateBorderDark : VanixColors.warning),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('⏱',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? _lateTextDark : VanixColors.warningInk, fontFamily: _en)),
                                ),
                              if (entry.updated) ...[
                                const SizedBox(width: 8),
                                // .m-upd — --activebg, 1px --greendeep, r10,
                                // padding 2px 8px, 10/600 --greenink, gap 4
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? _updBgDark : VanixColors.activeBg,
                                    border: Border.all(color: VanixColors.greenDeep),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.refresh, size: 11, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk),
                                    const SizedBox(width: 4),
                                    Text(FS.t(lang, 'mpUpdated'),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk, fontFamily: _en)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${entry.farm} — ${entry.manager}', style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 64,
                      constraints: const BoxConstraints(minHeight: 64),
                      decoration: BoxDecoration(color: _boxColor, borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${entry.litres}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.0, color: Colors.white, fontFamily: _en)),
                            const SizedBox(height: 2),
                            Text('Ltrs',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85), fontFamily: _en)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entry.pendingApproval) _pendingSub(context),
          ],
        ),
      ),
    );
  }

  // .m-sub — a 1px DASHED --border top rule with margin-top 2 / padding-top
  // 10. No fill, no radius: it is a hairline divider inside the card, not a
  // nested panel. Owner sees ✕ / Approve; farmer sees the status only
  // (`.persona-farmer .m-sub-actions { display:none }`).
  Widget _pendingSub(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      child: CustomPaint(
        painter: _DashedTopRule(_border),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.pendingLabel ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text1)),
                    const SizedBox(height: 2),
                    Text('${FS.t(lang, 'mpBy')} ${entry.pendingBy ?? ''} · ${FS.t(lang, 'mpPendingApproval')}',
                        style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
                  ],
                ),
              ),
              if (!isFarmer) ...[
                const SizedBox(width: 10),
                // .m-reject — h34, padding 0 14, r17, 1px --border,
                // transparent, 12/500 --text1
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: _border),
                    foregroundColor: _text1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: const Text('✕', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 6),
                // .m-approve — h34, padding 0 14, r17, no border,
                // --greenink fill, 12/600 white
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                    backgroundColor: VanixColors.greenInk,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                  ),
                  child: Text(FS.t(lang, 'mpApprove'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `border-top: 1px dashed var(--border)` — Flutter has no dashed BorderSide,
/// so the rule is stroked by hand at the top edge.
class _DashedTopRule extends CustomPainter {
  final Color color;
  const _DashedTopRule(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 2.0, gap = 2.0;
    for (double x = 0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, 0.5), Offset(end, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedTopRule old) => old.color != color;
}
