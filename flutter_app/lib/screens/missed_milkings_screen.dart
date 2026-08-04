import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/milk_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import 'milk_add_entry_screen.dart';

/// One expected-but-unlogged milking: a cow × session pair with no
/// [MilkEntry] behind it.
class MissedSlot {
  final Cow cow;
  final MilkSession session;
  const MissedSlot(this.cow, this.session);
}

/// Missed Milkings — the destination for the Home dashboard's "Milking
/// Sessions Missed → View All" row.
///
/// WHY THIS IS ITS OWN SCREEN, NOT A MILK LOG FILTER
///
/// A missed session is the *absence* of a [MilkEntry]. The Milk Log
/// renders a `List<MilkEntry>` — records that exist — so no filter over
/// that list can ever surface a record that was never created. Making a
/// filter work would mean injecting synthetic placeholder entries into
/// the same `_entries` list that also feeds the Milk Summary totals, the
/// approvals queue, and edit/delete. Ghost rows there would skew litre
/// totals and expose edit affordances for milkings that never happened —
/// a data-integrity problem, not a presentation one.
///
/// The user's task is different too. A Milk Log row's verb is "edit or
/// approve this record"; a missed session's only useful verb is "log it
/// now". Different object, different action, so it earns its own screen.
///
/// "Logged late" (`MilkEntry.onTime == false`) *is* a genuine filterable
/// property of existing entries, and it appears here as a separate
/// secondary section — deliberately not merged with the missed list, so
/// "never recorded" and "recorded, but late" are never conflated.
class MissedMilkingsScreen extends StatefulWidget {
  final AppState appState;

  /// Fixed demo "today" — matches [MilkLogScreen]'s reference date so both
  /// screens agree on which entries count as today's.
  final DateTime today;

  const MissedMilkingsScreen({super.key, required this.appState, required this.today});

  /// Hour by which each session is expected to be logged. Mirrors
  /// `SESS_HOURS = { Morning: 7, Evening: 18 }` in the prototype JS.
  static const Map<MilkSession, int> dueHour = {
    MilkSession.morning: 7,
    MilkSession.evening: 18,
  };

  /// A session counts as *due* once it has demonstrably run — either some
  /// cow already has an entry for it, or its due hour has passed. Before
  /// that it is merely pending, and calling it "missed" would be wrong.
  static bool sessionIsDue(List<MilkEntry> todayEntries, MilkSession session) {
    if (todayEntries.any((e) => e.session == session)) return true;
    return TimeOfDay.now().hour >= dueHour[session]!;
  }

  /// The expected-but-unlogged slots for [today], in session order.
  ///
  /// Scoped to today only: "Milking Sessions Missed" sits on a Home
  /// dashboard that reports on the current day, and back-filling every
  /// historical gap would bury today's actionable ones.
  static List<MissedSlot> compute(List<MilkEntry> entries, DateTime today) {
    final todays = entries.where((e) =>
        e.date.year == today.year && e.date.month == today.month && e.date.day == today.day).toList();
    final out = <MissedSlot>[];
    for (final session in MilkSession.values) {
      if (!sessionIsDue(todays, session)) continue;
      final logged = todays.where((e) => e.session == session).map((e) => e.cow).toSet();
      for (final cow in MilkSeed.cows) {
        if (!logged.contains(cow.name)) out.add(MissedSlot(cow, session));
      }
    }
    return out;
  }

  /// Count for the dashboard badge, so the number and this screen can
  /// never disagree.
  static int countFor(DateTime today) => compute(MilkSeed.entries(today), today).length;

  @override
  State<MissedMilkingsScreen> createState() => _MissedMilkingsScreenState();
}

