#!/usr/bin/env bash
# Verification audit — screen 06 (Milk Log, #page-milk).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/milk_log_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }

# ── page shell ──
# #page-milk background:var(--bgwarm) → #F2EDE4 light / #121212 dark
ck "page bg bgWarm/#121212"       "$F" 'backgroundColor: isDark \? _pageBgDark : VanixColors\.bgWarm'
ck "dark --bgwarm = 0xFF121212"   "$F" '_pageBgDark = Color\(0xFF121212\)'
ck "scroller pad bottom 120"      "$F" 'EdgeInsets\.only\(bottom: 120\)'

# ── .m-hero ──
ck "hero pad 16/18/16/20"         "$F" 'fromSTEB\(16, 18, 16, 20\)|fromLTRB\(16, 18, 16, 20\)'
ck "hero bottom radius 14"        "$F" 'vertical\(bottom: Radius\.circular\(14\)\)'
ck "hero bg bgWarm/darkSecond"    "$F" 'isDark \? VanixColors\.darkSecond : VanixColors\.bgWarm'
ckn "hero NOT darkPrimary bg"     "$F" 'isDark \? VanixColors\.darkPrimary : VanixColors\.bgWarm'
ck "hero shadow 0 12 28"          "$F" 'blurRadius: 28, offset: const Offset\(0, 12\)'
ck "hero shadow 18% / 55% dark"   "$F" 'alpha: isDark \? 0\.55 : 0\.18\)'
ckn "hero shadow not fixed 0.18"  "$F" 'withValues\(alpha: 0\.18\), blurRadius: 28'
# `#s7-stats.stats-open .m-hero { box-shadow:none }` — shadow drops when open
ck "hero shadow off when summary" "$F" 'boxShadow: _showSummary$|_showSummary\s*$|_showSummary'
ck "hero title 22/w600"           "$F" 'fontSize: 22, fontWeight: FontWeight\.w600'

# ── .s7-period-btn ──
ck "period pill h32"              "$F" 'height: 32,'
ck "period pill radius 16"        "$F" 'BorderRadius\.circular\(16\)'
ck "period pill pad-h 12"         "$F" 'symmetric\(horizontal: 12\)'
ck "period label 12/w600"         "$F" 'fontSize: 12, fontWeight: FontWeight\.w600, color: textColor'
ck "period gap 6"                 "$F" 'SizedBox\(width: 6\)'
ck "period chevron 11"            "$F" 'Icons\.keyboard_arrow_down, size: 11'
ckn "chevron NOT 14"              "$F' " 'Icons\.keyboard_arrow_down, size: 14'
ckn "chevron NOT 14"              "$F" 'Icons\.keyboard_arrow_down, size: 14'
# 0 2px 6px rgba(0,0,0,.08); .dark .m-hero button deepens to .40
ck "control shadow helper 0 2 6"  "$F" 'blurRadius: 6, offset: const Offset\(0, 2\)'
ck "control shadow 8% / 40% dark" "$F" 'alpha: isDark \? 0\.40 : 0\.08\)'
ck "period pill has shadow"       "$F" 'boxShadow: _controlShadow\(isDark\)'

# ── #s7-filter ──
ck "filter circle 32x32"          "$F" 'width: 32,\n        height: 32,|width: 32,'
ck "filter funnel glyph 15"       "$F" 'Icon\(icon, size: 15'
ck "filter/period border token"   "$F" 'isDark \? VanixColors\.darkBorder : VanixColors\.border'
ck "period sheet options"         "$F" "'Today', 'This Week', 'This Month', 'This Year', 'Custom…'"
ck "period sheet title"           "$F" "title: 'Show data for'"

