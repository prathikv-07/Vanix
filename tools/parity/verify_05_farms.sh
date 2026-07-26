#!/usr/bin/env bash
# Verification audit — screen 05 (Farms, #page-farms).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/farms_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }

# ── page shell ──
# #page-farms scroll container: padding:0 0 120px
ck "scroll bottom pad 120"        "$F" 'only\(bottom: 120\)'
# the div wrapping search + list: padding:14px 16px 0
ck "search wrap pad 16/14/16/0"   "$F" 'fromSTEB\(16, 14, 16, 0\)'
# #farms-list { margin-top:10px }
ck "list pad 16/10/16/0"          "$F" 'fromSTEB\(16, 10, 16, 0\)'
ck "search/filter row gap 8"      "$F" 'SizedBox\(width: 8\)'

# ── hero (.m-hero) ──
ck "hero pad 16/18/16/18"         "$F" 'fromSTEB\(16, 18, 16, 18\)'
ck "hero bottom radius 14"        "$F" 'BorderRadius\.vertical\(bottom: Radius\.circular\(14\)\)'
ckn "hero NOT radius 24"          "$F" 'vertical\(bottom: Radius\.circular\(24\)\)'
ck "hero shadow 0 12 28 @18/@55"  "$F" 'alpha: isDark \? 0\.55 : 0\.18\), blurRadius: 28, offset: const Offset\(0, 12\)'
ckn "hero NOT 24blur @ (0,10)"    "$F" 'blurRadius: 24, offset: const Offset\(0, 10\)'
# #flow-root.dark .m-hero { background:#1C1C1C }
ck "hero dark surface #1C1C1C"    "$F" 'isDark \? VanixColors\.darkSecond : VanixColors\.bgWarm'
ck "hero title 22/w600"           "$F" 'fontSize: 22, fontWeight: FontWeight\.w600'
ck "title→tiles gap 14"           "$F" 'SizedBox\(height: 14\)'

# ── stat tiles (.m-stat-card) ──
ck "tile pad 14/8"                "$F" 'symmetric\(vertical: 14, horizontal: 8\)'
ck "tile radius 16"               "$F" 'BorderRadius\.circular\(16\)'
# .m-stat-card is in the shared Airbnb-shadow selector list
ck "tile carries card shadow"     "$F" 'boxShadow: isDark \? VanixShadow\.cardDark : VanixShadow\.card'
ck "tile value 26/w700"           "$F" 'fontSize: 26,\s*$|fontSize: 26,'
ckm "tile value Latin face"       "$F" 'fontWeight: FontWeight\.w700,\s*fontFamily: .NotoSans.,'
# dark: .m-hero p[class~="en"] (1,3,1) beats .m-stat-card p (1,2,1) → --text2
ck "tile value dark = --text2"    "$F" 'isDark \? VanixColors\.textHint : VanixColors\.textPrimary'
# letter-spacing .04em at 10px = 0.4px
ck "tile label 10/w600 ls 0.4"    "$F" 'fontSize: 10, fontWeight: FontWeight\.w600, letterSpacing: 0\.4[^0-9]'
ckn "tile label NOT ls 0.5"       "$F" 'letterSpacing: 0\.5[^0-9]'
ck "tile label uppercased"        "$F" 'label\.toUpperCase\(\)'
ck "tile label gap 4"             "$F" 'SizedBox\(height: 4\)'

# ── search (.farms-search-wrap) ──
ck "search height 46"             "$F" 'height: 46,'
ck "search radius 14"             "$F" 'BorderRadius\.circular\(14\)'
ck "search pad-h 14"              "$F" 'symmetric\(horizontal: 14\)'
ck "search glyph 16"              "$F" 'Icons\.search, size: 16'
ckn "search glyph NOT 18"         "$F" 'Icons\.search, size: 18'
ck "search text 14/--text1"       "$F" 'fontSize: 14, color: isDark \? VanixColors\.textOnDarkDim : VanixColors\.textPrimary'
ck "placeholder 14/--text2"       "$F" 'hintStyle: const TextStyle\(fontSize: 14, color: VanixColors\.textHint\)'
# theme InputDecoration would force 48 min-height / radius 12 — opt out
ck "field collapsed, no theme box" "$F" 'isCollapsed: true'

