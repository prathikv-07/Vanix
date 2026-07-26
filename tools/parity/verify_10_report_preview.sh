#!/usr/bin/env bash
# Verification audit — screen 10 (Report Preview, #page-report-preview).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/report_preview_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── page shell ──
# #page-report-preview background:var(--bgwarm) => #F2EDE4
ck "page bg bgWarm (light)"       "$F" 'backgroundColor: isDark \? VanixColors\.darkPrimary : VanixColors\.bgWarm'
# scroller padding 0 0 96px + doc wrapper padding 16, behind a 76px footer
ck "scroll pad 16/16/16/36"       "$F" 'fromSTEB\(16, 16, 16, 36\)'
ckn "scroll pad NOT .../24"       "$F" 'fromSTEB\(16, 16, 16, 24\)'

# ── .m-hero header ──
ck "hero pad 16/14/16/14"         "$F" 'fromSTEB\(16, 14, 16, 14\)'
ck "hero bottom radius 14"        "$F" 'vertical\(bottom: Radius\.circular\(14\)\)'
ckm "hero shadow blur 28 @0,12"   "$F" 'blurRadius: 28,\s*offset: const Offset\(0, 12\)'
# light rgba(0,0,0,.18) / #flow-root.dark .m-hero rgba(0,0,0,.55)
ck "hero shadow .18 / .55 dark"   "$F" 'alpha: isDark \? 0\.55 : 0\.18'
ckmn "hero shadow not .18 only"   "$F" 'alpha: 0\.18\), blurRadius: 28'
# #flow-root.dark .m-hero { background:#1C1C1C !important } — NOT --bgwarm
ck "hero bg darkSecond in dark"   "$F" 'color: isDark \? VanixColors\.darkSecond : VanixColors\.bgWarm,'
ckm "darkSecond bound to hero"    "$F" 'VanixColors\.darkSecond : VanixColors\.bgWarm,\s*borderRadius: const BorderRadius\.vertical\(bottom: Radius\.circular\(14\)\)'
ck "hero title 20/w600"           "$F" 'fontSize: 20, fontWeight: FontWeight\.w600'
# #flow-root.dark .m-hero h2 { color:#F5F5F5 } — not pure white
ck "hero title #F5F5F5 in dark"   "$F" 'isDark \? VanixColors\.textOnDarkDim : VanixColors\.textPrimary'
ckn "hero title NOT Colors.white" "$F" 'isDark \? Colors\.white :'
ck "hero row gap 10"              "$F" 'SizedBox\(width: 10\)'

# ── #report-preview-back ──
ckm "back btn 36x36"              "$F" 'width: 36,\s*height: 36,'
ck "back btn circle"              "$F" 'shape: BoxShape\.circle'
ck "back btn bg --bgcard"         "$F" 'isDark \? VanixColors\.darkSecond : VanixColors\.bgCard'
# dark: #flow-root.dark .m-hero button { box-shadow:0 2px 6px rgba(0,0,0,0.4) }
ck "back btn dark shadow 0 2 6"   "$F" 'alpha: 0\.4\), blurRadius: 6, offset: const Offset\(0, 2\)'
ck "back icon is ✕ at 18"         "$F" 'Icons\.close, size: 18'
ckn "back icon NOT size 20"       "$F" 'Icons\.close, size: 20'

# ── #report-preview-doc (printed sheet) ──
ck "doc pad 20"                   "$F" 'EdgeInsetsDirectional\.all\(20\)'
ck "doc radius 16"                "$F" 'BorderRadius\.circular\(16\)'
ck "doc bg stays #FFFFFF in dark" "$F" 'color: Colors\.white,\s*$|color: Colors\.white,'
ck "doc border 1px --border"      "$F" 'Border\.all\(color: isDark \? VanixColors\.darkBorder : VanixColors\.border\)'
# 0 4px 16px rgba(0,0,0,.06) + 0 1px 3px rgba(0,0,0,.04) == VanixShadow.card
ck "doc uses VanixShadow.card"    "$F" 'boxShadow: VanixShadow\.card'
ckn "doc NOT single .05 shadow"   "$F" 'alpha: 0\.05\), blurRadius: 16'
ckn "doc NOT cardDark in dark"    "$F" 'VanixShadow\.cardDark'

# ── doc body typography ──
ck "farm name 18/w700 #111"       "$F" 'fontSize: 18, fontWeight: FontWeight\.w700, color: Color\(0xFF111111\)'
ck "type row 13/w600 danger"      "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: VanixColors\.danger'
ck "name→type gap 4"              "$F" 'SizedBox\(height: 4\)'
ck "generated-on 11 / #666"       "$F" 'fontSize: 11, color: Color\(0xFF666666\)'
ck "generated-on margin 4/14"     "$F" 'only\(top: 4, bottom: 14\)'
# Neither span carries class="en" — computed face is Noto Sans Devanagari.
ckmn "date must NOT force NotoSans" "$F" "0xFF666666\\), fontFamily: 'NotoSans'"
# new Date('2026-07-22T09:41:00').toDateString() === "Wed Jul 22 2026"
ck "date has weekday prefix"      "$F" "weekdays\\[now\\.weekday - 1\\]"
ck "date day zero-padded"         "$F" "padLeft\\(2, '0'\\)"
ckn "date NOT 'Jul 22, 2026' form" "$F" "months\\[now\\.month - 1\\]\\} \\\$\\{now\\.day\\}, "
ck "divider 1px --divider"        "$F" 'Container\(height: 1, color: isDark \? VanixColors\.darkDivider : VanixColors\.divider\)'
ck "divider bottom margin 14"     "$F" 'SizedBox\(height: 14\)'

