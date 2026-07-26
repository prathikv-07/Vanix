import 'package:flutter/material.dart';
import '../models/milk_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

class MilkEntryResult {
  final bool delete;
  final MilkEntry? entry;
  const MilkEntryResult.save(MilkEntry this.entry) : delete = false;
  const MilkEntryResult.delete() : entry = null, delete = true;
}

/// Add / edit a milk-log entry — pixel replica of #s8-page in prototype.html.
///
/// Every value below was measured with getComputedStyle on the live prototype
/// (viewport 375x812), never read off the markup: the inline `background`
/// shorthand on `.sel` wipes the chevron data-URI to `background-image:none`,
/// so the FARM/COW selects render with NO chevron at all — only the
/// `padding-right:32px !important` from `.sel` survives.
///
/// Session-pill state comes from the prototype's own paint(): the OFF state
/// clears the inline `color`/`border-color`, so the UA button defaults win and
/// both compute to #000000 — it is NOT --text1/--border.
class MilkAddEntryScreen extends StatefulWidget {
  final AppState appState;
  final List<MilkEntry> allEntries;
  final MilkEntry? editing;
  final DateTime today;

  const MilkAddEntryScreen({super.key, required this.appState, required this.allEntries, required this.today, this.editing});

  @override
  State<MilkAddEntryScreen> createState() => _MilkAddEntryScreenState();
}

class _MilkAddEntryScreenState extends State<MilkAddEntryScreen> {
  // ── measured prototype constants ──
  /// SESS_HOURS = { Morning: 7, Evening: 18 } in the prototype JS.
  static const int _morningHour = 7;
  static const int _eveningHour = 18;
  /// `var current = h < 16 ? 'Morning' : 'Evening'` — the default-session cut
  /// is 16:00, while the Evening lock is a separate `h < 17` test.
  static const int _currentSessionCutoff = 16;
  static const int _eveningLockHour = 17;

  /// border-bottom:1.5px solid #9A948A on the LITRES row (a literal, not a token).
  static const Color _litresRule = Color(0xFF9A948A);
  /// Chrome's ::placeholder colour on #s8-litres.
  static const Color _placeholder = Color(0xFF757575);

  late String _farm;
  late Cow _cow;
  late DateTime _date;
  late MilkSession _session;
  final _litresCtrl = TextEditingController();

  bool get _isDark => widget.appState.isDark;
  Color get _warmBg => _isDark ? VanixColors.darkBgWarm : VanixColors.bgWarm;
  Color get _cardBg => _isDark ? VanixColors.darkBgCard : VanixColors.bgCard;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _text1 => _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  Color get _text2 => _isDark ? VanixColors.darkTextHint : VanixColors.textHint;
  Color get _warnBg => _isDark ? VanixColors.darkWarningBg : VanixColors.warningBg;