# ── filter button (#farms-filter-btn) ──
ckm "filter btn 46x46"            "$F" 'width: 46,\s*height: 46,'
ckmn "filter btn NOT 48x48"       "$F" 'width: 48,\s*height: 48,'
ck "funnel glyph 15"              "$F" 'FunnelIcon\(size: 15'
# .fs-trigger-dot
ckm "trigger dot 10px"            "$F" 'width: 10,\s*height: 10,'
ck "trigger dot 2px --bgwarm ring" "$F" '_darkBgWarm : VanixColors\.bgWarm, width: 2'
ckm "trigger dot at -2/-2"        "$F" 'top: -2,\s*end: -2,'

# ── farm card (.farm-row) ──
ck "card radius 18"               "$F" 'BorderRadius\.circular\(18\)'
ck "card pad 14"                  "$F" 'EdgeInsetsDirectional\.all\(14\)'
ck "card margin-bottom 12"        "$F" 'only\(bottom: 12\)'
# `.farm-row { border: none !important }` kills the inline 1px border
ckmn "card is shadow-only, no border" "$F" 'border: Border\.all\([^)]*\),\s*boxShadow: isDark \? VanixShadow'
ck "card overflow hidden"         "$F" 'clipBehavior: Clip\.antiAlias'
# cornerTag()
ck "tag pad 16/5/14/6"            "$F" 'fromSTEB\(16, 5, 14, 6\)'
ckm "tag radius 17 end / 12 start" "$F" 'topEnd: Radius\.circular\(17\),\s*bottomStart: Radius\.circular\(12\)'
# letter-spacing .06em at 10px = 0.6px
ckm "tag 10/w700 ls 0.6"          "$F" 'fontSize: 10,\s*fontWeight: FontWeight\.w700,\s*letterSpacing: 0\.6,'
ckm "tag Latin face"              "$F" 'letterSpacing: 0\.6,\s*fontFamily: .NotoSans.,'
ck "farm name 16/w700"            "$F" 'fontSize: 16, fontWeight: FontWeight\.w700'
ck "head row top-aligned"         "$F" 'crossAxisAlignment: CrossAxisAlignment\.start'
ck "head row gap 10"              "$F" 'SizedBox\(width: 10\)'
ck "name→location gap 3"          "$F" 'SizedBox\(height: 3\)'
ck "location→manager gap 2"       "$F" 'SizedBox\(height: 2\)'
# PIN_SVG / PERSON_SVG are 11px with margin-inline-end:3px
ck "meta glyph 11"                "$F" 'size: 11, color: VanixColors\.textHint'
ckn "meta glyph NOT 12"           "$F" 'size: 12, color: VanixColors\.textHint'
ck "meta glyph gap 3"             "$F" 'SizedBox\(width: 3\)'
ck "meta text 12/--text2"         "$F" 'fontSize: 12, color: VanixColors\.textHint'
# GROUPCOW_SVG 15px, margin-inline-end 4
ck "cattle glyph 15"              "$F" 'width: 15, height: 15'
ck "cattle 14/w700 Latin"         "$F" "fontSize: 14, fontWeight: FontWeight\\.w700, fontFamily: 'NotoSans'"
ck "cattle offset top28/end4"     "$F" 'only\(top: 28, end: 4\)'
ck "chip row gap above 12"        "$F" 'SizedBox\(height: 12\)'
ck "chip gap 6"                   "$F" 'SizedBox\(width: 6\)'
ckm "5 chips, prototype order"    "$F" 'cattleHeat.*insemWord.*statusPregnantChip.*cattleFever.*statMilkToday'

# ── stat chips (farmChip) — bg/color args are dead code in the HTML ──
ck "chip pad 8/4"                 "$F" 'symmetric\(vertical: 8, horizontal: 4\)'
ck "chip radius 12"               "$F" 'BorderRadius\.circular\(12\)'
# in dark these resolve to --bgcard #1E1E1E / --border #333333, not
# darkSecond/darkBorder like the hero tiles
ck "chip dark surface #1E1E1E"    "$F" 'isDark \? _darkBgCard : VanixColors\.bgCard'
ck "chip dark border #333333"     "$F" 'isDark \? _darkBorderSoft : VanixColors\.border'
ck "chip label 9/w600"            "$F" 'fontSize: 9, fontWeight: FontWeight\.w600'
ck "chip label gap 2"             "$F" 'SizedBox\(height: 2\)'

