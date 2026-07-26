import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../models/group_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cattle Groups (#page-groups) + its four bottom sheets.
// Every literal below was MEASURED off the live prototype with
// getComputedStyle — inline styles in prototype.html are overridden by later
// CSS rules, so the markup is not authoritative. Notable traps:
//   • `[id$="-sheet"] { box-shadow:none !important }` (line 986) kills the
//     inline `0 -8px 32px rgba(0,0,0,0.18)` on all four sheets → no shadow.
//   • `.en` elements resolve to the Latin face var(--font-en) = NotoSans.
//   • `#flow-root.dark .m-hero p` forces the hero subtitle to --text1, so in
//     dark mode it is NOT --text2.
//   • `#flow-root.dark .m-hero` deepens the hero shadow to 55% opacity.
// ─────────────────────────────────────────────────────────────────────────────

// Sheet chrome — measured: padding 8px 24px 28px, border-radius 24px 24px 0 0.
const EdgeInsets _kSheetPad = EdgeInsets.fromLTRB(24, 8, 24, 28);
const double _kSheetRadius = 24;

// Grabber wrapper padding is 6px 0 2px; the header below it adds margin-top:10.
const EdgeInsets _kGrabPad = EdgeInsets.only(top: 6, bottom: 2);
const double _kGrabWidth = 36;
const double _kGrabHeight = 4;

const double _kCloseSize = 36; // sheet ✕ button: 36x36, border-radius:50%
const double _kRemoveSize = 30; // member-row ✕ button: 30x30
const double _kCheckSize = 18; // list checkbox: 18x18, accent-color --greenink
const double _kListRowGap = 10; // gap:10px on every flex list row

/// Measured colour pairs for this screen. Light values come from the prototype
/// root vars; dark values from `#flow-root.dark`.
class _P {
  final bool dark;
  const _P(this.dark);

  Color get text1 => dark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  Color get text2 => VanixColors.textHint;
  Color get border => dark ? VanixColors.darkBorder : VanixColors.border;
  Color get divider => dark ? VanixColors.darkDivider : VanixColors.divider;
  Color get card => dark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get warm => dark ? VanixColors.darkPrimary : VanixColors.bgWarm;
  Color get sheet => dark ? VanixColors.darkSecond : VanixColors.bgCard;
}

/// Round ✕ button — measured 36x36 (sheet close) / 30x30 (member remove),
/// border-radius:50%, background var(--bgwarm), glyph "✕" at font-size:14px.
Widget _closeGlyphBtn({
  required double size,
  required Color bg,
  required Color fg,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text('✕', style: TextStyle(fontSize: 14, height: 1, color: fg)),
        ),
      ),
    ),
  );
}

/// `border: 1.5px dashed var(--border)` on #groups-new-btn — Flutter has no
/// dashed BoxBorder, so the stroke is painted.
class _DashedRRectBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  const _DashedRRectBorder({required this.color, required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    const dash = 4.5; // Chrome renders a 1.5px dashed stroke as ~3w dash / 2w gap
    const gap = 3.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectBorder old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

/// Sheet shell: grabber + 18/700 title + round ✕, then [children].
/// `maxHeightFactor` mirrors the sheet's measured max-height (78vh / 70vh);
/// #grp-new-sheet has none, so it is null there.
Widget _sheetShell({
  required BuildContext ctx,
  required _P p,
  required String title,
  required List<Widget> children,
  double? maxHeightFactor,
}) {
  final body = Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: _kGrabPad,
        child: Center(
          child: Container(
            width: _kGrabWidth,
            height: _kGrabHeight,
            decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.text1)),
        ),
        _closeGlyphBtn(size: _kCloseSize, bg: p.warm, fg: p.text1, onTap: () => Navigator.pop(ctx)),
      ]),
      ...children,
    ],
  );
  return Container(
    constraints: maxHeightFactor == null
        ? const BoxConstraints()
        : BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * maxHeightFactor),
    decoration: BoxDecoration(
      color: p.sheet,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_kSheetRadius)),
    ),
    padding: _kSheetPad,
    child: body,
  );
}

