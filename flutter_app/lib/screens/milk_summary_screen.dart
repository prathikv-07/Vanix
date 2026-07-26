import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Milk Summary — pixel parity with `#s7-stats` in prototype.html (the
/// "complete summary" view that expands out of the Milk Log hero when
/// "View complete summary" is tapped).
///
/// Every number here came off the live prototype via getComputedStyle, never
/// off the markup: the inline styles on this screen are partly overridden by
/// later CSS. The traps that bit, all measured:
///
///  * `#s7-stats.stats-open .m-hero { box-shadow:none !important }` wins over
///    `.m-hero`'s own inline `0 12px 28px` — the retained hero has NO shadow
///    while the summary is open. `.m-stat-card` on the other hand DOES carry
///    the Airbnb card shadow (`0 4px 16px rgba(0,0,0,.06), 0 1px 3px .04`).
///  * The breed chips' weight is a specificity accident. `.s7-bchip.on` sets
///    `font-weight:600`, but only the "All breeds" chip carries an inline
///    `font-weight:500`, and inline beats a non-important class rule. So
///    "All breeds" measures 500 in BOTH states, while every other chip
///    measures 400 off / 600 on.
///  * The chips' dark surface comes from their inline `var(--bgcard)` /
///    `var(--border)` (→ #1E1E1E / #333333) because inline beats the
///    non-important `#flow-root.dark .s7-bchip` rule that asks for
///    #1C1C1C / #3A3A3A. The stat cards are the opposite: their dark rule IS
///    `!important`, so they measure #1C1C1C / #3A3A3A.
///  * Dark `--text2` is #9E988E, but every muted label on this screen is
///    re-overridden to the light #8C8780 by `.m-hero p[class~="en"]`,
///    `.m-tile p + p` and `.m-stat-card p[style*="text2"]`.
///  * The bar rows have NO track: `.m-btrack` is a bare flex row, the fill is
///    a `width:pct%` flex item next to the value. Nothing grey behind it.
///  * `class="en"` nodes need `fontFamily: 'NotoSans'` — litres, week labels,
///    every numeric and every uppercase caption on this screen is one.
class MilkSummaryScreen extends StatelessWidget {
  final AppState appState;
  const MilkSummaryScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDark;
    return Scaffold(
      // #s7-stats: light background:var(--bgwarm); dark #111111 !important.
      backgroundColor: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // inner wrapper padding:0 0 120px
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _SummaryHero(appState: appState),
            MilkSummaryContent(appState: appState, padding: const EdgeInsets.fromLTRB(20, 16, 20, 0)),
          ],
        ),
      ),
    );
  }
}

/// The retained hero replica at the top of `#s7-stats` — an exact copy of the
/// Milk Log hero so the clip-path expand reads as seamless.
class _SummaryHero extends StatelessWidget {
  final AppState appState;
  const _SummaryHero({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDark;
    final text1 = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    // .m-hero button { border-color:#3A3A3A } in dark; --border in light.
    final btnBorder = isDark ? VanixColors.darkHairline : VanixColors.border;
    return Container(
      // padding:18px 16px 20px; border-radius:0 0 14px 14px
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        // light var(--bgwarm); dark .m-hero → #1C1C1C !important
        color: isDark ? VanixColors.darkSecond : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        // .stats-open .m-hero { box-shadow:none !important } — no shadow here
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milk Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: text1)),
              const SizedBox(width: 10),
              Row(
                children: [
                  // .s7-period-btn — h32, radius 16, pad 0 12, 12px/w600, gap 6
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: btnBorder, width: 1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MilkSummaryContent.pillShadow(isDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text1)),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, size: 11, color: text1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // #s7-stats-back — 32x32 circle, funnel glyph 14
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: btnBorder, width: 1),
                      boxShadow: MilkSummaryContent.pillShadow(isDark),
                    ),
                    child: Icon(Icons.filter_alt_outlined, size: 14, color: text1),
                  ),
                ],
              ),
            ],
          ),
          // the Total Milk block sits in a wrapper with margin-top:16px
          const SizedBox(height: 16),
          _SummaryTotals(appState: appState),
        ],
      ),
    );
  }
}