class _MissedMilkingsScreenState extends State<MissedMilkingsScreen> {
  late List<MilkEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = MilkSeed.entries(widget.today);
  }

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;
  String _t(String k) => FS.t(_lang, k);

  Color get _warmBg => _isDark ? VanixColors.darkBgWarm : VanixColors.bgWarm;
  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _text1 => _isDark ? Colors.white : VanixColors.textPrimary;
  Color get _text2 => _isDark ? VanixColors.darkTextHint : VanixColors.textHint;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;

  List<MilkEntry> get _todayEntries => _entries
      .where((e) =>
          e.date.year == widget.today.year && e.date.month == widget.today.month && e.date.day == widget.today.day)
      .toList();

  String _sessionLabel(MilkSession s) => _t(s == MilkSession.morning ? 'sessMorning' : 'sessEvening');
  String _time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Opens Add Entry with the cow and session already chosen, so the
  /// farmer never re-picks what the row already told them.
  Future<void> _logNow(MissedSlot slot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MilkAddEntryScreen(
          appState: widget.appState,
          allEntries: _entries,
          today: widget.today,
          prefillCow: slot.cow,
          prefillSession: slot.session,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        final missed = MissedMilkingsScreen.compute(_entries, widget.today);
        final late = _todayEntries.where((e) => !e.onTime).toList();
        final expected = MilkSeed.cows.length * MilkSession.values.length;

        final bySession = <MilkSession, List<MissedSlot>>{};
        for (final m in missed) {
          bySession.putIfAbsent(m.session, () => []).add(m);
        }

        return Theme(
          data: theme,
          child: Scaffold(
            backgroundColor: _warmBg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: missed.isEmpty && late.isEmpty
                        ? _emptyState()
                        : ListView(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 28),
                            children: [
                              _summaryCard(missed.length, expected),
                              const SizedBox(height: 18),
                              for (final session in MilkSession.values)
                                if ((bySession[session] ?? []).isNotEmpty) ...[
                                  _sectionLabel(
                                      '${_sessionLabel(session)} · ${_t('missingWord')} (${bySession[session]!.length})'),
                                  for (final slot in bySession[session]!) _missedRow(slot),
                                  const SizedBox(height: 14),
                                ],
                              if (late.isNotEmpty) ...[
                                _sectionLabel('${_t('missedLoggedLate')} (${late.length})'),
                                for (final e in late) _lateRow(e),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _warmBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(backgroundColor: _cardBg, shape: const CircleBorder()),
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.chevron_left, size: 18, color: _text1),
            ),
          ),
          const SizedBox(width: 10),
          // No count badge here — the summary card below already states the
          // number, and repeating it in the title read as clutter.
          Expanded(child: Text(_t('missedTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _text1))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.55, color: VanixColors.textHint)),
      );

  /// Frames the gap against the day's total so a bare "7" reads as
  /// "7 of 14", not an unbounded pile.
  Widget _summaryCard(int missedCount, int expected) {
    final logged = expected - missedCount;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$missedCount',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: _text1, height: 1.1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('${_t('missedOf')} $expected ${_t('missedSessionsNotLogged')}',
                    style: TextStyle(fontSize: 13, color: _text2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Explicit widths rather than flex-weighted Expandeds — the latter
          // collapsed to nothing inside the ClipRRect at this height.
          LayoutBuilder(
            builder: (context, c) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 6,
                width: c.maxWidth,
                color: VanixColors.warning,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    height: 6,
                    width: expected == 0 ? 0 : c.maxWidth * logged / expected,
                    color: VanixColors.greenDeep,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('$logged ${_t('missedLoggedOnDay')} · ${_dayLabel()}', style: TextStyle(fontSize: 11, color: _text2)),
        ],
      ),
    );
  }

  String _dayLabel() => '${_t('dashToday')} — ${widget.today.day} Jul';

  Widget _missedRow(MissedSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.cow.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                const SizedBox(height: 2),
                // The section heading already says which session this is, so
                // an "Expected by HH:MM" line per row was redundant.
                Text('${slot.cow.breed} · ${_t('beltWord')} ${slot.cow.belt}',
                    style: TextStyle(fontSize: 12, color: _text2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: VanixColors.greenInk,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
            ),
            onPressed: () => _logNow(slot),
            child: Text(_t('missedLogNow'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// Logged-but-late entries: real records, so no "Log now" — this is
  /// information about compliance, not an outstanding task.
  Widget _lateRow(MilkEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.cow, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                const SizedBox(height: 2),
                Text('${_sessionLabel(e.session)} · ${_time(e.time)} · ${e.litres} L',
                    style: TextStyle(fontSize: 12, color: _text2)),
                if (e.lateNote != null) ...[
                  const SizedBox(height: 4),
                  Text(e.lateNote!, style: const TextStyle(fontSize: 11, color: VanixColors.warningInk)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_t('missedLatePill').toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: VanixColors.warning)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 44, color: VanixColors.greenInk),
            const SizedBox(height: 12),
            Text(_t('missedNone'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1)),
            const SizedBox(height: 6),
            Text(_t('missedNoneSub'),
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _text2, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