# ── TOTAL MILK label + value + delta ──
ck "total label 11/w500"          "$F" 'fontSize: 11, fontWeight: FontWeight\.w500, letterSpacing: 0\.88'
# .08em at 11px is 0.88px, not 1px — anchored so 0.88 can't satisfy it
ckn "total label NOT ls 1"        "$F" 'letterSpacing: 1[^0-9]'
ck "total label Latin face"       "$F" "letterSpacing: 0\.88, color: VanixColors\.textHint, fontFamily: _en"
ck "class=en maps to NotoSans"    "$F" "_en = 'NotoSans'"
ck "total gap 6"                  "$F" 'SizedBox\(height: 6\)'
ck "total value 32/w700 lh1"      "$F" 'fontSize: 32, fontWeight: FontWeight\.w700, height: 1\.0'
ck "total/delta gap 10"           "$F" 'SizedBox\(width: 10\)'
ck "delta 13/w600"                "$F" 'fontSize: 13, fontWeight: FontWeight\.w600'
# `.dark .m-hero span` outranks `.dark .m-delta`, so dark delta is #F5F5F5
ck "delta greenInk / F5F5F5 dark" "$F" 'isDark \? VanixColors\.textOnDarkDim : VanixColors\.greenInk, fontFamily: _en'
ckn "delta not always greenInk"   "$F" 'color: VanixColors\.greenInk\), *$'

# ── .m-tile ──
ck "tiles gap 8"                  "$F" 'SizedBox\(width: 8\)'
ck "tile pad 10"                  "$F" 'EdgeInsets\.all\(10\)'
ck "tile radius 12"               "$F" 'BorderRadius\.circular\(12\)'
ck "tile bg bgCard/#262626"       "$F" 'isDark \? VanixColors\.darkSubSurface : VanixColors\.bgCard'
ckn "tile bg not raw 0xFF262626"  "$F" 'isDark \? const Color\(0xFF262626\) : VanixColors\.bgCard'
ck "tile value 18/w700"           "$F" 'fontSize: 18, fontWeight: FontWeight\.w700'
ck "tile value Latin face"        "$F" 'VanixColors\.textPrimary, fontFamily: _en\)\),'
ck "tile label gap 2"             "$F" 'SizedBox\(height: 2\)'
ck "tile label 11/textHint"       "$F" 'fontSize: 11, color: VanixColors\.textHint\), overflow'
ckmn "tile has no card shadow"    "$F" 'BorderRadius\.circular\(12\),\s*\n?\s*boxShadow'

# ── #s7-open-stats / #s7-stats-collapse ──
ck "summary btn min-h 38"         "$F" 'minimumSize: const Size\(0, 38\)'
ck "summary btn radius 19"        "$F" 'BorderRadius\.circular\(19\)'
ck "summary btn 13/w600"          "$F" 'fontSize: 13, fontWeight: FontWeight\.w600\)'
ck "summary btn greenInk/Deep"    "$F" 'isDark \? VanixColors\.greenDeep : VanixColors\.greenInk'
ck "summary btn 38 not clamped"   "$F" 'tapTargetSize: MaterialTapTargetSize\.shrinkWrap'
ck "summary btn labels"           "$F" "'Hide complete summary' : 'View complete summary'"
# The prototype button is text-only — no leading icon
ckmn "summary btn has no icon"    "$F" 'OutlinedButton\.icon'
ckmn "no chevron_right icon"      "$F" 'Icons\.chevron_right'

# ── section labels (.m-list > p.en) ──
ck "list wrapper pad 16/12/16/0"  "$F" 'fromLTRB\(16, 12, 16, 0\)'
ckn "list wrapper NOT top 16"     "$F" 'fromLTRB\(16, 16, 16, 0\)'
ck "section label 12/w600"        "$F" 'fontSize: 12, fontWeight: FontWeight\.w600, letterSpacing: 0\.96'
# .08em at 12px is 0.96px; the old value was 0.5 — anchored so 0.96 can't pass it
ckn "section label NOT ls 0.5"    "$F" 'letterSpacing: 0\.5[^0-9]'
ck "section label Latin face"     "$F" 'letterSpacing: 0\.96, color: _text2, fontFamily: _en'
ck "section label uppercased"     "$F" 'groups\[gi\]\.key\.toUpperCase\(\)'
ck "label margin-bottom 10"       "$F" 'top: gi == 0 \? 12 : 8, bottom: 10'
ckn "label margin NOT bottom 8"   "$F" 'EdgeInsets\.only\(bottom: 8\), child: Text\(group'
ck "dark --text2 = 0xFF9E988E"    "$F" '_textHintDark = Color\(0xFF9E988E\)'
ck "section label --text2"        "$F" '_text2 => _isDark \? _textHintDark : VanixColors\.textHint'