/// Total Milk headline + the three `.m-tile`s + the "Hide complete summary"
/// button — the lower half of the retained hero.
class _SummaryTotals extends StatelessWidget {
  final AppState appState;
  const _SummaryTotals({required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDark;
    final text1 = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    // .m-delta → var(--greendeep) in dark, var(--greenink) in light.
    final accent = isDark ? VanixColors.greenDeep : VanixColors.greenInk;
    final btnBorder = isDark ? VanixColors.darkHairline : VanixColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 11px/w500, letter-spacing:.08em = 0.88px, uppercase, class="en"
        const Text(
          'TOTAL MILK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
            color: VanixColors.textHint,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // 32px/w700, line-height:1
            Text('38.6 L', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.0, color: text1, fontFamily: 'NotoSans')),
            const SizedBox(width: 10),
            Text('▲ 8% vs yesterday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent, fontFamily: 'NotoSans')),
            const Spacer(), // margin-inline-start:auto on the download button
            // #s7-stats-dl — 32x32 circle, download glyph 15
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: btnBorder, width: 1),
                boxShadow: MilkSummaryContent.pillShadow(isDark),
              ),
              child: Icon(Icons.file_download_outlined, size: 15, color: text1),
            ),
          ],
        ),
        // tile row margin-top:16px, gap 8
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _tile('18', 'Cows milked', isDark, text1)),
            const SizedBox(width: 8),
            Expanded(child: _tile('12.5 L', 'Max — Gauri', isDark, text1)),
            const SizedBox(width: 8),
            Expanded(child: _tile('2.0 L', 'Min — Kajri', isDark, text1)),
          ],
        ),
        // #s7-stats-collapse — margin-top 12, min-height 38, radius 19, 13/w600
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: btnBorder, width: 1),
            borderRadius: BorderRadius.circular(19),
            boxShadow: MilkSummaryContent.pillShadow(isDark),
          ),
          child: Text('Hide complete summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
        ),
      ],
    );
  }

  /// .m-tile — padding 10, radius 12, 1px border; value 18/w700 class="en",
  /// caption 11px pinned to #8C8780 by `.m-tile p + p` even in dark.
  Widget _tile(String value, String sub, bool isDark, Color text1) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        // .m-tile dark: background #262626, border-color #3A3A3A
        color: isDark ? VanixColors.darkSubSurface : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkHairline : VanixColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text1, fontFamily: 'NotoSans')),
          const SizedBox(height: 2), // margin:2px 0 0
          Text(sub, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}

/// Reusable analytics body — breed filter chips, the 8-week trend chart,
/// highest/lowest week tiles, TOP 5 COWS and YIELD BY BREED bar cards.
/// Used standalone by [MilkSummaryScreen] and expanded in place inside the
/// Milk Log page. The prototype wraps this block in `padding:0 20px`; the
/// caller supplies that plus the chip row's own `margin-top:16px`.
class MilkSummaryContent extends StatefulWidget {
  final AppState appState;
  final EdgeInsets padding;
  final bool showTotalHeader;
  const MilkSummaryContent({super.key, required this.appState, this.padding = EdgeInsets.zero, this.showTotalHeader = false});

  /// #3A3A3A — the literal hairline the prototype's dark rules hard-code for
  /// `.m-stat-card`, `.m-tile` and `.m-hero button`. Deliberately distinct
  /// from `--border` in dark (#333333 = VanixColors.darkBorder), which the
  /// breed chips DO resolve to via their inline style.

  /// box-shadow:0 2px 6px rgba(0,0,0,0.08) on the hero pills; the dark
  /// `.m-hero button` rule deepens it to rgba(0,0,0,0.4).
  static List<BoxShadow> pillShadow(bool isDark) => [
        BoxShadow(color: isDark ? const Color(0x66000000) : const Color(0x14000000), blurRadius: 6, offset: const Offset(0, 2)),
      ];

  @override
  State<MilkSummaryContent> createState() => _MilkSummaryContentState();
}

class _MilkSummaryContentState extends State<MilkSummaryContent> {
  // WEEKS in prototype.html
  static const List<String> _weeks = ['12 May', '19 May', '26 May', '2 Jun', '9 Jun', '16 Jun', '23 Jun', '30 Jun'];

  // STATS in prototype.html — trend / cows / breeds per breed filter.
  static const List<String> _breeds = ['all', 'Jersey', 'Ongole', 'Gir/Sahiwal', 'Desi'];
  static const Map<String, String> _chipLabels = {'all': 'All breeds'};

  static const Map<String, List<double>> _trends = {
    'all': [512, 498, 540, 567, 531, 588, 549, 471],
    'Jersey': [221, 208, 230, 246, 228, 262, 240, 198],
    'Ongole': [186, 182, 198, 205, 192, 214, 200, 171],
    'Gir/Sahiwal': [105, 108, 112, 116, 111, 112, 109, 102],
    'Desi': [36, 34, 38, 40, 37, 42, 39, 35],
  };