# ── setup row + pill ──
ck "setup pill height 36"         "$F" 'height: 36,'
ck "setup pill 12/w600"           "$F" 'fontSize: 12, fontWeight: FontWeight\.w600'
ck "setup sub 'notSetUp · 0 …'"   "$F" "notSetUp'\\)\\} · 0 "

# ── filter sheet (#farms-fs-sheet + wireFilterSheet injections) ──
ck "sheet top radius 24"          "$F" 'BorderRadius\.vertical\(top: Radius\.circular\(24\)\)'
ck "sheet bottom pad 12"          "$F" 'fromSTEB\(0, 0, 0, 12\)'
# global [id$="-sheet"] rule strips the inline 0 -8px 32px shadow
ckmn "sheet has NO shadow"        "$F" 'top: Radius\.circular\(24\)\)\),\s*boxShadow'
# dark: #flow-root.dark #page-farms > div (2,1,1) also matches this sheet and
# outranks the generic sheet rule → #111111
ck "sheet dark bg #111111"        "$F" 'isDark \? VanixColors\.darkPrimary : VanixColors\.bgCard'
ckm "grabber 36x4"                "$F" 'width: 36,\s*height: 4,'
ck "grabber radius 2"             "$F" 'BorderRadius\.circular\(2\)'
ck "grabber margin top6/bottom2"  "$F" 'only\(top: 6, bottom: 2\)'
ckn "grabber NOT top 8"           "$F" 'only\(top: 8, bottom: 2\)'
ck "header pad 24/10/24/0"        "$F" 'fromSTEB\(24, 10, 24, 0\)'
# `#farms-fs-sheet h3 { font-size:17px !important }` beats the inline 20px
ck "sheet title 17/w700"          "$F" 'fontSize: 17, fontWeight: FontWeight\.w700'
ckn "sheet title NOT 20"          "$F" 'fontSize: 20, fontWeight: FontWeight\.w700'
ck "header gap 12"                "$F" 'SizedBox\(width: 12\)'
# .fs-reset-btn
ck "reset greenInk"               "$F" 'foregroundColor: VanixColors\.greenInk'
ck "reset pad 6px vertical"       "$F" 'symmetric\(vertical: 6\)'
# #farms-fs-close
ckm "close btn 38x38"             "$F" 'width: 38,\s*height: 38,'
ckm "close btn circle on --bgwarm" "$F" '_darkBgWarm : VanixColors\.bgWarm,\s*shape: BoxShape\.circle'
ck "close glyph 15"               "$F" "Text\\('✕', style: TextStyle\\(fontSize: 15"
# body
ck "body height 260"              "$F" 'height: 260'
ck "body margin-top 14"           "$F" 'only\(top: 14\)'
ck "body top+bottom --divider"    "$F" 'Border\(top: BorderSide\(color: divider\), bottom: BorderSide\(color: divider\)\)'
# margin-inline:-24 realised as "no side padding on this child"
ckn "no illegal negative margin"  "$F" 'fromSTEB\(-24'
# .fs-cats-rail
ck "rail width 126"               "$F" 'width: 126'
ck "rail pad 8px vertical"        "$F" 'symmetric\(vertical: 8\)'
ck "rail end 1px --divider"       "$F" 'BorderDirectional\(end: BorderSide\(color: divider\)\)'
ck "rail bg --bgcard"             "$F" 'railBg = isDark \? _darkBgCard : VanixColors\.bgCard'
# .fs-panes-wrap
ck "panes pad 20/12"              "$F" 'symmetric\(horizontal: 20, vertical: 12\)'