/// Checkbox list row — measured: padding 10px 0, border-bottom 1px solid
/// var(--divider), gap 10px, 18x18 checkbox with accent-color var(--greenink).
Widget _checkRow({
  required _P p,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Widget label,
}) {
  return InkWell(
    onTap: () => onChanged(!value),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.divider, width: 1))),
      child: Row(children: [
        SizedBox(
          width: _kCheckSize,
          height: _kCheckSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: VanixColors.greenInk,
              side: BorderSide(color: p.border, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: _kListRowGap),
        Expanded(child: label),
      ]),
    ),
  );
}

/// Pill CTA — measured: min-height 48, border-radius 24, background
/// var(--greenink) in BOTH themes (not greenDeep), 14px/600 white label.
Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: VanixColors.greenInk,
          foregroundColor: VanixColors.textOnDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );

/// Secondary pill — measured: min-height 48, radius 24, 1px solid
/// var(--border), background var(--bgcard), label var(--text1) 14px/600.
Widget _secondaryBtn(_P p, String label, VoidCallback onTap) => SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.border, width: 1),
          backgroundColor: p.card,
          foregroundColor: p.text1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );

/// Cancel + Save footer — measured: display:flex, gap:10px, both flex:1.
Widget _btnPair(_P p, String cancelLabel, VoidCallback onCancel, String saveLabel, VoidCallback onSave) => Row(
      children: [
        Expanded(child: _secondaryBtn(p, cancelLabel, onCancel)),
        const SizedBox(width: 10),
        Expanded(child: _primaryBtn(saveLabel, onSave)),
      ],
    );

/// Centred empty-state paragraph — measured: text-align center, font-size 13,
/// colour var(--text2).
Widget _emptyText(_P p, String label, {required EdgeInsets margin}) => Padding(
      padding: margin,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: p.text2),
      ),
    );

