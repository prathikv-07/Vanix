import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Add Cattle — pixel parity with `#page-add-cattle` in prototype.html.
///
/// Every number in this file was read off the live prototype with
/// getComputedStyle (never off the markup — the inline styles are partly
/// overridden, and in a couple of places outright broken; see the notes on
/// the age/status selects below).
///
/// Layout: white full-bleed page → header (back 34px circle + 22px title) →
/// "Cattle Detail / Device Details" tab row → scrolling pane → Cancel/Save
/// footer. The Cattle Detail pane leads with a centred 160×160 dashed
/// photo-upload tile, then a 14px-gap stack of 52px-tall fields
/// (Name / Type / Breed / Gender), then a two-column Age + Cow Status row of
/// 48px selects, then the "Add cow history" link. That link swaps the same
/// header/body into the Cow History pane (2×2 date grid + Calving Number
/// stepper) rather than pushing a new sheet, and the tab row hides while it
/// is open. Type / Breed / Gender open a bottom-sheet picker.
class AddCattleScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const AddCattleScreen({super.key, required this.appState, required this.farm});

  @override
  State<AddCattleScreen> createState() => _AddCattleScreenState();
}

class _AddCattleScreenState extends State<AddCattleScreen> {
  String _tab = 'cow'; // cow | device
  bool _showHistory = false;
  int _lactation = 2;

  // Picker-backed values (AC_PICKER_OPTS in prototype.html).
  String _type = 'Cow';
  String _breed = 'Select';
  String _gender = 'Select';
  // Native <select> values — the closed state shows the first <option>.
  String _ageYears = 'yearsWord';
  String _ageMonths = 'monthsWord';
  String _status = 'selectWord';

  static const List<String> _typeOpts = ['Cow', 'Sheep', 'Buffalo'];
  static const List<String> _breedOpts = ['Jersey', 'Gir', 'Sahiwal', 'Ongole', 'Desi'];
  static const List<String> _genderOpts = ['Female', 'Male'];
  static const List<String> _yearOpts = ['yearsWord', '0', '1', '2', '3', '4', '5'];
  static const List<String> _monthOpts = ['monthsWord', '0', '3', '6', '9'];
  static const List<String> _statusOpts = ['selectWord', 'stMilking', 'stPreg', 'statusUnknown', 'stDry'];

  /// Strings the prototype ships that `FS` does not carry yet — `FS.t` falls
  /// back to the raw key, which would render "acTabCowDetails" on screen.
  /// Local fallback only; the real fix belongs in lib/i18n/farm_strings.dart.
  static const Map<String, Map<String, String>> _localStrings = {
    'en': {
      'acTabCowDetails': 'Cattle Detail',
      'acTabDeviceDetails': 'Device Details',
      'acAddHistory': 'Add cow history',
      'acNodeMacId': 'Node/MAC ID',
      'statusUnknown': 'Before Estrus',
    },
    'hi': {
      'acTabCowDetails': 'पशु विवरण',
      'acTabDeviceDetails': 'डिवाइस विवरण',
      'acAddHistory': 'गाय का इतिहास जोड़ें',
      'acNodeMacId': 'नोड/MAC आईडी',
      'statusUnknown': 'एस्ट्रस से पहले',
    },
  };

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  String _t(String key) {
    final v = FS.t(_lang, key);
    if (v != key) return v;
    return _localStrings[_lang]?[key] ?? _localStrings['en']![key] ?? key;
  }

  // ── measured tokens ──
  // Light: --bgcard #FFFFFF, --border #D8D0C5, --divider #EBE6DD,
  // --text1 #111111, --text2 #8C8780, --bgwarm #F2EDE4, --greenink #1E7A52.
  // Dark (#flow-root.dark) drifts from the shared tokens — see the harness
  // ckfail lines; the closest tokens are used until the dark pass lands.
  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _divider => _isDark ? VanixColors.darkDivider : VanixColors.divider;
  Color get _text1 => _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  Color get _warmBg => _isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;

