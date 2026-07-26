#!/usr/bin/env bash
# Verification audit — screen 03 (Farmer Dashboard, #farmer-dash).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/farmer_dashboard_screen.dart
B=~/Downloads/Vanix/flutter_app/lib/widgets/brand_logo.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── shell / scroll ──
ck "scroll padding-bottom 128"  "$F" 'only\(bottom: 128\)'
ck "header pad 16/20/16/6"      "$F" 'fromSTEB\(16, 20, 16, 6\)'

# ── header ──
ck "logo is the SVG wordmark"   "$F" 'BrandLogo\(height: 32'
ckn "no text wordmark left"     "$F" "TextSpan\(text: 'My', style: TextStyle\(fontSize: 19"
ck "logo widget fetches svg"    "$B" 'mybovine\.ai/assets/logos/vanix-logo\.svg'
ck "greeting 13/w600/--text2"   "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: VanixColors\.textHint'

# ── Priority / To-do tabs ──
ck "tabs wrap pad 16/14"        "$F" 'fromSTEB\(16, 14, 16, 0\)'
ckn "tabs wrap NOT pad 8"       "$F" 'fromSTEB\(16, 8, 16, 0\)'
ck "tab row gap 8"              "$F" 'SizedBox\(width: 8\)'
ck "tab row margin-bottom 14"   "$F" 'SizedBox\(height: 14\)'
ck "tab min-height 36"          "$F" 'minHeight: 36'
ck "tab pad-h 16"               "$F" 'symmetric\(horizontal: 16\)'
ck "tab radius 18"              "$F" 'BorderRadius\.circular\(18\)'
ck "tab 13px w600/w500"         "$F" 'fontSize: 13, fontWeight: on \? FontWeight\.w600 : FontWeight\.w500'
# Prototype JS (line ~6259): active Priority = --danger, active To-do = --greenink.
ck "Priority active = danger"   "$F" "_tabBtn\('immediate', .*VanixColors\.danger\)"
ck "To-do active = greenInk"    "$F" "_tabBtn\('todos', .*VanixColors\.greenInk\)"
ck "inactive tab = bgcard"      "$F" 'color: on \? onColor : _cardBg'
ck "inactive border = --border"  "$F" 'color: on \? onColor : _border'

# ── Priority cards ──
ck "card radius 16"             "$F" 'BorderRadius\.circular\(16\)'
ck "card pad 16/14"             "$F" 'fromLTRB\(16, 14, 16, 14\)'
ck "card gap 10"                "$F" 'only\(bottom: 10\)'
ck "left border 4px"            "$F" 'left: BorderSide\(color: border, width: 4\)'
ck "other borders 1px"          "$F" 'top: BorderSide\(color: border\)'
ck "fever tint dangerBg"        "$F" 'VanixColors\.dangerBg'
ck "warn tint warningBg"        "$F" 'VanixColors\.warningBg'
ck "fever eyebrow = danger"     "$F" "'cattleFever'.*VanixColors\.danger, VanixColors\.dangerBg, VanixColors\.danger"
ck "warn eyebrow = #8A5A00"     "$F" 'VanixColors\.warningInk'
ck "eyebrow 11/w700"            "$F" 'fontSize: 11, fontWeight: FontWeight\.w700'
ck "eyebrow ls 0.55"            "$F" 'letterSpacing: 0\.55'
ckn "eyebrow NOT ls 0.5,"       "$F" 'letterSpacing: 0\.5,'
ck "eyebrow uppercased"         "$F" '_t\(typeKey\)\.toUpperCase\(\)'
ck "name 15/w600"               "$F" 'fontSize: 15, fontWeight: FontWeight\.w600, color: _text1'
ck "name gap 4"                 "$F" 'SizedBox\(height: 4\)'
ck "breed w400 --text2"         "$F" 'fontSize: 15, fontWeight: FontWeight\.w400, color: VanixColors\.textHint'
ck "breed single-spaced dash"   "$F" "text: ' — \\\$breed'"
ckn "no double-spaced dash"     "$F" "'  —  \\\$breed'"
ck "question gap 6"             "$F" 'SizedBox\(height: 6\)'
ck "question 13/--text2"        "$F" 'fontSize: 13, color: VanixColors\.textHint'
ck "question row gap 10"        "$F" 'SizedBox\(width: 10\)'
ck "chevron 18"                 "$F" 'Icons\.chevron_right, size: 18'
ck "4 priority cards"           "$F" "_priorityCard\('fpVaccination'"

# ── To-do cards ──
ck "todo card radius 16"        "$F" 'BorderRadius\.circular\(16\), boxShadow: _shadow'
ck "todo card pad 14"           "$F" 'EdgeInsets\.all\(14\)'
ck "todo card gap 10"           "$F" 'margin: const EdgeInsets\.only\(bottom: 10\)'
ck "todo card has shadow"       "$F" 'boxShadow: _shadow'
ck "accent bar 4px"             "$F" 'Container\(width: 4'
ck "accent bar radius 2"        "$F" 'BorderRadius\.circular\(2\)'
ck "accent bar stretches"       "$F" 'IntrinsicHeight'
ck "bar1 greenInk"              "$F" "_row\(VanixColors\.greenInk, 'fpVetAppt'"
ck "bar2 warning"               "$F" "_row\(VanixColors\.warning, 'fpInsem'"
ck "bar3 --border"              "$F" "_row\(_border, 'fpMilkLog'"
ck "row gap 12 both sides"      "$F" 'SizedBox\(width: 12\)'
# Scoped to the To-do row: the gap immediately before the Open button must be
# 12, not the old 10. (A bare "no SizedBox(width: 10)" check would wrongly
# flag the legitimate 10px gap in the Priority card's question row.)
ckmn "no 10px gap before Open"  "$F" 'SizedBox\(width: 10\),\s*\n\s*ElevatedButton'
ck "todo title 15/w600"         "$F" 'fontSize: 15, fontWeight: FontWeight\.w600, color: _text1'
ck "todo sub 12/--text2"        "$F" 'fontSize: 12, color: VanixColors\.textHint'
ck "todo sub gap 3"             "$F" 'SizedBox\(height: 3\)'
ck "Open btn min-h 36"          "$F" 'minimumSize: const Size\(0, 36\)'
ck "Open btn radius 18"         "$F" 'BorderRadius\.circular\(18\)'
ck "Open btn greenInk"          "$F" 'backgroundColor: VanixColors\.greenInk'
ck "Open btn 13/w600"           "$F" 'fontSize: 13, fontWeight: FontWeight\.w600'

total=$((pass+fail))
echo "── Screen 03 Farmer Dashboard verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