  int get _hour => TimeOfDay.now().hour;
  MilkSession get _currentSession => _hour < _currentSessionCutoff ? MilkSession.morning : MilkSession.evening;
  bool get _isToday => _date.year == widget.today.year && _date.month == widget.today.month && _date.day == widget.today.day;
  bool get _eveningLocked => _isToday && _hour < _eveningLockHour;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _farm = e?.farm ?? MilkSeed.farms.first;
    _cow = e != null ? MilkSeed.cows.firstWhere((c) => c.name == e.cow, orElse: () => MilkSeed.cows.first) : MilkSeed.cows.first;
    _date = e?.date ?? widget.today;
    _session = e?.session ?? _currentSession;
    _litresCtrl.text = e != null ? e.litres.toString() : '';
  }

  @override
  void dispose() {
    _litresCtrl.dispose();
    super.dispose();
  }

  String _cowLabel(Cow c) => '${c.name} — ${c.breed} — ${c.belt}';
  String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// `dateInput.max = todayStr` — future dates are hard-blocked, and on change
  /// `if (isToday() && h < 17) selected = 'Morning'`.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: widget.today);
    if (picked == null) return;
    setState(() {
      _date = picked;
      if (_isToday && _hour < _eveningLockHour) _session = MilkSession.morning;
    });
  }

  /// Mirrors the prototype's session click handler exactly.
  void _selectSession(MilkSession target) {
    if (target == _session) return;
    if (!_isToday) {
      setState(() => _session = target);
      return;
    }
    if (target == _currentSession) {
      setState(() => _session = target);
      return;
    }
    final diff = _hour - (target == MilkSession.morning ? _morningHour : _eveningHour);
    final when = diff > 0 ? '${diff.abs()} hours after' : '${diff.abs()} hours before';
    _showPastSessionWarning(target, when);
  }

  void _showPastSessionWarning(MilkSession target, String when) {
    _showConfirmCard(
      title: 'Logging a past session?',
      body: 'This is $when the usual ${target.label} milking time. Are you sure?',
      confirmLabel: 'Proceed',
      onConfirm: () => setState(() => _session = target),
    );
  }

  /// `if (dateInput.value === todayStr)` — the duplicate guard only ever runs
  /// against today's cards, never past dates.
  MilkEntry? _existingDuplicate() {
    if (!_isToday) return null;
    for (final e in widget.allEntries) {
      if (e.id != widget.editing?.id && e.cow == _cow.name && e.session == _session && _sameDay(e.date, _date)) return e;
    }
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _onSave() {
    // litres = Math.round((parseFloat(value) || 0) * 10) / 10
    final litres = ((double.tryParse(_litresCtrl.text) ?? 0) * 10).round() / 10;

    if (widget.editing != null) {
      Navigator.pop(context, MilkEntryResult.save(_buildEntry(litres)));
      return;
    }

    final dup = _existingDuplicate();
    if (dup != null) {
      final tail = widget.appState.isOwner
          ? 'Your entry will be added to it. Continue?'
          : 'Your entry will be added to it after the Farm Owner approves. Continue?';
      _showConfirmCard(
        title: 'Entry already exists',
        body: '${_cow.name} already has a ${_session.label} entry today (${dup.litres} L). $tail',
        confirmLabel: 'Yes, continue',
        onConfirm: () => Navigator.pop(context, MilkEntryResult.save(_buildEntry(litres, pending: true, pendingLabel: '+$litres L (second entry)'))),
      );
      return;
    }

    Navigator.pop(context, MilkEntryResult.save(_buildEntry(litres)));
  }

  MilkEntry _buildEntry(double litres, {bool pending = false, String? pendingLabel}) => MilkEntry(
        id: widget.editing?.id ?? 'e${DateTime.now().microsecondsSinceEpoch}',
        cow: _cow.name,
        breed: _cow.breed,
        belt: _cow.belt,
        farm: _farm,
        manager: widget.editing?.manager ?? 'Anita',
        date: _date,
        session: _session,
        time: TimeOfDay.now(),
        litres: litres,
        pendingApproval: pending,
        pendingLabel: pendingLabel,
      );

  // ── #s8-warn-backdrop / #s7-dup-backdrop — identical centred confirm card ──
  // backdrop rgba(0,0,0,0.45); padding 28px; card #FFFFFF, radius 20,
  // padding 26px 22px, box-shadow 0 24px 60px rgba(0,0,0,0.30), centred text.
  void _showConfirmCard({required String title, required String body, required String confirmLabel, required VoidCallback onConfirm}) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 24), blurRadius: 60)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 46x46 circle, --warnbg fill, 1px --warning ring, ⚠ at 20px.
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _warnBg,
                  border: Border.all(color: VanixColors.warning, width: 1),
                ),
                child: const Text('⚠', style: TextStyle(fontSize: 20, color: Color(0xFF000000))),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _text1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.6, color: _text2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VanixColors.greenInk,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(confirmLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _text1,
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: _border, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── field-group label: 11px/w500, letter-spacing .1em → 1.1px, uppercase,
  // --text2, class="en" → NotoSans. margin-bottom 6 (10 under LITRES). ──
  Widget _label(String text, {double bottom = 6}) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: _text2, fontFamily: 'NotoSans'),
        ),
      );

  /// 10px helper line under a field — margin-top 4, --text2, --font-hi (no .en).
  Widget _helper(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: TextStyle(fontSize: 10, color: _text2)),
      );

  /// A `.sel` <select>: 46px tall, --bgcard, 1px --border, radius 12,
  /// padding 0 32px 0 14px, 15px --text1 in --font-hi, and NO chevron — the
  /// inline `background` shorthand nukes the .sel background-image to none.
  Widget _select<T>({required T value, required List<T> items, required String Function(T) label, required ValueChanged<T> onChanged}) {
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.only(start: 14, end: 32),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const SizedBox.shrink(),
          iconSize: 0,
          dropdownColor: _cardBg,
          style: TextStyle(fontSize: 15, color: _text1),
          items: [for (final it in items) DropdownMenuItem<T>(value: it, child: Text(label(it), overflow: TextOverflow.ellipsis))],
          onChanged: (v) => onChanged(v as T),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // #s8-body — padding 14px 24px 0.
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    // [data-owner-only] FARM group — margin-top 18, hidden for
                    // farmer/manager personas by .persona-* { display:none }.
                    if (widget.appState.isOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Farm'),
                            _select<String>(
                              value: _farm,
                              items: MilkSeed.farms,
                              label: (f) => f,
                              onChanged: (v) => setState(() => _farm = v),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Cow'),
                          _select<Cow>(
                            value: _cow,
                            items: MilkSeed.cows,
                            label: _cowLabel,
                            onChanged: (v) => setState(() => _cow = v),
                          ),
                          _helper('Only CALVED and MILKING cows are listed'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Date'),
                          _dateField(),
                          _helper('Defaults to today · future dates not allowed'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Milking session'),
                          // #s8-sessions — flex row, gap 8.
                          Row(
                            children: [
                              Expanded(child: _sessionPill(MilkSession.morning)),
                              const SizedBox(width: 8),
                              Expanded(child: _sessionPill(MilkSession.evening)),
                            ],
                          ),
                          _helper('Defaults to the current time of day'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Litres', bottom: 10),
                          _litresRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // .s8-actions — sticky bottom:0, --bgwarm, padding 12px 0 16px, gap 10.
            Container(
              color: _warmBg,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: _text1,
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: _border, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VanixColors.greenInk,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header row — align-items:center, gap 6. #s8-back is a 40x40 circle with
  /// --bgcard fill + 1px --border and an 18px '‹' at line-height 18px; the
  /// title is 22px/w600 --text1 with line-height 40px. No trailing action.
  Widget _header() => Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cardBg,
                border: Border.all(color: _border, width: 1),
              ),
              child: Text('‹', style: TextStyle(fontSize: 18, height: 1, color: _text1)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.editing != null ? 'Edit Milk Entry' : 'Add Milk Entry',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 40 / 22, color: _text1),
            ),
          ),
        ],
      );

  /// #s8-date — same 46px shell as a select but padding 0 14px (no 32px right
  /// gutter) and class="en" → NotoSans. Value renders dd/mm/yyyy (en-GB UA)
  /// with Chrome's calendar-picker glyph at --text1, not --text2.
  Widget _dateField() => InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dateLabel(_date), style: TextStyle(fontSize: 15, color: _text1, fontFamily: 'NotoSans')),
              Icon(Icons.calendar_today_outlined, size: 16, color: _text1),
            ],
          ),
        ),
      );

  /// #s8-sessions button. ON: --greenink fill + ring, #FFFFFF, w600.
  /// OFF: transparent, and because paint() blanks the inline color/border-color
  /// the UA button defaults win — both compute to #000000, w500.
  /// Evening on today before 17:00 is opacity .4 + pointer-events:none.
  Widget _sessionPill(MilkSession session) {
    final on = _session == session;
    final locked = session == MilkSession.evening && _eveningLocked;
    final offInk = _isDark ? VanixColors.textOnDarkDim : const Color(0xFF000000);
    return Opacity(
      opacity: locked ? 0.4 : 1,
      child: IgnorePointer(
        ignoring: locked,
        child: InkWell(
          onTap: () => _selectSession(session),
          borderRadius: BorderRadius.circular(21),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? VanixColors.greenInk : Colors.transparent,
              border: Border.all(color: on ? VanixColors.greenInk : (_isDark ? _border : offInk), width: 1),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Text(
              session.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: on ? Colors.white : offInk,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// LITRES row — align-items:baseline, gap 10, padding-bottom 10,
  /// border-bottom 1.5px #9A948A. Input 32px/w700 --text1 in --font-en;
  /// "Ltrs" 16px/w500 --text2 in --font-en.
  Widget _litresRow() => Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _isDark ? _border : _litresRule, width: 1.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: TextField(
                controller: _litresCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _text1, fontFamily: 'NotoSans'),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0.0',
                  hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _placeholder, fontFamily: 'NotoSans'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Ltrs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _text2, fontFamily: 'NotoSans')),
          ],
        ),
      );
}