  static const Map<String, List<(String, double)>> _cows = {
    'all': [('Gauri', 88.4), ('Lakshmi', 76.2), ('Mohini', 64.9), ('Dhauli', 58.3), ('Kajri', 41.7)],
    'Jersey': [('Gauri', 88.4), ('Kajri', 41.7), ('Rani', 38.2), ('Heera', 29.6), ('Chandni', 16.1)],
    'Ongole': [('Lakshmi', 76.2), ('Ganga', 24.8), ('Radha', 21.1)],
    'Gir/Sahiwal': [('Dhauli', 58.3), ('Sona', 22.4), ('Badal', 15.3)],
    'Desi': [('Mohini', 64.9), ('Kesar', 12.3)],
  };

  static const Map<String, List<(String, double)>> _breedBars = {
    'all': [('Jersey', 214), ('Ongole', 150), ('Gir/Sahiwal', 96), ('Desi', 37)],
    'Jersey': [('Jersey', 214)],
    'Ongole': [('Ongole', 150)],
    'Gir/Sahiwal': [('Gir/Sahiwal', 96)],
    'Desi': [('Desi', 37)],
  };

  String _cur = 'all';
  int? _tipIndex;

  bool get _isDark => widget.appState.isDark;
  Color get _text1 => _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
  // .m-stat-card's dark override is !important: #1C1C1C / #3A3A3A.
  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _cardBorder => _isDark ? VanixColors.darkHairline : VanixColors.border;
  Color get _accent => _isDark ? VanixColors.greenDeep : VanixColors.greenInk;
  // Every muted caption on this screen measures #8C8780 in BOTH modes.
  Color get _muted => VanixColors.textHint;