/// Add-to-group sheet, reachable from a cow's kebab (Farm Detail / Cow
/// Profile). Mirrors #cow-grp-sheet — a checkbox list of every group with this
/// cow's membership toggled. Measured max-height:70vh.
Future<void> showAddToGroupSheet(BuildContext context, AppState appState, String farmId, int no) {
  final lang = appState.languageCode;
  final p = _P(appState.isDark);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => _sheetShell(
        ctx: ctx,
        p: p,
        title: FS.t(lang, 'addToGroupTitle'),
        maxHeightFactor: 0.70,
        children: [
          const SizedBox(height: 12), // #cow-grp-list margin-top:12px
          if (kGroups.isEmpty)
            _emptyText(p, FS.t(lang, 'noGroupsYet'), margin: const EdgeInsets.symmetric(vertical: 12))
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final g in kGroups)
                      _checkRow(
                        p: p,
                        value: g.has(farmId, no),
                        onChanged: (v) {
                          g.toggle(farmId, no, v);
                          setSheet(() {});
                        },
                        label: Text(g.name, style: TextStyle(fontSize: 14, color: p.text1)),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12), // #cow-grp-save margin-top:12px
          _primaryBtn(FS.t(lang, 'saveWord'), () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}

/// Cattle Groups (Account → Cattle Groups) — owner-only. Mirrors #page-groups
/// in prototype.html: create groups, open a group to add/remove cattle.
class GroupsScreen extends StatefulWidget {
  final AppState appState;
  const GroupsScreen({super.key, required this.appState});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;
  String _t(String k) => FS.t(_lang, k);
  _P get _p => _P(_isDark);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        return Theme(
          data: theme,
          child: Scaffold(
            // #page-groups background:var(--bgwarm)
            backgroundColor: _p.warm,
            body: SafeArea(
              child: ListView(
                // scroller padding: 0 0 40px
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  _hero(),
                  Padding(
                    // content wrapper padding: 14px 16px 0
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                    child: Column(
                      children: [
                        _newGroupButton(),
                        const SizedBox(height: 12), // #groups-list margin-top:12px
                        if (kGroups.isEmpty)
                          _emptyText(_p, _t('noGroupsYet'), margin: const EdgeInsets.only(top: 20))
                        else
                          for (final g in kGroups) _groupRow(g),
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

  /// .m-hero — measured: padding 18px 16px, border-radius 0 0 14px 14px,
  /// box-shadow 0 12px 28px rgba(0,0,0,0.18) → 0.55 in dark, background
  /// var(--bgwarm) light / #1C1C1C dark. Row gap is 2px and the 40x40 back
  /// button carries margin-inline-start:-10px, so the start padding is
  /// folded to 16-10=6 to land the title at x=48 exactly.
  Widget _hero() {
    final p = _p;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 18, 16, 18),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.55 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            // svg width/height 20, stroke var(--text1)
            icon: Icon(Icons.chevron_left, size: 20, color: p.text1),
          ),
        ),
        const SizedBox(width: 2), // hero row gap:2px
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('rowCattleGroups'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: p.text1),
              ),
              const SizedBox(height: 2), // subtitle margin:2px 0 0
              Text(
                _t('groupsSub'),
                // dark: `.m-hero p` is forced to --text1, not --text2
                style: TextStyle(fontSize: 11, color: _isDark ? p.text1 : p.text2),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  /// #groups-new-btn — measured: min-height 46, border-radius 14,
  /// border 1.5px DASHED var(--border), background transparent,
  /// colour var(--greenink), 14px/600, centred.
  Widget _newGroupButton() {
    return CustomPaint(
      painter: _DashedRRectBorder(color: _p.border, radius: 14, strokeWidth: 1.5),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _openNewGroup,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 46),
            backgroundColor: Colors.transparent,
            foregroundColor: VanixColors.greenInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(_t('newGroupBtn'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  /// .grp-row — measured: padding 14, margin-bottom 10, border-radius 16,
  /// border 1px solid var(--border), background var(--bgcard), gap 10,
  /// NO box-shadow. Name 14px/600 var(--text1); the count carries class="en"
  /// so it renders in the Latin face at 12px var(--text2).
  Widget _groupRow(CattleGroup g) {
    final p = _p;
    return InkWell(
      onTap: () => _openGroupDetail(g),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border, width: 1),
        ),
        child: Row(children: [
          Expanded(
            child: Text(g.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text1)),
          ),
          const SizedBox(width: _kListRowGap),
          Text(
            '${g.members.length} ${_t('cowsWord')}',
            style: TextStyle(fontSize: 12, color: p.text2, fontFamily: 'NotoSans'),
          ),
        ]),
      ),
    );
  }

  // ── #grp-new-sheet — new-group name ──
  void _openNewGroup() {
    final ctrl = TextEditingController();
    final p = _p;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _sheetShell(
          ctx: ctx,
          p: p,
          title: _t('newGroupBtn'),
          children: [
            const SizedBox(height: 14), // #grp-new-name margin-top:14px
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(fontSize: 13, color: p.text1),
              // measured: min-height 44, padding 0 12, background var(--bgwarm),
              // 1px solid var(--border), border-radius 10, font-size 13.
              decoration: InputDecoration(
                hintText: _t('groupNamePh'),
                hintStyle: TextStyle(fontSize: 13, color: p.text2),
                filled: true,
                fillColor: p.warm,
                isDense: true,
                constraints: const BoxConstraints(minHeight: 44),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: p.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: p.border, width: 1),
                ),
                // the prototype defines no :focus style — the border stays --border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: p.border, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 8), // collapsed input/button-row margins
            _btnPair(p, _t('cancelWord'), () => Navigator.pop(ctx), _t('createGroup'), () {
              final nm = ctrl.text.trim();
              if (nm.isNotEmpty) {
                final g = CattleGroup(id: 'g${DateTime.now().millisecondsSinceEpoch}', name: nm);
                kGroups.add(g);
                Navigator.pop(ctx);
                setState(() {});
                _openGroupDetail(g);
              }
            }),
          ],
        ),
      ),
    );
  }

  // ── #grp-detail-sheet — members + add cattle (max-height:78vh) ──
  void _openGroupDetail(CattleGroup g) {
    final p = _p;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell(
          ctx: ctx,
          p: p,
          title: g.name,
          maxHeightFactor: 0.78,
          children: [
            const SizedBox(height: 12), // #grp-detail-cows margin-top:12px
            if (g.members.isEmpty)
              _emptyText(p, _t('noCowsInGroup'), margin: const EdgeInsets.symmetric(vertical: 12))
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final m in g.members) _memberRow(p, g, m, setSheet)],
                  ),
                ),
              ),
            const SizedBox(height: 12), // #grp-add-cattle-btn margin-top:12px
            _addCattleBtn(() => _openPicker(g, () => setSheet(() {}))),
          ],
        ),
      ),
    );
  }

  /// Member row — measured: padding 10px 0, border-bottom 1px solid
  /// var(--divider), gap 10, name 14px/600 var(--text1), farm name class="en"
  /// so Latin face at 11px var(--text2) with margin-top:2px, and a 30x30
  /// round ✕ at 14px var(--text2) on var(--bgwarm).
  Widget _memberRow(_P p, CattleGroup g, GroupMember m, StateSetter setSheet) {
    final farm = kFarms.firstWhere((f) => f.id == m.farmId);
    final cow = farm.cows.firstWhere((c) => c.no == m.no);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.divider, width: 1))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cow.nm(_lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text1)),
            const SizedBox(height: 2),
            Text(farm.nm(_lang), style: TextStyle(fontSize: 11, color: p.text2, fontFamily: 'NotoSans')),
          ]),
        ),
        const SizedBox(width: _kListRowGap),
        _closeGlyphBtn(
          size: _kRemoveSize,
          bg: p.warm,
          fg: p.text2,
          onTap: () {
            setState(() => g.members.removeWhere((x) => x.farmId == m.farmId && x.no == m.no));
            setSheet(() {});
          },
        ),
      ]),
    );
  }

  /// #grp-add-cattle-btn — measured: min-height 46, border-radius 23,
  /// 1px solid var(--greenink), background var(--activebg), 14px/600.
  Widget _addCattleBtn(VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            side: const BorderSide(color: VanixColors.greenInk, width: 1),
            backgroundColor: VanixColors.activeBg,
            foregroundColor: VanixColors.greenInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          ),
          child: Text(_t('addCattleBtn'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );

  // ── #grp-pick-sheet — add-cattle picker (max-height:78vh) ──
  void _openPicker(CattleGroup g, VoidCallback onClosed) {
    final p = _p;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell(
          ctx: ctx,
          p: p,
          title: _t('addCattleBtn'),
          maxHeightFactor: 0.78,
          children: [
            const SizedBox(height: 12), // #grp-pick-list margin-top:12px
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final fc in allCowsFlat())
                      _checkRow(
                        p: p,
                        value: g.has(fc.farm.id, fc.cow.no),
                        onChanged: (v) {
                          g.toggle(fc.farm.id, fc.cow.no, v);
                          setSheet(() {});
                        },
                        // cow name 14px --text1, then a nested class="en" span
                        // at 11px --text2 holding "— <farm>"
                        label: Text.rich(
                          TextSpan(
                            text: fc.cow.nm(_lang),
                            style: TextStyle(fontSize: 14, color: p.text1),
                            children: [
                              TextSpan(
                                text: ' — ${fc.farm.nm(_lang)}',
                                style: TextStyle(fontSize: 11, color: p.text2, fontFamily: 'NotoSans'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12), // button row margin-top:12px
            _btnPair(p, _t('cancelWord'), () => Navigator.pop(ctx), _t('saveWord'), () {
              Navigator.pop(ctx);
              setState(() {});
              onClosed();
            }),
          ],
        ),
      ),
    );
  }
}