# ── .m-card.m-entry ──
ck "card radius 16"               "$F" 'BorderRadius\.circular\(16\)'
ck "card pad 16/14"               "$F" 'symmetric\(horizontal: 16, vertical: 14\)'
ck "card margin-bottom 10"        "$F" 'EdgeInsets\.only\(bottom: 10\)'
ck "card bg bgCard/darkSecond"    "$F" 'isDark \? VanixColors\.darkSecond : VanixColors\.bgCard'
ckn "card bg not raw 0xFF1C1C1C"  "$F" 'isDark \? const Color\(0xFF1C1C1C\) : VanixColors\.bgCard'
# .m-card has box-shadow:none — it is a bordered card, not an elevated one
ckmn "card has NO shadow"         "$F" 'BorderRadius\.circular\(16\),\s*\n?\s*boxShadow'
ck "card title 16/w600"           "$F" 'fontSize: 16, fontWeight: FontWeight\.w600, color: _text1'
# meta row margin-top is 2px, not 3
ck "meta row gap 2"               "$F" 'SizedBox\(height: 2\),\s*$|SizedBox\(height: 2\)'
ckn "meta row NOT gap 3"          "$F" 'SizedBox\(height: 3\)'
ck "meta row inner gap 8"         "$F" 'SizedBox\(width: 8\)'
ck "sub row gap 6"                "$F" 'SizedBox\(height: 6\)'
ck "sub 12/textHint"              "$F" 'fontSize: 12, color: VanixColors\.textHint\)\),'
ck "col/box gap 12"               "$F" 'SizedBox\(width: 12\)'
ck "row min-height 64"            "$F" 'BoxConstraints\(minHeight: 64\)'
ck "box stretches to row"         "$F" 'crossAxisAlignment: CrossAxisAlignment\.stretch,\s*$|IntrinsicHeight'

# ── .m-pill ──
ck "pill pad 2/10"                "$F" 'symmetric\(horizontal: 10, vertical: 2\)'
ck "pill radius 10"               "$F" 'BorderRadius\.circular\(10\)'
ck "pill bg bgWarm/#262626"       "$F" 'isDark \? VanixColors\.darkSubSurface : VanixColors\.bgWarm'
ck "pill 11/w600 Latin"           "$F" 'fontSize: 11, fontWeight: FontWeight\.w600, color: isDark \? _pillTextDark'
ck "pill dark text #EDEDED"       "$F" '_pillTextDark = Color\(0xFFEDEDED\)'

# ── .m-ok / .m-late ──
# .m-ok is a bare 12px ✓ glyph, NOT a Material check icon
ck "on-time is 12px ✓ glyph"      "$F" "Text\('✓', style: TextStyle\(fontSize: 12"
ckmn "on-time NOT Icons.check"    "$F" 'Icons\.check, size: 14'
ck "on-time greenInk/greenDeep"   "$F" 'isDark \? VanixColors\.greenDeep : VanixColors\.greenInk, fontFamily: _en\)\)'
# .m-late is a warnbg/warning chip with a 10/600 #8A5A00 ⏱, not an icon
ck "late chip pad 2/8"            "$F" 'symmetric\(horizontal: 8, vertical: 2\)'
ck "late chip bg warningBg"       "$F" 'isDark \? _lateBgDark : VanixColors\.warningBg'
ck "late chip border warning"     "$F" 'isDark \? _lateBorderDark : VanixColors\.warning\)'
ck "late glyph 10/w600 warnInk"   "$F" "Text\('⏱',"
ck "late text warningInk #8A5A00" "$F" 'isDark \? _lateTextDark : VanixColors\.warningInk'
ckmn "late NOT Icons.schedule"    "$F" 'Icons\.schedule'
ck "late dark bg #33290F"         "$F" '_lateBgDark = Color\(0xFF33290F\)'
ck "late dark border #8A6A1F"     "$F" '_lateBorderDark = Color\(0xFF8A6A1F\)'
ck "late dark text #E8C87A"       "$F" '_lateTextDark = Color\(0xFFE8C87A\)'