  /// The prototype prints the raw JS number: 214 → "214 L", 88.4 → "88.4 L".
  static String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final trend = _trends[_cur]!;
    final bars = _breedBars[_cur]!;
    final maxV = trend.reduce(math.max);
    final minV = trend.reduce(math.min);

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTotalHeader) ...[
            _SummaryTotals(appState: widget.appState),
            const SizedBox(height: 16),
          ],
          _breedChips(),
          // .m-stat-card margin-top:12px
          const SizedBox(height: 12),
          _trendCard(trend),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _weekTile('HIGHEST WEEK', maxV, _weeks[trend.indexOf(maxV)])),
              const SizedBox(width: 8),
              Expanded(child: _weekTile('LOWEST WEEK', minV, _weeks[trend.indexOf(minV)])),
            ],
          ),
          const SizedBox(height: 12),
          _barCard('TOP 5 COWS — THIS WEEK', _cows[_cur]!),
          // single-breed view: the breed bar restates the filter — card hidden
          if (bars.length > 1) ...[
            const SizedBox(height: 12),
            _barCard('YIELD BY BREED — THIS WEEK', bars),
          ],
        ],
      ),
    );
  }

  // ── #s7-breed-chips — display:flex, gap 8, overflow-x:auto, pad-bottom 2 ──
  Widget _breedChips() {
    return SizedBox(
      height: 38, // 36px chip + 2px padding-bottom
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 2),
        itemCount: _breeds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _chip(_breeds[i]),
      ),
    );
  }

  Widget _chip(String breed) {
    final on = _cur == breed;
    // Specificity accident: only the "All breeds" chip carries an inline
    // font-weight:500, which beats `.s7-bchip.on { font-weight:600 }`.
    final weight = breed == 'all' ? FontWeight.w500 : (on ? FontWeight.w600 : FontWeight.w400);
    // .on: light #111111 fill + #FFFFFF text; dark #F5F5F5 fill + #111111 text.
    final onBg = _isDark ? VanixColors.textOnDarkDim : VanixColors.darkPrimary;
    final onFg = _isDark ? VanixColors.textPrimary : VanixColors.textOnDark;
    // off: the inline var(--bgcard)/var(--border) win over the dark class rule.
    final offBg = _isDark ? VanixColors.darkBgCard : VanixColors.bgCard;
    final offBorder = _isDark ? VanixColors.darkBorder : VanixColors.border;
    return GestureDetector(
      onTap: () => setState(() {
        _cur = breed;
        _tipIndex = null;
      }),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? onBg : offBg,
          border: Border.all(color: on ? onBg : offBorder, width: 1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          _chipLabels[breed] ?? breed,
          style: TextStyle(fontSize: 13, fontWeight: weight, color: on ? onFg : _text1),
        ),
      ),
    );
  }

  // ── WEEKLY YIELD — LAST 8 WEEKS card ──
  Widget _trendCard(List<double> trend) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caption('WEEKLY YIELD — LAST 8 WEEKS', 11, 1.1),
          // #s7-trend margin-top:10px
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              // svg width:100% on viewBox 0 0 320 150 → height = w * 150/320
              final h = w * _TrendPainter.vbH / _TrendPainter.vbW;
              final s = w / _TrendPainter.vbW;
              return GestureDetector(
                onTapDown: (d) {
                  // one invisible hit rect per point, iw/(n-1) wide, centred
                  final step = _TrendPainter.iw / (trend.length - 1) * s;
                  final i = ((d.localPosition.dx - _TrendPainter.padL * s) / step).round().clamp(0, trend.length - 1);
                  setState(() => _tipIndex = i);
                },
                onTapUp: (_) => setState(() => _tipIndex = null),
                onTapCancel: () => setState(() => _tipIndex = null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: w,
                      height: h,
                      child: CustomPaint(
                        painter: _TrendPainter(
                          values: trend,
                          weeks: _weeks,
                          line: _accent,
                          // .gline — #E7E1D6 light, #2A2A2A dark
                          grid: _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE7E1D6),
                          dotStroke: _cardBg,
                          valFill: _text1,
                          lblFill: VanixColors.textHint,
                        ),
                      ),
                    ),
                    if (_tipIndex != null) _tip(trend, _tipIndex!, s, w),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// #s7-tip — absolute, `left: clamp(px - 40, 4, cardW - 96)`,
  /// `top: y - 34`, both relative to the card. The chart host starts 17px in
  /// (1px card border + 16px card padding), so in host coordinates the clamp
  /// becomes [-13, hostW - 79].
  Widget _tip(List<double> trend, int i, double s, double hostW) {
    final x = _TrendPainter.xAt(i, trend.length) * s;
    final y = _TrendPainter.yAt(trend, trend[i]) * s;
    return Positioned(
      left: (x - 40).clamp(-13.0, math.max(-13.0, hostW - 79.0)),
      top: y - 34,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          // background:var(--dark1) — #111111 in both modes
          color: VanixColors.darkPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${_weeks[i]} · ${_num(trend[i])} L',
          maxLines: 1,
          softWrap: false, // white-space:nowrap
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VanixColors.textOnDark, fontFamily: 'NotoSans'),
        ),
      ),
    );
  }

  // ── HIGHEST / LOWEST WEEK tiles — .m-stat-card, padding 14 ──
  Widget _weekTile(String label, double value, String week) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caption(label, 10, 1.0),
          const SizedBox(height: 4), // margin:4px 0 0
          Text('${_num(value)} L', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _text1, fontFamily: 'NotoSans')),
          // margin:2px 0 0 — no class="en", so the Devanagari face applies
          const SizedBox(height: 2),
          Text('Week of $week', style: TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }

  // ── TOP 5 COWS / YIELD BY BREED bar cards ──
  Widget _barCard(String label, List<(String, double)> rows) {
    final peak = rows.map((r) => r.$2).reduce(math.max);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caption(label, 11, 1.1),
          const SizedBox(height: 12), // caption margin:0 0 12px
          for (var i = 0; i < rows.length; i++) ...[
            // .m-brow margin-bottom:10px, :last-child 0
            if (i > 0) const SizedBox(height: 10),
            _barRow(rows[i].$1, rows[i].$2, peak),
          ],
        ],
      ),
    );
  }

  Widget _barRow(String name, double value, double peak) {
    final pct = math.max(4, (value / peak * 100).round());
    final valStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text1, fontFamily: 'NotoSans');
    final valText = '${_num(value)} L';
    return Row(
      children: [
        // .m-bname — width:86px, 13px, --text1, ellipsis, NOT class="en"
        SizedBox(
          width: 86,
          child: Text(name, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _text1)),
        ),
        const SizedBox(width: 10), // .m-brow gap
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              // .m-btrack is a bare flex row — there is NO track behind the
              // fill. The fill's width:pct% is a flex-basis that shrinks to
              // fit beside the flex-shrink:0 value, floored by min-width:4px.
              final tp = TextPainter(text: TextSpan(text: valText, style: valStyle), textDirection: TextDirection.ltr)..layout();
              final room = c.maxWidth - 8 - tp.width;
              final fill = math.max(4.0, math.min(pct / 100 * c.maxWidth, room));
              return Row(
                children: [
                  Container(
                    width: fill,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _accent,
                      // border-radius:0 4px 4px 0
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8), // .m-btrack gap
                  Text(valText, style: valStyle),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// The uppercase `class="en"` captions: 11px or 10px, w500, .1em tracking,
  /// --text2 (measured #8C8780 in both modes).
  Widget _caption(String text, double size, double tracking) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: tracking,
        color: _muted,
        fontFamily: 'NotoSans',
      ),
    );
  }

  /// .m-stat-card — radius 16, 1px --border, --bgcard, plus the Airbnb card
  /// shadow. These cards are NOT covered by the `[id$="-sheet"]`
  /// box-shadow:none rule, so the shadow really is there.
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: child,
    );
  }
}