# ── rail category rows (.s7-cat) ──
ck "cat 5px start bar"            "$F" 'start: BorderSide\(color: active \? VanixColors\.greenInk : Colors\.transparent, width: 5\)'
ck "cat pad 14 all round"         "$F" 'fromSTEB\(14, 14, 14, 14\)'
# inline `border:none` on the button overrides .s7-cat's border-bottom
ckmn "cat rows have NO divider"   "$F" 'border: Border\(\s*bottom: BorderSide'
ckmn "cat has NO min-height 48"   "$F" 'BoxConstraints\(minHeight: 48\),\s*padding: const EdgeInsetsDirectional\.fromSTEB\(14, 14, 14, 14\)'
ckm "cat 13px, inactive w400"     "$F" 'fontSize: 13,\s*fontWeight: active \? FontWeight\.w700 : FontWeight\.w400,'
ckmn "cat inactive NOT w500"      "$F" 'active \? FontWeight\.w700 : FontWeight\.w500'
# #flow-root.dark .s7-cat.on { color:var(--greendeep) } while the bar stays greenInk
ck "cat active dark greenDeep"    "$F" 'activeInk = isDark \? VanixColors\.greenDeep : VanixColors\.greenInk'
ck "rail dot 7px greenInk"        "$F" 'width: 7, height: 7, decoration: const BoxDecoration\(color: VanixColors\.greenInk, shape: BoxShape\.circle\)'
ck "label→dot gap 10"             "$F" 'SizedBox\(width: 10\)'

# ── option rows (.s7-chip) ──
ck "opt row min-height 48"        "$F" 'BoxConstraints\(minHeight: 48\)'
ck "opt row pad-h 4"              "$F" 'symmetric\(horizontal: 4\)'
ckm "control 22x22"              "$F" 'width: 22,\s*height: 22,'
ck "control border 2px"           "$F" 'VanixColors\.greenInk : borderCol, width: 2'
ck "multi control radius 6"       "$F" 'BorderRadius\.circular\(6\)'
ck "multi tick 13 white"          "$F" 'Icons\.check, size: 13, color: VanixColors\.textOnDark'
ckn "multi tick NOT 14"           "$F" 'Icons\.check, size: 14'
# inset 0 0 0 4px var(--bgcard) inside the 18px padding box → 10px core
ckm "radio inset ring 18px"       "$F" 'width: 18,\s*height: 18,'
ckm "radio core 10px greenInk"    "$F" 'width: 10,\s*height: 10,\s*decoration: const BoxDecoration\(shape: BoxShape\.circle, color: VanixColors\.greenInk\)'
ck "radio inset uses --bgcard"    "$F" 'insetCol = isDark \? _darkBgCard : VanixColors\.bgCard'
ck "opt label 14, w500→w600"      "$F" 'fontSize: 14, fontWeight: active \? FontWeight\.w600 : FontWeight\.w500'

# ── apply / cancel ──
ck "apply height 52"              "$F" 'minimumSize: const Size\(double\.infinity, 52\)'
ck "apply radius 26"              "$F" 'BorderRadius\.circular\(26\)'
ck "apply greenInk fill"          "$F" 'backgroundColor: VanixColors\.greenInk'
ck "apply 16/w600"                "$F" 'textStyle: const TextStyle\(fontSize: 16, fontWeight: FontWeight\.w600\)'
# a bare ElevatedButton would inherit the theme's 48px StadiumBorder
ckmn "apply not theme-default"    "$F" 'ElevatedButton\(\s*onPressed'
ck "cancel 44 / --text2"          "$F" 'minimumSize: const Size\(double\.infinity, 44\), foregroundColor: VanixColors\.textHint'
ck "apply/cancel keep 24 sides"   "$F" 'symmetric\(horizontal: 24\)'

# ── panes content ──
ckm "status pane 4 options"       "$F" 'filterAllFarms.*filterHealthy.*filterAttention.*filterSetup'
ckm "location pane 4 options"     "$F" 'allWord.*locCoimbatore.*locErode.*locSalem'
ck "empty state 13/--text2"       "$F" 'fontSize: 13, color: VanixColors\.textHint'
ck "empty state margin-top 24"    "$F" 'only\(top: 24\)'

total=$((pass+fail))
echo "── Screen 05 Farms verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