  void _back() {
    if (_showHistory) {
      setState(() => _showHistory = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
    return Theme(
      data: theme,
      child: Scaffold(
        // #page-add-cattle background is a literal #FFFFFF (= --bgcard light).
        backgroundColor: _cardBg,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              // The tab row is hidden while the Cow History pane is open.
              if (!_showHistory) _tabsRow(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                  children: _showHistory
                      ? _historyPane()
                      : _tab == 'cow'
                          ? _cowPane()
                          : _devicePane(),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── header — padding 16/16/16/12, gap 4px, 34px circular back button ──
  Widget _header() => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Material(
                color: _warmBg,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  // svg 17×17, stroke-width 2.2, stroke var(--text1)
                  child: Icon(Icons.chevron_left, size: 17, color: _text1),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _t(_showHistory ? 'acCowHistory' : 'addCattle'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2, color: _text1),
            ),
          ],
        ),
      );

  // ── tab row — padding 0/16, gap 8, 1px --divider underline ──
  Widget _tabsRow() => Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _divider))),
        child: Row(children: [
          Expanded(child: _tabBtn('acTabCowDetails', 'cow')),
          const SizedBox(width: 8),
          Expanded(child: _tabBtn('acTabDeviceDetails', 'device')),
        ]),
      );

  Widget _tabBtn(String labelKey, String value) {
    final on = _tab == value;
    return InkWell(
      onTap: () => setState(() => _tab = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: on ? VanixColors.greenInk : Colors.transparent, width: 3)),
        ),
        child: Text(
          _t(labelKey),
          style: TextStyle(
            fontSize: 14,
            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
            color: on ? VanixColors.greenInk : VanixColors.textHint,
          ),
        ),
      ),
    );
  }

  // ── Cattle Detail pane ──
  List<Widget> _cowPane() => [
        Center(child: _photoUpload()),
        const SizedBox(height: 20),
        _bigInput(_t('acCowName')),
        const SizedBox(height: 14),
        _bigSelect('Type', _type, () => _openPicker('Type', _typeOpts, _type, (v) => _type = v)),
        const SizedBox(height: 14),
        _bigSelect(_t('breedWord'), _breed, () => _openPicker(_t('breedWord'), _breedOpts, _breed, (v) => _breed = v)),
        const SizedBox(height: 14),
        _bigSelect(_t('genderWord'), _gender, () => _openPicker(_t('genderWord'), _genderOpts, _gender, (v) => _gender = v)),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('ageWord'),
                Row(children: [
                  Expanded(child: _select(_ageYears, _yearOpts, (v) => _ageYears = v)),
                  const SizedBox(width: 8),
                  Expanded(child: _select(_ageMonths, _monthOpts, (v) => _ageMonths = v)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('cowStatusWord'),
                _select(_status, _statusOpts, (v) => _status = v),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: InkWell(
            onTap: () => setState(() => _showHistory = true),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add, size: 16, color: VanixColors.greenInk),
              const SizedBox(width: 6),
              Text(_t('acAddHistory'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
            ]),
          ),
        ),
      ];

  // ── Device Details pane ──
  List<Widget> _devicePane() => [
        _label('acBeltNo'),
        _input('e.g. 026'),
        _label('acNodeMacId', top: 16),
        _input('A4:C1:38:2B:9F:11'),
      ];

  // ── Cow History pane — two 2-up date rows, then the Calving Number stepper ──
  List<Widget> _historyPane() => [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('acLastHeat'), _dateField()])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('acLastInsem'), _dateField()])),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('acLastPreg'), _dateField()])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('acLastCalving'), _dateField()])),
          ]),
        ),
        _label('acLactationNo', top: 14),
        _stepper(),
      ];

  // ── footer — padding 12/16, gap 10, Cancel:Save = 1:1.6 ──
  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Row(children: [
          Expanded(
            flex: 5,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: EdgeInsets.zero,
                backgroundColor: _cardBg,
                side: BorderSide(color: _border, width: 1),
                foregroundColor: _text1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_t('cancelWord'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 8,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: EdgeInsets.zero,
                backgroundColor: VanixColors.greenInk,
                foregroundColor: VanixColors.textOnDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_t('saveWord'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );

  // ── field label — 11px/700, letter-spacing .05em @11px = 0.55px, uppercase ──
  Widget _label(String key, {double top = 0}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 7),
        child: Text(
          _t(key).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: VanixColors.textHint,
          ),
        ),
      );

  BoxDecoration get _fieldDeco => BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _border, width: 1),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      );

  // 48px input — Device Details. class="en" ⇒ NotoSans, not Devanagari.
  Widget _input(String placeholder) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: _fieldDeco,
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          style: TextStyle(fontSize: 15, color: _text1, fontFamily: 'NotoSans'),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: placeholder,
            hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 15, fontFamily: 'NotoSans'),
          ),
        ),
      );

  // 52px input — #ac-name-input (padding 0 16, radius 12).
  Widget _bigInput(String placeholder) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: _fieldDeco,
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          style: TextStyle(fontSize: 15, color: _text1),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: placeholder,
            hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 15),
          ),
        ),
      );

  // 52px "Label Value ⌄" row — #ac-type-btn / -breed- / -gender-.
  // One space between label and value; chevron svg is 12×12, stroke --text2.
  Widget _bigSelect(String label, String value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VanixRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          decoration: _fieldDeco,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: VanixColors.textHint),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1, fontFamily: 'NotoSans'),
                  ),
                ]),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 12, color: VanixColors.textHint),
          ]),
        ),
      );

  // 48px native <select>. Two things measured here that the markup hides:
  //  · the closed value renders in --text1, NOT the hint colour — even for
  //    the "Years" / "Months" / "Select" first options;
  //  · the chevron background-image never applies. Its inline `url("data:…")`
  //    contains double quotes inside a double-quoted style attribute, so the
  //    declaration is truncated — computed background-image is url("") and
  //    background-position falls back to 0% 0%. So: no chevron at all.
  Widget _select(String value, List<String> opts, void Function(String) set) => InkWell(
        onTap: () => _openPicker(null, opts, value, set, translate: true),
        borderRadius: BorderRadius.circular(VanixRadius.md),
        child: Container(
          height: 48,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: _fieldDeco,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            _t(value),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(fontSize: 15, color: _text1),
          ),
        ),
      );

  // 160×160 dashed photo tile — 1.5px dashed --border, radius 16, padding 8,
  // 8px gap, 26px icon, 12px/1.3 caption.
  Widget _photoUpload() => CustomPaint(
        painter: _DashedRRectPainter(color: _border, strokeWidth: 1.5, radius: 16),
        child: Container(
          width: 160,
          height: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 26, color: VanixColors.textHint),
              const SizedBox(height: 8),
              Text(
                _t('acPhotoHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.3, color: VanixColors.textHint),
              ),
            ],
          ),
        ),
      );

  // <input type="date"> — Chrome paints "dd/mm/yyyy" in --text1 plus its own
  // calendar glyph on the trailing edge. class="en" ⇒ NotoSans.
  Widget _dateField() => Container(
        height: 48,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: _fieldDeco,
        child: Row(children: [
          Expanded(
            child: Text('dd/mm/yyyy',
                style: TextStyle(fontSize: 15, color: _text1, fontFamily: 'NotoSans')),
          ),
          Icon(Icons.calendar_today_outlined, size: 16, color: _text1),
        ]),
      );

  // Calving Number stepper — 48px row, radius 12, clipped; value flex:1 with
  // 14px inline padding, then two 48px full-height buttons each with a 1px
  // leading divider and a 20px glyph.
  Widget _stepper() => Container(
        height: 48,
        decoration: _fieldDeco,
        clipBehavior: Clip.hardEdge,
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              child: Text('$_lactation',
                  style: TextStyle(fontSize: 15, color: _text1, fontFamily: 'NotoSans')),
            ),
          ),
          _stepBtn('–', () => setState(() {
                if (_lactation > 0) _lactation--;
              })),
          _stepBtn('+', () => setState(() => _lactation++)),
        ]),
      );

  Widget _stepBtn(String glyph, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: _border, width: 1))),
          child: Text(glyph, style: TextStyle(fontSize: 20, color: _text1)),
        ),
      );

  // ── #ac-picker-sheet — radius 24 top, padding 8/24/24, NO shadow (the
  // [id$="-sheet"] rule kills it), 36×4 grabber, 38px circular ✕, options
  // 46px tall with 4px inline padding; selected = --greenink/600. ──
  void _openPicker(String? title, List<String> opts, String current, void Function(String) set, {bool translate = false}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x59000000), // rgba(0,0,0,0.35)
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Material(
                    color: _warmBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(child: Text('✕', style: TextStyle(fontSize: 15, color: _text1))),
                    ),
                  ),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: opts.map((o) {
                  final sel = o == current;
                  return InkWell(
                    onTap: () {
                      setState(() => set(o));
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        translate ? _t(o) : o,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          color: sel ? VanixColors.greenInk : _text1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// CSS `border:1.5px dashed` — Blink strokes dashes of 3× the border width
/// with equal gaps, i.e. 4.5 on / 4.5 off around the 16px-radius rect.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.strokeWidth, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(radius),
      ));
    const dash = 4.5;
    const gap = 4.5;
    for (final metric in path.computeMetrics()) {
      double pos = 0;
      while (pos < metric.length) {
        final next = pos + dash;
        canvas.drawPath(metric.extractPath(pos, next.clamp(0, metric.length)), paint);
        pos = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}