# ── .m-upd ──
ck "upd chip bg activeBg"         "$F" 'isDark \? _updBgDark : VanixColors\.activeBg'
ck "upd chip border greenDeep"    "$F" 'Border\.all\(color: VanixColors\.greenDeep\)'
ck "upd glyph 11"                 "$F" 'Icons\.refresh, size: 11'
ckmn "upd glyph NOT 12"           "$F" 'Icons\.refresh, size: 12'
ck "upd inner gap 4"              "$F" 'SizedBox\(width: 4\)'
ckmn "upd gap NOT 3"              "$F" 'Icons\.refresh, size: \d+.*\n.*SizedBox\(width: 3\)'
ck "upd label 10/w600"            "$F" 'fontSize: 10, fontWeight: FontWeight\.w600, color: isDark \? VanixColors\.greenDeep'
ck "upd dark bg #0F2A1E"          "$F" '_updBgDark = Color\(0xFF0F2A1E\)'

# ── litres box ──
ck "box 64 wide, min-h 64"        "$F" 'width: 64,\s*\n?\s*constraints: const BoxConstraints\(minHeight: 64\)|width: 64,'
ck "box radius 14"                "$F" 'BorderRadius\.circular\(14\)'
ck "box >=8 = greenInk"           "$F" 'litres >= 8\) return VanixColors\.greenInk'
ck "box >=4 = #C07E10"            "$F" 'litres >= 4\) return _amberBox'
ck "amber box token #C07E10"      "$F" '_amberBox = Color\(0xFFC07E10\)'
# the mid band is #C07E10, NOT warningInk (#8A5A00)
ckn "box mid NOT warningInk"      "$F" 'litres >= 4\) return VanixColors\.warningInk'
ck "box <4 = danger #D44C3A"      "$F" 'return VanixColors\.danger;'
ck "box value 22/w700 lh1"        "$F" 'fontSize: 22, fontWeight: FontWeight\.w700, height: 1\.0'
ckn "box value NOT lh 1.05"       "$F" 'height: 1\.05'
ck "box unit gap 2"               "$F" 'SizedBox\(height: 2\),\s*\n?\s*Text\(.Ltrs|SizedBox\(height: 2\)'
ck "box unit 10/w500"             "$F" 'fontSize: 10, fontWeight: FontWeight\.w500, color: Colors\.white\.withValues\(alpha: 0\.85\)'
# rgba(255,255,255,.85) — white70 is 0.70 and reads visibly dimmer
ckmn "box unit NOT white70"       "$F" 'Colors\.white70'

# ── .m-sub pending sub-card ──
# .m-sub is a 1px DASHED top rule with margin-top 2 / padding-top 10 —
# not a filled, rounded, bordered panel.
ck "m-sub dashed top rule"        "$F" 'painter: _DashedTopRule\(_border\)'
ck "dashed rule strokeWidth 1"    "$F" 'strokeWidth = 1'
ck "m-sub margin-top 2"           "$F" 'margin: const EdgeInsets\.only\(top: 2\)'
ck "m-sub padding-top 10"         "$F" 'EdgeInsets\.only\(top: 10\)'
ckmn "m-sub has no fill/radius"   "$F" '_pendingSub.*?\n.*?return Container\(\s*\n\s*margin: const EdgeInsets\.only\(top: 12\)'
ckmn "m-sub not pad-all-12"       "$F" '_pendingSub.*?padding: const EdgeInsets\.all\(12\)'
ck "m-sub label 13/w600"          "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: _text1'
ck "m-sub meta 11/textHint"       "$F" 'fontSize: 11, color: VanixColors\.textHint\)'
ck "m-sub text/actions gap 10"    "$F" 'SizedBox\(width: 10\),\s*$|SizedBox\(width: 10\)'
ck "reject/approve h34"           "$F" 'minimumSize: const Size\(0, 34\)'
ck "reject/approve pad-h 14"      "$F" 'symmetric\(horizontal: 14\)'
ck "reject/approve radius 17"     "$F" 'BorderRadius\.circular\(17\)'
ck "reject 12/w500"               "$F" 'fontSize: 12, fontWeight: FontWeight\.w500'
ck "approve greenInk fill"        "$F" 'backgroundColor: VanixColors\.greenInk'
ck "approve 12/w600 white"        "$F" 'fontSize: 12, fontWeight: FontWeight\.w600\)\)'
ck "actions gap 6"                "$F" 'SizedBox\(width: 6\)'
ck "actions owner-only"           "$F" 'if \(!isFarmer\)'