/// Repaints `renderTrend()` from prototype.html: a 320x150 viewBox scaled to
/// the available width, padL 6 / padR 10 / padT 24 / padB 22, three grid
/// lines, a 0.1-opacity area, a 2px polyline, r=4 dots on the max and min
/// weeks ONLY, and value/week captions on weeks 0, max, min and last.
class _TrendPainter extends CustomPainter {
  final List<double> values;
  final List<String> weeks;
  final Color line, grid, dotStroke, valFill, lblFill;

  _TrendPainter({
    required this.values,
    required this.weeks,
    required this.line,
    required this.grid,
    required this.dotStroke,
    required this.valFill,
    required this.lblFill,
  });

  static const double vbW = 320;
  static const double vbH = 150;
  static const double padL = 6;
  static const double padR = 10;
  static const double padT = 24;
  static const double padB = 22;
  static const double iw = vbW - padL - padR; // 304
  static const double ih = vbH - padT - padB; // 104

  static double xAt(int i, int n) => padL + i * iw / (n - 1);

  static double yAt(List<double> data, double v) {
    final max = data.reduce(math.max);
    final min = data.reduce(math.min);
    final span = (max - min) == 0 ? 1.0 : (max - min);
    return padT + (max - v) / span * ih;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / vbW;
    final max = values.reduce(math.max);
    final min = values.reduce(math.min);
    final iMax = values.indexOf(max);
    final iMin = values.indexOf(min);

    double x(int i) => xAt(i, values.length) * s;
    double y(double v) => yAt(values, v) * s;

    // .gline — stroke-width 1, at f = 0, 0.5, 1 of the inner height
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1 * s;
    for (final f in const [0.0, 0.5, 1.0]) {
      final gy = (padT + f * ih) * s;
      canvas.drawLine(Offset(padL * s, gy), Offset((vbW - padR) * s, gy), gridPaint);
    }

    // .tarea — polygon padL,(H-padB) → points → (W-padR),(H-padB); opacity .1
    final base = (vbH - padB) * s;
    final area = Path()..moveTo(padL * s, base);
    for (var i = 0; i < values.length; i++) {
      area.lineTo(x(i), y(values[i]));
    }
    area
      ..lineTo((vbW - padR) * s, base)
      ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.1));

    // .tline — stroke-width 2, round cap + join, fill:none
    final poly = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      poly.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      poly,
      Paint()
        ..color = line
        ..strokeWidth = 2 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // .tdot — r=4, fill line, stroke var(--bgcard) width 2, ONLY on max/min
    for (final i in [iMax, iMin]) {
      final c = Offset(x(i), y(values[i]));
      canvas.drawCircle(c, 4 * s, Paint()..color = line);
      canvas.drawCircle(
        c,
        4 * s,
        Paint()
          ..color = dotStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * s,
      );
    }

    // .tval (10px/w600) + .tlabel (10px/w400), both NotoSans, anchor middle
    for (var i = 0; i < values.length; i++) {
      if (i != 0 && i != iMax && i != iMin && i != values.length - 1) continue;
      final ux = xAt(i, values.length);
      _text(
        canvas,
        values[i] == values[i].roundToDouble() ? values[i].round().toString() : values[i].toString(),
        ux.clamp(14.0, vbW - 18) * s,
        (yAt(values, values[i]) - 8) * s,
        TextStyle(fontSize: 10 * s, fontWeight: FontWeight.w600, color: valFill, fontFamily: 'NotoSans'),
      );
      _text(
        canvas,
        weeks[i],
        ux.clamp(20.0, vbW - 22) * s,
        (vbH - 6) * s,
        TextStyle(fontSize: 10 * s, color: lblFill, fontFamily: 'NotoSans'),
      );
    }
  }

  /// SVG `y` is the alphabetic baseline and `text-anchor:middle` centres on x.
  void _text(Canvas canvas, String label, double cx, double baseline, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr)..layout();
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(cx - tp.width / 2, baseline - ascent));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.line != line || old.grid != grid || old.dotStroke != dotStroke || old.valFill != valFill;
}
