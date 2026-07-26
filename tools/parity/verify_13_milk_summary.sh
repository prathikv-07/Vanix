#!/usr/bin/env bash
# Verification audit — screen 13 (Milk Summary, #s7-stats: the expanded
# "complete summary" view of the Milk Log).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=${1:-~/Downloads/Vanix/flutter_app/lib/screens/milk_summary_screen.dart}
F=$(eval echo "$F")
T=~/Downloads/Vanix/flutter_app/lib/theme/vanix_theme.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── page shell (#s7-stats) ──
# light background:var(--bgwarm) #F2EDE4; dark #111111 !important.
ck "page bg bgwarm/#111111"      "$F" 'isDark \? VanixColors\.darkPrimary : VanixColors\.bgWarm'
ckn "page bg NOT darkBgWarm"     "$F" 'backgroundColor: isDark \? VanixColors\.darkBgWarm'
ck "inner wrap pad 0 0 120"      "$F" 'EdgeInsets\.only\(bottom: 120\)'
# content block padding:0 20px + chip row margin-top:16px
ck "content pad 20/16/20/0"      "$F" 'fromLTRB\(20, 16, 20, 0\)'

# ── retained hero replica (.m-hero) ──
ck "hero pad 18/16/20"           "$F" 'fromLTRB\(16, 18, 16, 20\)'
ck "hero radius 0 0 14 14"       "$F" 'BorderRadius\.vertical\(bottom: Radius\.circular\(14\)\)'
ck "hero bg bgwarm/#1C1C1C"      "$F" 'color: isDark \? VanixColors\.darkSecond : VanixColors\.bgWarm'
# .stats-open .m-hero { box-shadow:none !important } beats the inline 0 12px 28px.
ckmn "hero has NO shadow"        "$F" 'Radius\.circular\(14\)\),\s*boxShadow'
ckn "hero NOT 0 12px 28px"       "$F" 'blurRadius: 28'
ck "hero title 22/w600"          "$F" 'fontSize: 22, fontWeight: FontWeight\.w600, color: text1'
ck "hero header gap 10"          "$F" 'SizedBox\(width: 10\)'
ckm "period pill h32 pad 0 12"   "$F" 'height: 32,\s*padding: const EdgeInsets\.symmetric\(horizontal: 12\)'
ck "period pill radius 16"       "$F" 'BorderRadius\.circular\(16\)'
ck "period pill 12/w600"         "$F" 'fontSize: 12, fontWeight: FontWeight\.w600, color: text1'
ck "period chevron 11"           "$F" 'Icons\.keyboard_arrow_down, size: 11'
ckn "chevron NOT 14/16"          "$F" 'keyboard_arrow_down, size: 1[46]'
ck "period pill gap 6"           "$F" 'SizedBox\(width: 6\)'
ck "hero right group gap 8"      "$F" 'SizedBox\(width: 8\)'
ckm "filter btn 32x32"           "$F" 'width: 32,\s*height: 32,'
ck "filter btn circle"           "$F" 'shape: BoxShape\.circle'
ck "filter glyph 14"             "$F" 'Icons\.filter_alt_outlined, size: 14'
# #flow-root.dark .m-hero button { border-color:#3A3A3A }
ck "hero btn border #3A3A3A"     "$F" 'darkHairline : VanixColors\.border'
# box-shadow:0 2px 6px rgba(0,0,0,.08); dark .m-hero button → rgba(0,0,0,.4)
ck "pill shadow .08/.4 0 2 6"    "$F" 'Color\(0x66000000\) : const Color\(0x14000000\), blurRadius: 6, offset: const Offset\(0, 2\)'
ckm "hero→totals gap 16"         "$F" 'SizedBox\(height: 16\),\s*_SummaryTotals\(appState: appState\)'

# ── Total Milk block (hero lower half) ──
ck "TOTAL MILK label text"       "$F" "'TOTAL MILK'"
ckm "label 11/w500"              "$F" "'TOTAL MILK',\s*style: TextStyle\(\s*fontSize: 11,\s*fontWeight: FontWeight\.w500,"
# letter-spacing:.08em at 11px = 0.88px (NOT 0.8, NOT the .1em 1.1px)
ck "label ls .08em = 0.88"       "$F" 'letterSpacing: 0\.88,'
ckn "label ls NOT 0.8 flat"      "$F" 'letterSpacing: 0\.8,'
ckm "label hint + NotoSans"      "$F" "letterSpacing: 0\.88,\s*color: VanixColors\.textHint,\s*fontFamily: 'NotoSans'"
ck "label→value gap 6"           "$F" 'SizedBox\(height: 6\)'
ck "big val 32/w700/lh1/en"      "$F" "'38\.6 L', style: TextStyle\(fontSize: 32, fontWeight: FontWeight\.w700, height: 1\.0, color: text1, fontFamily: 'NotoSans'\)"
ck "delta 13/w600/en"            "$F" "'▲ 8% vs yesterday', style: TextStyle\(fontSize: 13, fontWeight: FontWeight\.w600, color: accent, fontFamily: 'NotoSans'\)"
ck "delta greenDeep in dark"     "$F" 'accent = isDark \? VanixColors\.greenDeep : VanixColors\.greenInk'
ck "dl btn margin-start auto"    "$F" 'const Spacer\(\), // margin-inline-start:auto'
ck "dl glyph 15"                 "$F" 'Icons\.file_download_outlined, size: 15'
ckn "dl glyph NOT 17/18"         "$F" 'file_download_outlined, size: 1[78]'
ckm "tile row margin-top 16"     "$F" 'SizedBox\(height: 16\),\s*Row\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*Expanded\(child: _tile\(.18.'
ckm "tile row gap 8"             "$F" "_tile\(.18., .Cows milked., isDark, text1\)\),\s*const SizedBox\(width: 8\)"
ck "tile pad 10"                 "$F" 'EdgeInsets\.all\(10\)'
ck "tile radius 12"              "$F" 'BorderRadius\.circular\(12\)'
ck "tile dark bg #262626"        "$F" 'isDark \? VanixColors\.darkSubSurface : VanixColors\.bgCard'
ck "tile dark border #3A3A3A"    "$F" 'isDark \? VanixColors\.darkHairline : VanixColors\.border, width: 1'
ck "tile val 18/w700/en"         "$F" "fontSize: 18, fontWeight: FontWeight\.w700, color: text1, fontFamily: 'NotoSans'"
ck "tile val→sub gap 2"          "$F" 'SizedBox\(height: 2\), // margin:2px 0 0'
# .m-tile p + p pins the caption to #8C8780 even in dark.
ck "tile sub 11 @ #8C8780"       "$F" 'fontSize: 11, color: VanixColors\.textHint\)'
ck "tile labels 18/12.5/2.0"     "$F" "_tile\('12\.5 L', 'Max — Gauri'"
ck "collapse min-h 38"           "$F" 'BoxConstraints\(minHeight: 38\)'
ck "collapse radius 19"          "$F" 'BorderRadius\.circular\(19\)'
ck "collapse label + 13/w600"    "$F" "'Hide complete summary', style: TextStyle\(fontSize: 13, fontWeight: FontWeight\.w600, color: accent\)"
ckn "collapse label NOT 'View'"  "$F" "'View complete summary'"

# ── breed filter chips (#s7-breed-chips) ──
ck "chip row 38 (36+2 pad)"      "$F" 'height: 38, // 36px chip \+ 2px padding-bottom'
ck "chip row pad-bottom 2"       "$F" 'EdgeInsets\.only\(bottom: 2\)'
ck "chip row overflow-x auto"    "$F" 'scrollDirection: Axis\.horizontal'
ck "chip gap 8"                  "$F" 'separatorBuilder: \(_, __\) => const SizedBox\(width: 8\)'
ck "chip height 36"              "$F" 'height: 36,'
ck "chip pad 0 16"               "$F" 'EdgeInsets\.symmetric\(horizontal: 16\)'
ck "chip radius 18"              "$F" 'BorderRadius\.circular\(18\)'
ck "chip font 13"                "$F" 'fontSize: 13, fontWeight: weight'
# Specificity trap: the inline font-weight:500 on the "All breeds" chip beats
# `.s7-bchip.on { font-weight:600 }`, so it measures 500 in BOTH states while
# every other chip measures 400 off / 600 on.
ck "All-breeds weight always 500" "$F" "weight = breed == 'all' \? FontWeight\.w500 : \(on \? FontWeight\.w600 : FontWeight\.w400\)"
ckn "chip weight NOT on?600:500" "$F" 'on \? FontWeight\.w600 : FontWeight\.w500'
ckn "chip weight NOT on?600:400 flat" "$F" 'fontWeight: on \? FontWeight\.w600 : FontWeight\.w400'
# .on: light #111111 fill / #FFFFFF text; dark #F5F5F5 fill / #111111 text.
ck "chip on fill 111/F5F5F5"     "$F" 'onBg = _isDark \? VanixColors\.textOnDarkDim : VanixColors\.darkPrimary'
ck "chip on fg FFF/111"          "$F" 'onFg = _isDark \? VanixColors\.textPrimary : VanixColors\.textOnDark'
ck "chip on border = fill"       "$F" 'border: Border\.all\(color: on \? onBg : offBorder, width: 1\)'
# off state: the inline var(--bgcard)/var(--border) beat the non-important
# `#flow-root.dark .s7-bchip` rule, so dark is #1E1E1E / #333333.
ck "chip off dark bg #1E1E1E"    "$F" 'offBg = _isDark \? VanixColors\.darkBgCard : VanixColors\.bgCard'
ck "chip off dark border #333333" "$F" 'offBorder = _isDark \? VanixColors\.darkBorder : VanixColors\.border'
ckn "chip off NOT darkSecond"    "$F" 'offBg = _isDark \? VanixColors\.darkSecond'
ckn "chip off NOT darkHairline"  "$F" 'offBorder = _isDark \? MilkSummaryContent\.darkHairline'
ck "5 chips all+4 breeds"        "$F" "_breeds = \\['all', 'Jersey', 'Ongole', 'Gir/Sahiwal', 'Desi'\\]"
ck "'all' renders 'All breeds'"  "$F" "_chipLabels = \\{'all': 'All breeds'\\}"
ckm "chip tap clears tooltip"    "$F" '_cur = breed;\s*_tipIndex = null;'

# ── .m-stat-card shell ──
ck "card pad 16"                 "$F" 'padding = const EdgeInsets\.all\(16\)'
ckm "card radius 16"             "$F" 'BorderRadius\.circular\(16\),\s*boxShadow: _isDark \? VanixShadow\.cardDark'
ck "card border 1 --border"      "$F" 'Border\.all\(color: _cardBorder, width: 1\)'
# dark override IS !important here → #1C1C1C / #3A3A3A (not --bgcard/--border).
ck "card dark bg #1C1C1C"        "$F" '_cardBg => _isDark \? VanixColors\.darkSecond : VanixColors\.bgCard'
ck "card dark border #3A3A3A"    "$F" '_cardBorder => _isDark \? VanixColors\.darkHairline : VanixColors\.border'
# The token now lives in the shared theme, which is its proper home.
ck "darkHairline is #3A3A3A"     "$T" 'darkHairline = Color\(0xFF3A3A3A\)'
ckn "card dark bg NOT darkBgCard" "$F" '_cardBg => _isDark \? VanixColors\.darkBgCard'
# .m-stat-card keeps the Airbnb shadow — the [id$="-sheet"] none rule misses it.
ck "card shadow present"         "$F" 'boxShadow: _isDark \? VanixShadow\.cardDark : VanixShadow\.card'
ckn "card shadow NOT suppressed" "$F" 'boxShadow: null'
ckm "trend card margin-top 12"   "$F" 'SizedBox\(height: 12\),\s*_trendCard\(trend\)'

# ── uppercase class="en" captions ──
ckm "caption w500"               "$F" 'Widget _caption\([^;]*fontWeight: FontWeight\.w500,'
ck "caption ls .1em@11 = 1.1"    "$F" "_caption\('WEEKLY YIELD — LAST 8 WEEKS', 11, 1\.1\)"
ck "caption ls .1em@10 = 1.0"    "$F" "_caption\(label, 10, 1\.0\)"
ckm "caption NotoSans"           "$F" "color: _muted,\s*fontFamily: 'NotoSans',"
# All muted captions here measure #8C8780 in BOTH modes (.m-hero p[class~=en],
# .m-tile p + p, .m-stat-card p[style*="text2"] all force the light hint).
ck "muted = #8C8780 both modes"  "$F" '_muted => VanixColors\.textHint'
ckn "muted NOT darkTextHint"     "$F" '_muted => _isDark \? VanixColors\.darkTextHint'
ck "TOP 5 COWS caption"          "$F" "'TOP 5 COWS — THIS WEEK'"
ck "YIELD BY BREED caption"      "$F" "'YIELD BY BREED — THIS WEEK'"
ck "caption→bars gap 12"         "$F" 'SizedBox\(height: 12\), // caption margin:0 0 12px'
ckm "caption→chart gap 10"       "$F" 'SizedBox\(height: 10\),\s*LayoutBuilder'

# ── HIGHEST / LOWEST WEEK tiles ──
ckm "hi/lo row gap 8"            "$F" "_weekTile\(.HIGHEST WEEK., maxV, _weeks\[trend\.indexOf\(maxV\)\]\)\),\s*const SizedBox\(width: 8\)"
ck "hi/lo card pad 14"           "$F" 'padding: const EdgeInsets\.all\(14\)'
ck "HIGHEST WEEK label"          "$F" "_weekTile\('HIGHEST WEEK', maxV"
ck "LOWEST WEEK label"           "$F" "_weekTile\('LOWEST WEEK', minV"
ck "week val 20/w700/en"         "$F" "fontSize: 20, fontWeight: FontWeight\.w700, color: _text1, fontFamily: 'NotoSans'"
ck "week val margin 4"           "$F" 'SizedBox\(height: 4\), // margin:4px 0 0'
ckm "week sub margin 2"          "$F" 'SizedBox\(height: 2\),\s*Text\(.Week of'
ck "'Week of X' 11 muted"        "$F" "'Week of \\\$week', style: TextStyle\(fontSize: 11, color: _muted\)"
# 'Week of …' is NOT class="en" — it keeps the Devanagari face.
ckmn "'Week of' NOT NotoSans"    "$F" "'Week of \\\$week'[^;]*NotoSans"
ck "hi/lo from trend max/min"    "$F" '_weeks\[trend\.indexOf\(maxV\)\]'

# ── trend chart (renderTrend) ──
ckm "viewBox 320x150"            "$F" 'vbW = 320;\s*static const double vbH = 150'
ck "padL 6"                      "$F" 'padL = 6;'
ck "padR 10"                     "$F" 'padR = 10;'
ck "padT 24"                     "$F" 'padT = 24;'
ck "padB 22"                     "$F" 'padB = 22;'
ck "inner width 304"             "$F" 'iw = vbW - padL - padR; // 304'
ck "inner height 104"            "$F" 'ih = vbH - padT - padB; // 104'
ck "x(i) = padL + i*iw/(n-1)"    "$F" 'xAt\(int i, int n\) => padL \+ i \* iw / \(n - 1\)'
ck "y(v) = padT + (max-v)/span*ih" "$F" 'padT \+ \(max - v\) / span \* ih'
ck "3 glines at 0/.5/1"          "$F" 'for \(final f in const \[0\.0, 0\.5, 1\.0\]\)'
ck "gline stroke-width 1"        "$F" 'strokeWidth = 1 \* s'
ck "gline #E7E1D6 / #2A2A2A"     "$F" 'Color\(0xFF2A2A2A\) : const Color\(0xFFE7E1D6\)'
ckn "gline NOT --border/divider" "$F" 'grid: _isDark \? VanixColors\.darkDivider'
ck "tarea opacity 0.1"           "$F" 'line\.withValues\(alpha: 0\.1\)'
ckn "tarea NOT 0.08/0.12"        "$F" 'withValues\(alpha: 0\.0?1?[28]\)'
ck "tarea baseline H-padB"       "$F" 'base = \(vbH - padB\) \* s'
ck "tline stroke-width 2"        "$F" 'strokeWidth = 2 \* s'
ckm "tline round cap+join"       "$F" 'strokeCap = StrokeCap\.round\s*\.\.strokeJoin = StrokeJoin\.round'
# .tdot only on the max and min weeks — not on every point, not on first/last.
ck "dots ONLY on max/min"        "$F" 'for \(final i in \[iMax, iMin\]\)'
ckn "no dot on every index"      "$F" 'i == 0 \|\| i == values\.length - 1 \|\| i == maxIdx'
ck "dot r 4"                     "$F" '4 \* s, Paint\(\)\.\.color = line'
ckm "dot stroke = --bgcard w2"   "$F" '\.\.color = dotStroke\s*\.\.style = PaintingStyle\.stroke\s*\.\.strokeWidth = 2 \* s'
ck "tval 10/w600 --text1"        "$F" "fontSize: 10 \* s, fontWeight: FontWeight\.w600, color: valFill, fontFamily: 'NotoSans'"
ck "tlabel 10/w400 #8C8780"      "$F" "fontSize: 10 \* s, color: lblFill, fontFamily: 'NotoSans'"
ck "tlabel fill = textHint"      "$F" 'lblFill: VanixColors\.textHint'
ck "tval x clamp 14..302"        "$F" 'ux\.clamp\(14\.0, vbW - 18\)'
ck "tlabel x clamp 20..298"      "$F" 'ux\.clamp\(20\.0, vbW - 22\)'
ck "tval y = y(v) - 8"           "$F" '\(yAt\(values, values\[i\]\) - 8\) \* s'
ck "tlabel y = H - 6"            "$F" '\(vbH - 6\) \* s'
ck "captions on 0/max/min/last"  "$F" 'if \(i != 0 && i != iMax && i != iMin && i != values\.length - 1\) continue'
ck "svg aspect 320:150"          "$F" 'w \* _TrendPainter\.vbH / _TrendPainter\.vbW'
ck "SVG baseline-anchored text"  "$F" 'computeDistanceToActualBaseline\(TextBaseline\.alphabetic\)'
ck "text-anchor middle"          "$F" 'Offset\(cx - tp\.width / 2, baseline - ascent\)'
ck "hit rect iw/(n-1) wide"      "$F" 'step = _TrendPainter\.iw / \(trend\.length - 1\) \* s'

# ── tooltip (#s7-tip) ──
ckm "tip bg --dark1 both modes"  "$F" 'color: VanixColors\.darkPrimary,\s*borderRadius: BorderRadius\.circular\(8\)'
ckmn "tip bg NOT card-coloured"  "$F" 'color: _cardBg,\s*borderRadius: BorderRadius\.circular\(8\)'
ck "tip pad 5 / 9"               "$F" 'EdgeInsets\.symmetric\(horizontal: 9, vertical: 5\)'
ck "tip 11/w600 white en"        "$F" "fontSize: 11, fontWeight: FontWeight\.w600, color: VanixColors\.textOnDark, fontFamily: 'NotoSans'"
ck "tip white-space nowrap"      "$F" 'softWrap: false, // white-space:nowrap'
ck "tip left clamp -13"          "$F" 'left: \(x - 40\)\.clamp\(-13\.0,'
ck "tip left upper cardW-96"     "$F" 'hostW - 79\.0'
ck "tip top y - 34"              "$F" 'top: y - 34,'
ck "tip text 'week · N L'"       "$F" "'\\\$\\{_weeks\\[i\\]\\} · \\\$\\{_num\\(trend\\[i\\]\\)\\} L'"

# ── bar rows (.m-brow) ──
ck "bname width 86"              "$F" 'width: 86,'
ckn "bname NOT 70/80"            "$F" 'SizedBox\(width: [78]0, child: Text\(name'
ck "bname 13 --text1 ellipsis"   "$F" 'overflow: TextOverflow\.ellipsis, style: TextStyle\(fontSize: 13, color: _text1\)'
# .m-bname carries no class="en" — Devanagari face.
ckmn "bname NOT NotoSans"        "$F" "Text\(name, maxLines: 1[^;]*NotoSans"
ck "brow gap 10"                 "$F" 'SizedBox\(width: 10\), // \.m-brow gap'
ck "btrack gap 8"                "$F" 'SizedBox\(width: 8\), // \.m-btrack gap'
ck "bfill height 18"             "$F" 'height: 18,'
ck "bfill radius 0 4 4 0"        "$F" 'BorderRadius\.horizontal\(right: Radius\.circular\(4\)\)'
ckn "bfill NOT all-round 4"      "$F" 'borderRadius: BorderRadius\.circular\(4\)\),\s*$'
ck "bfill min-width 4"           "$F" 'math\.max\(4\.0, math\.min\('
ck "pct = max(4, round(v/max*100))" "$F" 'pct = math\.max\(4, \(value / peak \* 100\)\.round\(\)\)'
ckm "bfill greenink/greendeep"   "$F" 'height: 18,\s*decoration: BoxDecoration\(\s*color: _accent,'
ck "bval 12/w600/en"             "$F" "fontSize: 12, fontWeight: FontWeight\.w600, color: _text1, fontFamily: 'NotoSans'"
# .m-btrack has NO background — there is no grey rail behind the fill.
ckn "no grey bar track"          "$F" 'Color\(0xFFF0EBE2\)|Color\(0xFF262626\), borderRadius'
ckmn "bar track is not a Stack"  "$F" 'return Stack\(\s*children: \[\s*Container\(\s*width: fill,'
ckm "bar track is a plain Row"   "$F" 'final fill = math\.max\(4\.0, math\.min\([^;]*;\s*return Row\('
ckm "row gap 10 between bars"    "$F" 'SizedBox\(height: 10\),\s*_barRow'

# ── data (WEEKS + STATS in prototype.html) ──
ck "WEEKS 12 May..30 Jun"        "$F" "_weeks = \\['12 May', '19 May', '26 May', '2 Jun', '9 Jun', '16 Jun', '23 Jun', '30 Jun'\\]"
ckn "WEEKS NOT the old Jul set"  "$F" "'28 Jul'"
ck "all trend"                   "$F" "'all': \\[512, 498, 540, 567, 531, 588, 549, 471\\]"
ck "Jersey trend"                "$F" "'Jersey': \\[221, 208, 230, 246, 228, 262, 240, 198\\]"
ck "Ongole trend"                "$F" "'Ongole': \\[186, 182, 198, 205, 192, 214, 200, 171\\]"
ck "Gir/Sahiwal trend"           "$F" "'Gir/Sahiwal': \\[105, 108, 112, 116, 111, 112, 109, 102\\]"
ck "Desi trend"                  "$F" "'Desi': \\[36, 34, 38, 40, 37, 42, 39, 35\\]"
ck "all cows top-5"              "$F" "\\('Gauri', 88\.4\\), \\('Lakshmi', 76\.2\\), \\('Mohini', 64\.9\\), \\('Dhauli', 58\.3\\), \\('Kajri', 41\.7\\)"
ck "Jersey cows top-5"          "$F" "\\('Gauri', 88\.4\\), \\('Kajri', 41\.7\\), \\('Rani', 38\.2\\), \\('Heera', 29\.6\\), \\('Chandni', 16\.1\\)"
ck "Ongole cows (3 rows)"        "$F" "\\('Lakshmi', 76\.2\\), \\('Ganga', 24\.8\\), \\('Radha', 21\.1\\)"
ck "Desi cows (2 rows)"          "$F" "\\('Mohini', 64\.9\\), \\('Kesar', 12\.3\\)"
ck "all breed bars"              "$F" "\\('Jersey', 214\\), \\('Ongole', 150\\), \\('Gir/Sahiwal', 96\\), \\('Desi', 37\\)"
# renderStats: breeds.length > 1 ? 'block' : 'none'
ck "breed card hidden if <=1"    "$F" 'if \(bars\.length > 1\)'
ckn "breed card NOT keyed on 'all'" "$F" "_cur == 'all'\) \.\.\."
ck "int vs decimal L formatting" "$F" '_num\(double v\) => v == v\.roundToDouble\(\) \? v\.round\(\)\.toString\(\) : v\.toString\(\)'

# ── genuinely unfixed ──
# The prototype hard-codes these captions in English (no data-k), so Hindi
# renders them in English too; FS's wkYield8 / highestWeek / lowestWeek are
# unreachable by design. Nothing to fix in this file, but flagged as drift
# between lib/i18n and the prototype.
ckfail "hero pill / filter / download buttons are inert — period sheet, filter sheet and window.print() are not wired"

total=$((pass+fail))
echo "── Screen 13 Milk Summary verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
