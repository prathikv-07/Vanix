#!/usr/bin/env bash
# Verification audit — screen 02 (Owner Dashboard, #s1-dash / #dash-scroll).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/dashboard_screen.dart
B=~/Downloads/Vanix/flutter_app/lib/widgets/brand_logo.dart
S=~/Downloads/Vanix/flutter_app/lib/i18n/farm_strings.dart
pass=0; fail=0; failed=()

ck()  { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn() { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
# Multiline negative — needed because grep -E is line-based, so a regex
# containing \n silently never matches and a plain `ckn` would pass vacuously.
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── scroll container / section padding ──
ck "scroll padding-bottom 128"   "$F" 'only\(bottom: 128\)'
ck "header pad 16/20/16/6"       "$F" 'fromSTEB\(16, 20, 16, 6\)'
ck "farm-status pad 16/8"        "$F" 'fromSTEB\(16, 8, 16, 0\)'
ck "ai-strip pad 16/14"          "$F" 'fromSTEB\(16, 14, 16, 0\)'
ck "needs-attention pad 16/20"   "$F" 'fromSTEB\(16, 20, 16, 0\)'

# ── header ──
ck "logo is the SVG wordmark"    "$F" 'BrandLogo\(height: 32'
ck "logo widget fetches svg"     "$B" 'mybovine\.ai/assets/logos/vanix-logo\.svg'
ck "logo fetch cached"           "$B" 'static String\? _cachedSvg'
ck "logo validates svg markup"   "$B" "body\.contains\('<svg'\)"
ckn "no text-wordmark in header" "$F" "TextSpan\(text: 'My', style: TextStyle\(fontSize: 19"
ck "farmsel height 38"           "$F" 'height: 38'
ck "farmsel radius 19"           "$F" 'BorderRadius\.circular\(19\)'
ck "farmsel pad-h 14"            "$F" 'symmetric\(horizontal: 14\)'
ck "farmsel 14/w600"             "$F" 'fontSize: 14, fontWeight: FontWeight\.w600'
ck "farmsel gap 8"               "$F" 'SizedBox\(width: 8\)'
ck "farmsel chevron 13"          "$F" 'Icons\.keyboard_arrow_down, size: 13'

# ── section headings ──
ck "sec label 11/w700"           "$F" 'fontSize: 11, fontWeight: FontWeight\.w700'
ck "sec label ls 0.55"           "$F" 'letterSpacing: 0\.55'
ckn "sec label NOT ls 0.6"       "$F" 'letterSpacing: 0\.6,'
ck "sec label --text2"           "$F" 'color: VanixColors\.textHint\)'
ck "sec label uppercased"        "$F" "toUpperCase\(\), style: _secLbl"
ck "sec label margin-bottom 10"  "$F" 'only\(bottom: 10\)'

# ── Farm Status stat tiles ──
ck "stat card radius 16 + shadow" "$F" 'BorderRadius\.circular\(16\), boxShadow: _shadow'
ck "stat card pad 6/14"          "$F" 'symmetric\(horizontal: 6, vertical: 14\)'
ck "stat number 26/w700/lh1"     "$F" 'fontSize: 26, fontWeight: FontWeight\.w700, height: 1'
ck "stat number Latin face"      "$F" "height: 1, color: _text1, fontFamily: 'NotoSans'"
ck "stat gap 7"                  "$F" 'SizedBox\(height: 7\)'
ck "stat label 10/w600/lh1.3"    "$F" 'fontSize: 10, fontWeight: FontWeight\.w600, height: 1\.3'
ck "stat label single line"      "$F" 'maxLines: 1'
ck "stat row gap 10"             "$F" 'SizedBox\(width: 10\)'
# The prototype's stat labels are white-space:nowrap single lines (measured
# 13px tall, no break). A hard-coded \n here truncates under maxLines:1.
ck "label en 'Cows Pregnant'"    "$S" "'homeCowsPregnant': 'Cows Pregnant'"
ck "label en 'Cows in Heat'"     "$S" "'homeCowsHeat': 'Cows in Heat'"
ck "label hi matches prototype"  "$S" "'homeCowsHeat': 'हीट में गायें'"
ckn "no \\\\n in stat labels"       "$S" "'homeCows(Pregnant|Heat)': '[^']*\\\\\\\\n"

# ── AI chat strip ──
ck "ai strip #3A3A3A"            "$F" '0xFF3A3A3A'
ck "ai strip radius 16"          "$F" '0xFF3A3A3A\), borderRadius: BorderRadius\.circular\(16\)'
ck "ai strip pad 16/14"          "$F" 'symmetric\(horizontal: 16, vertical: 14\)'
ck "ai icon 20 brandGreen"       "$F" 'size: 20, color: VanixColors\.brandGreen'
ck "ai gap 10"                   "$F" 'SizedBox\(width: 10\)'
ck "ai text 13/w600/white"       "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: Colors\.white'

# ── Needs Attention ──
ck "NA card radius 18"           "$F" '_cardDeco\(radius: 18\)'
ck "NA card pad 16/4"            "$F" 'fromSTEB\(16, 4, 16, 4\)'
ck "NA row pad-v 14"            "$F" 'symmetric\(vertical: 14\)'
ck "NA row divider colour"       "$F" 'BorderSide\(color: _divider\)'
ck "NA divider token #EBE6DD"    "$F" '_divider => _isDark \? VanixColors\.darkDivider : VanixColors\.divider'
ck "NA row gap 12"               "$F" 'SizedBox\(width: 12\)'
ck "NA row text 14/w600"         "$F" 'fontSize: 14, fontWeight: FontWeight\.w600, color: _text1'
ck "NA count Latin face"         "$F" "color: _text1, fontFamily: 'NotoSans'"
ck "NA viewAll 12/w600/greenInk" "$F" 'fontSize: 12, fontWeight: FontWeight\.w600, color: VanixColors\.greenInk'
ck "NA last row no divider"      "$F" "divider: false"
ck "NA has 3 rows"               "$F" "_needsAttentionRow\('14'"
# The Today / This-week tab row is display:none in the prototype, so it must
# not be rendered here either.
ckn "Today/week tabs not built"  "$F" "_t\('dashToday'\)|_t\('dashThisWeek'\)"

# ── Cows in Fever / Heat horizontal rows ──
ck "hscroll viewport 78"         "$F" 'height: 78'
ck "hscroll pad 16/16"           "$F" 'only\(start: 16, end: 16\)'
ck "hscroll gap 12"              "$F" 'SizedBox\(width: 12\)'
ck "alert card width 190"        "$F" 'width: 190'
ck "alert card radius 14"        "$F" 'BorderRadius\.circular\(14\)\)'
ckmn "alert card has NO shadow"  "$F" 'width: 190,.{0,400}?boxShadow'
ck "alert card pad 10"           "$F" 'EdgeInsets\.all\(10\)'
ck "alert photo 56x56"           "$F" 'width: 56, height: 56'
ck "alert photo radius 10"       "$F" 'BorderRadius\.circular\(10\)'
ck "alert photo cover"           "$F" 'fit: BoxFit\.cover'
ck "alert photo gap 10"          "$F" 'SizedBox\(width: 10\)'
ck "alert name 13 lh17"          "$F" 'fontSize: 13, height: 17 / 13'
ck "alert meta 11 lh15"          "$F" 'fontSize: 11, height: 15 / 11'
ck "alert text gaps 3"           "$F" 'SizedBox\(height: 3\)'
ck "alert row centred"           "$F" 'crossAxisAlignment: CrossAxisAlignment\.center'

total=$((pass+fail))
echo "── Screen 02 Owner Dashboard verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