# ── SUMMARY label ──
ck "summary 11/w700"              "$F" 'fontSize: 11, fontWeight: FontWeight\.w700'
# letter-spacing .05em at 11px = 0.55px
ck "summary ls 0.55"              "$F" 'letterSpacing: 0\.55'
ckn "summary NOT ls 0.7"          "$F" 'letterSpacing: 0\.7[^0-9]'
ck "summary #999"                 "$F" 'letterSpacing: 0\.55, color: Color\(0xFF999999\)'
ck "summary uppercased"           "$F" "'reportSummaryWord'\\)\\.toUpperCase\\(\\)"
ck "summary→stats gap 8"          "$F" 'SizedBox\(height: 8\)'

# ── #report-preview-stats grid ──
ck "stat col+row gap 10"          "$F" 'final half = \(full - 10\) / 2'
ck "2 tiles per row"              "$F" 'i \+= 2'
ck "odd last tile spans full"     "$F" 'width: lone \? full : half'
ck "row gap 10 between rows"      "$F" 'bottom: i \+ 2 < stats\.length \? 10 : 0'
# CSS align-items:stretch on the flex line
ckm "tiles stretch to row height" "$F" 'IntrinsicHeight\(\s*child: Row\(\s*crossAxisAlignment: CrossAxisAlignment\.stretch'
ckn "stats NOT a plain Wrap"      "$F" 'Wrap\('

# ── stat tile ──
ck "tile bg #F7F5F0"              "$F" 'Color\(0xFFF7F5F0\)'
ck "tile radius 12"               "$F" 'BorderRadius\.circular\(12\)'
ck "tile pad 12h/10v"             "$F" 'symmetric\(horizontal: 12, vertical: 10\)'
ck "tile min-width 100"           "$F" 'BoxConstraints\(minWidth: 100\)'
ck "value 18/w700"                "$F" 'fontSize: 18, fontWeight: FontWeight\.w700, color: color'
ck "value→label gap 3"            "$F" 'SizedBox\(height: 3\)'
ck "label 10/w600 #888"           "$F" 'fontSize: 10, fontWeight: FontWeight\.w600, color: Color\(0xFF888888\)'
# letter-spacing .04em at 10px = 0.4px
ck "label ls 0.4"                 "$F" 'letterSpacing: 0\.4'
ckn "label NOT ls 0.5"            "$F" 'letterSpacing: 0\.5[^0-9]'
# text-transform:uppercase on the tile label
ck "label uppercased"             "$F" 'label\.toUpperCase\(\)'
ck "temp tile colours by level"   "$F" "'tempVeryHigh' => VanixColors\.danger"
ck "tempHigh = warningInk"        "$F" "'tempHigh' => VanixColors\.warningInk"
ck "tempNormal = greenInk"        "$F" "'tempNormal' => VanixColors\.greenInk"
ck "critical => 1 alert tile (3)" "$F" "'rowCriticalAlerts'\\), '3', VanixColors\.danger"
ck "full => 14 alerts + 2 appr"   "$F" "'rowCriticalAlerts'\\), '14', VanixColors\.danger"
ck "pending-approvals tile #111"  "$F" "'rowPendingApprovals'\\), '2', const Color\(0xFF111111\)"

# ── critical-only note ──
ck "note 12 danger italic"        "$F" 'fontSize: 12, color: VanixColors\.danger, fontStyle: FontStyle\.italic'
ck "note top margin 14"           "$F" 'only\(top: 14\)'
ck "note only when critical"      "$F" 'if \(critical\)'

# ── sticky footer + download ──
ck "footer pad 16/12/16/16"       "$F" 'fromSTEB\(16, 12, 16, 16\)'
# box-shadow 0 -8px 20px rgba(0,0,0,0.08) — unchanged in dark
ck "footer shadow .08/20/0,-8"    "$F" 'alpha: 0\.08\), blurRadius: 20, offset: const Offset\(0, -8\)'
ckn "footer shadow NOT blur 12"   "$F" 'alpha: 0\.08\), blurRadius: 12'
ck "dl btn full width"            "$F" 'width: double\.infinity'
ck "dl btn min-height 48"         "$F" 'minimumSize: const Size\(0, 48\)'
ck "dl btn radius 24"             "$F" 'BorderRadius\.circular\(24\)'
ck "dl btn greenInk fill"         "$F" 'backgroundColor: VanixColors\.greenInk'
ck "dl btn 14/w600 white"         "$F" 'fontSize: 14, fontWeight: FontWeight\.w600'
ck "dl btn white label"           "$F" 'foregroundColor: Colors\.white'
# button box-shadow: none
ck "dl btn elevation 0"           "$F" 'elevation: 0'

# ── #vanix-toast ──
ck "toast bg #111111"             "$F" 'backgroundColor: VanixColors\.darkPrimary'
ck "toast 13/w600 white"          "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: Colors\.white'
ck "toast pad 18h/10v"            "$F" 'symmetric\(horizontal: 18, vertical: 10\)'
ck "toast radius 20"              "$F" 'BorderRadius\.circular\(20\)'
ck "toast visible 2200ms"         "$F" 'Duration\(milliseconds: 2200\)'
ckn "toast NOT 1s"                "$F" 'Duration\(seconds: 1\)'

# ── genuinely unfixed: dark-mode token drift (no matching token exists) ──
ckfail "dark --bgwarm #121212 (token darkPrimary is #111111)"
ckfail "dark --bgcard #1E1E1E for back btn (token darkSecond is #1C1C1C)"
ckfail "dark --border #333333 for doc (token darkBorder is #3A3A3A)"
# Material Icons.close has a fixed stroke; prototype ✕ is stroke-width 2.4.
ckfail "back ✕ stroke-width 2.4 not expressible via Icons.close"

total=$((pass+fail))
echo "── Screen 10 Report Preview verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