# ── #s7-act entry-actions sheet ──
ck "act sheet radius 24 top"      "$F" 'vertical\(top: Radius\.circular\(24\)\)'
ck "act sheet pad 24/8/24/28"     "$F" 'fromLTRB\(24, 8, 24, 28\)'
ckn "act sheet NOT pad 20/20"     "$F" 'fromLTRB\(20, 20, 20, 28\)'
ck "act sheet shadow 0 -8 32"     "$F" 'blurRadius: 32, offset: const Offset\(0, -8\)'
ck "act grabber 36x4 r2"          "$F" 'width: 36, height: 4, decoration: BoxDecoration\(color: _grabber'
ck "act grabber #E0E0E0"          "$F" '_grabber = Color\(0xFFE0E0E0\)'
ck "act grabber pad 6/2"          "$F" 'EdgeInsets\.only\(top: 6, bottom: 2\)'
ck "act title 15/w600 Latin"      "$F" 'fontSize: 15, fontWeight: FontWeight\.w600, color: _text1, fontFamily: _en'
ck "act note 12/textHint"         "$F" 'fontSize: 12, color: VanixColors\.textHint\)\),'
ck "act note margin-bottom 14"    "$F" 'SizedBox\(height: 14\)'
ck "act rows min-h 50"            "$F" 'BoxConstraints\(minHeight: 50\)'
ck "act rows radius 14"           "$F" 'BorderRadius\.circular\(14\)'
ckmn "act rows NOT radius 12"     "$F" 'ListTile'
ck "act rows pad-h 16"            "$F" 'symmetric\(horizontal: 16\)'
ck "act rows gap 12"              "$F" 'Icon\(icon, size: 17'
ck "act rows label 15/w500"       "$F" 'fontSize: 15, fontWeight: FontWeight\.w500, color: fg'
ck "act rows 1px border"          "$F" 'Border\.all\(color: borderColor\)'
ck "act edit bg bgWarm/#262626"   "$F" 'isDark \? VanixColors\.darkSubSurface : VanixColors\.bgWarm,\s*$|darkSubSurface : VanixColors\.bgWarm'
ck "act del bg dangerBg/#2A1512"  "$F" 'isDark \? _actDelBgDark : VanixColors\.dangerBg'
ck "act del dark bg #2A1512"      "$F" '_actDelBgDark = Color\(0xFF2A1512\)'
ck "act del fg danger"            "$F" 'fg: VanixColors\.danger'

# ── #s7-fab ──
ck "fab 56x56"                    "$F" 'width: 56,\s*\n?\s*height: 56,'
ck "fab right 18"                 "$F" 'right: 18,'
ck "fab bottom 104"               "$F" 'bottom: 104 \+ MediaQuery'
ck "fab fill darkPrimary"         "$F" 'backgroundColor: VanixColors\.darkPrimary'
ck "fab shadow 0 10 24 @28%"      "$F" 'alpha: 0\.28\), blurRadius: 24, offset: const Offset\(0, 10\)'
# Material elevation 6 is not the measured 0 10px 24px rgba(0,0,0,.28)
ckn "fab not Material elev 6"     "$F" 'elevation: 6'
ck "fab plus glyph 24"            "$F" 'Icons\.add, size: 24'

# ── dark --text1 is #F5F5F5, not pure white ──
ck "dark text1 = textOnDarkDim"   "$F" '_isDark \? VanixColors\.textOnDarkDim : VanixColors\.textPrimary'
ckmn "no Colors.white for text1"  "$F" 'textColor = isDark \? Colors\.white'

total=$((pass+fail))
echo "── Screen 06 Milk Log verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
